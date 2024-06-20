import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passout/api/google/google_drive_api.dart';
import 'package:passout/api/google/google_signin_api.dart';

import '../../models/account.dart';
import '../../widgets/account_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignInProvider _googleSignInProvider = GoogleSignInProvider();
  GoogleDriveService? _googleDriveService;
  List<Account>? _accounts;

  @override
  void initState() {
    super.initState();
    _currentUser = _googleSignInProvider.currentUser;
    if (_currentUser != null) {
      _googleDriveService = GoogleDriveService(_currentUser!);
    } else {
      _handleSignIn();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _uploadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PassOut"),
      ),
      body: _currentUser != null
          ? _accounts != null
              ? _accounts!.isNotEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _accounts!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AccountCard(
                                  account: _accounts![index],
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
                                                    setState(() {
                                                      _accounts!
                                                          .removeAt(index);
                                                      _uploadFile();
                                                    });
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
    );
  }

  Future<void> _handleSignIn() async {
    final user = await _googleSignInProvider.signIn();
    setState(() {
      _currentUser = user;
      if (user != null) {
        _googleDriveService = GoogleDriveService(user);
      }
    });
    _getAccounts();
  }

  Future<void> _handleSignOut() async {
    await _googleSignInProvider.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  Future<void> _uploadFile() async {
    if (_currentUser != null && _accounts != null && _accounts!.isNotEmpty) {
      final content = await getMetaDataToUpload();
      const fileName = 'passout.txt';
      await _googleDriveService?.uploadFile(content, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );
    }
  }

  Future<String?> _downloadFile() async {
    if (_currentUser != null) {
      String fileName = 'passout.txt';
      final downloadedFile = await _googleDriveService?.downloadFile(fileName);
      print(downloadedFile);
      if (downloadedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File downloaded!')),
        );
      } else {
        setState(() {
          _accounts = [];
        });
      }
      return downloadedFile;
    }
    return null;
  }

  Future<String> getMetaDataToUpload() async {
    List<String> metaData = [];
    for (var account in _accounts!) {
      metaData.add(await account.encryptMetaData());
    }
    return jsonEncode(metaData);
  }

  Future<void> _getAccounts() async {
    var metaData = await _downloadFile();
    if (metaData != null) {
      var encryptedListOfMetaData = jsonDecode(metaData) as List<dynamic>;
      _accounts = [];
      for (var encryptedMetaData in encryptedListOfMetaData) {
        _accounts
            ?.add(await Account.decryptMetaData(encryptedMetaData.toString()));
      }
      setState(() {});
    }
  }
}
