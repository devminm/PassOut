import 'package:flutter/material.dart';
import 'package:hd_wallet_kit/hd_wallet_kit.dart';
import 'package:hd_wallet_kit/utils.dart';
import 'package:passout/app_router.dart';
import 'package:passout/helpers/secure_storage.dart';
import 'package:passout/widgets/gap.dart';

class MnemonicScreen extends StatefulWidget {
  const MnemonicScreen({super.key});

  @override
  State<MnemonicScreen> createState() => _MnemonicScreenState();
}

class _MnemonicScreenState extends State<MnemonicScreen> {
  bool didHaveMnemonic = false;
  final mnemonic = Mnemonic.generate();
  final textfieldControllers =
      List.generate(12, (index) => TextEditingController());
  String hint =
      "Please write down the following mnemonic words, you will need them to recover your wallet. Do not share them with anyone! After you have written them down, tap the 'Done!' button.";
  String submit = "Done!";
  @override
  initState() {
    super.initState();
    for (var i = 0; i < 12; i++) {
      textfieldControllers[i].text = mnemonic[i];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showGeneralDialog(
          context: context,
          pageBuilder: (dContext, animation, secondaryAnimation) {
            return AlertDialog(
              title: const Text("Recover Account"),
              content: const Text("Do you want to recover your account?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dContext).pop();
                  },
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () {
                    hint =
                        "Please enter the mnemonic words in the correct order. After you have entered them, tap the 'Confirm!' button.";
                    _submit(context);
                    Navigator.pop(dContext);
                  },
                  child: const Text("Yes"),
                ),
              ],
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint),
            Gap.vertical(),
            Expanded(
              child: Center(
                child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: (itemWidth / itemHeight) * 2.5,
                    children: List.generate(12, (index) {
                      return Card(
                        child: Center(
                          child: TextField(
                            controller: textfieldControllers[index],
                            textAlign: TextAlign.center,
                            expands: false,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Word ${index + 1}",
                            ),
                            enabled: submit == "Done!" ? false : true,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    })),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _submit(context);
              },
              child: Text(submit),
            ),
            Gap.vertical()
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    if (submit == "Done!") {
      setState(() {
        for (var i = 0; i < 12; i++) {
          textfieldControllers[i].text = "";
        }
        submit = "Confirm!";
      });
    } else {
      var mnemonic = textfieldControllers.map((e) => e.text).toList();
      try {
        Mnemonic.validate(mnemonic);
        final seed = Mnemonic.toSeed(mnemonic);
        final secStorage = SecureStorageService();
        await secStorage.write(key: "seed", value: uint8ListToHexString(seed));
        AppRouter.navigate(context, AppRouter.homeRoute);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid mnemonic words!"),
        ));
      }
    }
  }
}
