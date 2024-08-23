import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passout/api/google/google_drive_api.dart';
import 'package:passout/api/google/google_signin_api.dart';
import 'package:passout/api/webrtc/signaling.dart';
import 'package:passout/main.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../models/account.dart';
import '../../widgets/account_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignInProvider _googleSignInProvider = GoogleSignInProvider();
  GoogleDriveService? _googleDriveService;
  Signaling? _signaling;

  final TextEditingController _textController = TextEditingController();
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _currentUser = _googleSignInProvider.currentUser;
    if (_currentUser != null) {
      _googleDriveService = GoogleDriveService(_currentUser!);
    } else {
      _handleSignIn().then((value) {
        setState(() {
          isLoading = false;
        });
    });
      }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signaling = Signaling(this);
      // _signaling?.secretKey = 'kxv4jVBoGP431noIRPirPac/z8TxXu6ZU5HWCh+mZ7M=';
    });
  }

  @override
  void dispose() {
    super.dispose();
    uploadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PassOut"),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           FloatingActionButton(
            child: Icon(Icons.qr_code_scanner_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>  AppScanner(
                  onScan: (code) {
                    _signaling?.secretKey = code;
                  },
                ),
              ));
            },
          ),
          // const SizedBox(height: 16),
          // if(_signaling != null)
          // FloatingActionButton(
          //   onPressed: () async {},
          //   child: ValueListenableBuilder<int>(
          //     valueListenable: _signaling!.connectionStatus,
          //     builder: (context, value, child) {
          //       return Icon(value == 1 ? Icons.done_outlined : Icons.connect_without_contact_outlined,
          //         color : value == 1 ? Colors.green : Colors.red,);
          //     },
          //   ),
          // ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              child: _currentUser != null
                      ? !isLoading
                        ? getIt<Accounts>().accounts.isNotEmpty
                          ? Column(
                              children: [
                                Expanded(
                                  child: RefreshIndicator(
                                    onRefresh: () async {
                                       _handleSignIn().then((value) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      });
                                    },
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: getIt<Accounts>().accounts.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: AccountCard(
                                            account: getIt<Accounts>().accounts[index],
                                            onDelete: () {
                                              showGeneralDialog(
                                                  context: context,
                                                  pageBuilder: (context, animation,
                                                      secondaryAnimation) {
                                                    return AlertDialog(
                                                      title: const Text('Delete Account'),
                                                      content: const Text(
                                                          'Are you sure you want to delete this account?'),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: const Text('Cancel')),
                                                        TextButton(
                                                            onPressed: () {
                                                                getIt<Accounts>().accounts
                                                                    .removeAt(index);
                                                                uploadFile();
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: const Text('Delete')),
                                                      ],
                                                    );
                                                  });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/no-item-found.png'),
                                Text(
                                  'No accounts found!',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                )
                              ],
                            ))
              : const Center(child: CircularProgressIndicator())
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),
          if(_signaling != null)
          Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _signaling!.connectionStatus,
                builder: (context, value, child) {
                  return Text("Extension ${value == 1 ? 'connected' : 'disconnected'}",style: TextStyle(color: value == 1 ? Colors.green : Colors.red),);
                },
              ),
              const SizedBox(height: 8,)
            ],
          ),
        ],
      )
    );
  }

  Future<void> _handleSignIn() async {
    isLoading = true;
    final user = await _googleSignInProvider.signIn();
    setState(() {
      _currentUser = user;
      if (user != null) {
        _googleDriveService = GoogleDriveService(user);
      }
    });
   await _getAccounts();
  }

  Future<void> _handleSignOut() async {
    await _googleSignInProvider.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  Future<void> uploadFile() async {
    isLoading = true;
    var acc = getIt<Accounts>().accounts;
    if (_currentUser != null) {
      final content = await getMetaDataToUpload();
      const fileName = 'passout.txt';
      await _googleDriveService?.uploadFile(content, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accounts updated successfully!')),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<String?> downloadFile() async {
    if (_currentUser != null) {
      String fileName = 'passout.txt';
      final downloadedFile = await _googleDriveService?.downloadFile(fileName);
      print(downloadedFile);
      if (downloadedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accounts received successfully!')),
        );
      } else {
        setState(() {
          getIt<Accounts>().accounts = [];
        });
      }
      return downloadedFile;
    }
    return null;
  }

  Future<String> getMetaDataToUpload() async {
    List<String> metaData = [];
    for (var account in getIt<Accounts>().accounts) {
      metaData.add(await account.encryptMetaData());
    }
    return jsonEncode(metaData);
  }

  Future<void> _getAccounts() async {
    var metaData = await downloadFile();
    if (metaData != null) {
      var encryptedListOfMetaData = jsonDecode(metaData) as List<dynamic>;
      getIt<Accounts>().accounts = [];
      for (var encryptedMetaData in encryptedListOfMetaData) {
        getIt<Accounts>().accounts
            .add( Account.fromJson(await Account.decrypt(encryptedMetaData.toString())));
      }
      setState(() {});
    }
    return;
  }
}

class AppScanner extends StatelessWidget {
  final void Function(String)? onScan;
  const AppScanner({super.key, this.onScan});

  @override
  Widget build(BuildContext context) {
    bool hasPoper = false;
    return Scaffold(
      body: QRView(key: GlobalKey(), onQRViewCreated: (controller) {
        controller.scannedDataStream.listen((event) {
          print("krie khar ${event.code}");
          if (onScan != null) {
            onScan!(event.code!);
          }
          if (!hasPoper) {
            hasPoper = true;
            Navigator.maybePop(context);
          }
        });
      }),
    );
  }
}