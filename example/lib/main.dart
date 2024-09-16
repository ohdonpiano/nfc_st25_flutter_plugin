import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:nfc_st25/nfc_st25.dart';
import 'package:nfc_st25/utils/nfc_st25_tag.dart';

import 'hex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Test",
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  ExamplePageState createState() => ExamplePageState();
}

class ExamplePageState extends State<ExamplePage> {
  final _scrollController = ScrollController();
  final passwordControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final addressController = TextEditingController();
  final blockNumberController = TextEditingController();
  bool nfcAvailability = false;
  St25Tag? lastTag;
  bool loading = false;
  Uint8List? lastMsg;
  List<String> logs = [];
  MailBox? mailBoxInfo;

  List<dynamic> commands = [
    [0, 1, 0],
    [0, 1, 1],
    [0, 1, 2],
  ];

  StreamSubscription<St25Tag>? _subscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    NfcSt25.nfcAvailability.then((value) => {
          setState(() {
            nfcAvailability = value;
          })
        });
    for (TextEditingController controller in passwordControllers) {
      controller.text =
          arrayToHex(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]));
    }
    addressController.text = "0200";
    blockNumberController.text = "64";
    startListen();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  startListen() {
    _subscription = NfcSt25.startReading().listen((tag) {
      log("[TAG FOUND] : ${tag.uid}");
      //showSnackBar("Tag found " + tag.uid, false);
      setState(() {
        lastTag = tag;
        mailBoxInfo = tag.mailBox;
      });
    }, onError: (e) => log("error on discovery tag -> $e"));
  }

  clearLogs() {
    setState(() {
      logs = [];
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await NfcSt25.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    log("platform version: $platformVersion");
  }

  void log(String s) {
    if (kDebugMode) {
      print(s);
    }
    setState(() {
      logs.add(s);
    });
    goBottomLog();
  }

  goBottomLog() {
    if (_scrollController.hasClients) {
      var scrollPosition = _scrollController.position;

      _scrollController.animateTo(
        scrollPosition.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> readBlock() async {
    final address = int.tryParse(addressController.text.trim());
    if (address == null) {
      return;
    }
    try {
      final data = await NfcSt25.readBlock(address);
      log("read block (${data.length}) : $data");
    } catch (e) {
      log("failed read block index $address -> $e");
    }
  }

  Future<void> readMultipleBlocks() async {
    final address = int.tryParse(addressController.text.trim());
    if (address == null) {
      return;
    }
    final numBlocks = int.tryParse(blockNumberController.text.trim());
    if (numBlocks == null) {
      return;
    }
    try {
      final data = await NfcSt25.readBlocks(address, numBlocks);
      log("read multiple blocks (${data.length}) : $data");
    } catch (e) {
      log("failed read blocks -> $e");
    }
  }

  Future<void> presentPassword(int passwordNumber, String password) async {
    if (password.length != 16) {
      showSnackBar(
          "Invalid password length: ${password.length}. Must be 64 bits", true);
      return;
    }
    try {
      await NfcSt25.presentPassword(passwordNumber, hexToUint8List(password));
      log("password # $passwordNumber presented successfully");
    } catch (e) {
      log("failed to present password $passwordNumber -> $e");
    }
  }

  Future<void> writePassword(int passwordNumber, String password) async {
    if (password.length != 16) {
      showSnackBar(
          "Invalid password length: ${password.length}. Must be 64 bits", true);
      return;
    }
    try {
      await NfcSt25.writePassword(passwordNumber, password.codeUnits);
      log("password # $passwordNumber written successfully");
    } catch (e) {
      log("failed to write password $passwordNumber -> $e");
    }
  }

  Future<void> readMailBoxMsg() async {
    int cntError = 0;
    Uint8List msg = Uint8List.fromList([]);
    while (cntError < 5) {
      try {
        log("Read try #$cntError");
        if (cntError > 0) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        msg = await NfcSt25.readMailbox;
        log("READ MSG (${msg.length}) : $msg");
        setState(() {
          lastMsg = msg;
        });
      } catch (e) {
        log("failed read  -> $e");
        cntError++;
      }
    }
    setState(() {
      lastMsg = msg;
    });
  }

  Future<void> resetMailBox() async {
    try {
      await NfcSt25.resetMailBox();
      log("SUCCESSFUL RESET MAILBOX");
    } catch (e) {
      log("Error reset mailbox $e");
      //showSnackBar("failed to reset mailbox -> " + e.toString(), true);
    }
  }

  Future<void> getMailBoxInfo() async {
    MailBox mailbox;
    try {
      mailbox = await NfcSt25.getMailBoxInfo();
      //showSnackBar("SUCCESSFUL RESET MAILBOX", false);
      log("GET MAILBOX INFO :\n$mailbox");
      setState(() {
        mailBoxInfo = mailbox;
      });
    } catch (e) {
      setState(() {
        mailBoxInfo = null;
      });
      log("failed get mailbox info -> $e");
      //showSnackBar("failed to reset mailbox -> " + e.toString(), true);
    }
  }

  Future<bool> writeMailBoxMsg(List<int> data) async {
    Uint8List msg = Uint8List.fromList(data);
    try {
      await NfcSt25.writeMailBoxByte(msg);
      log("SUCCESS WRITE $msg");
      return true;
    } catch (e) {
      log("failed write -> $e");
      return false;
    }
  }

  Future<void> writeAndRead(List<int> data) async {
    bool success = await writeMailBoxMsg(data);
    if (success) {
      await readMailBoxMsg();
      if (lastMsg != null) {
        showSnackBar('Send: $data \nReceived: ${lastMsg!}', false);
      }
    }
  }

  Future<void> writeNDEF(String msg) async {
    try {
      await NfcSt25.writeNDEFString(msg);
      log("SUCCESS WRTITE NDEF msg: $msg");
    } catch (e) {
      log("failed write ndef -> $e");
      return;
    }
  }

  Future<String?> readNDEF() async {
    try {
      String ris = await NfcSt25.readNDEF();
      log("SUCCESS read NDEF msg:\n$ris");
      return ris;
    } catch (e) {
      log("failed write ndef -> $e");
      return null;
    }
  }

  void showSnackBar(String text, bool error) {
    final snackBar = SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red : null,
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _tapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: nfcAvailability
          ? Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Expanded(
                      child: Card(
                          child: Container(
                              height: 300,
                              padding: const EdgeInsets.all(8),
                              child: const Stack(children: [
                                Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Text(
                                      "Please tap a tag !",
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    )),
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Icon(
                                      Icons.nfc,
                                      size: 128,
                                      color: Colors.black38,
                                    ))
                              ]))))
                ])
          : const Text("Nfc unavailable."),
    );
  }

  AppBar _myAppBar() {
    if (lastTag == null) {
      return AppBar(
        title: const Text('ST25 nfc plugin example'),
      );
    }

    return AppBar(
      title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lastTag?.name ?? ""),
            Text(lastTag?.uid ?? "",
                style: const TextStyle(color: Colors.blue, fontSize: 14.0))
          ]),
      actions: [
        IconButton(
            icon: const Icon(Icons.cancel), onPressed: () => invalidateAll())
      ],
    );
  }

  invalidateAll() {
    log("INVALIDATE DATA");
    setState(() {
      lastTag = null;
      logs = [];
      mailBoxInfo = null;
    });
  }

  void showWriteDialog(bool read) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: const Text("Select command to send"),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: commands
                  .map((e) => ElevatedButton(
                        onPressed: () {
                          //writeMailBoxMsg(e);
                          read ? writeAndRead(e) : writeMailBoxMsg(e);
                          Navigator.of(context).pop();
                        },
                        child: Text(e.toString()),
                      ))
                  .toList()),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: _myAppBar(),
        body: lastTag == null
            ? _tapCard()
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCommands(),
                          //_buildMailBox(),
                          _buildLogs(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCommands() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Description: ${lastTag!.description}"),
          Text("Memory size: ${lastTag!.memorySize}"),
          Text('Last mailbox msg read: $lastMsg'),
          const SizedBox(height: 25),
          const Text("Read / Write blocks"),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    label: Text("Address hex - hex"), prefix: Text("0x")),
                inputFormatters: [HexadecimalTextInputFormatter()],
                controller: addressController,
              ),
            ),
            Expanded(
              child: TextFormField(
                  decoration:
                      const InputDecoration(label: Text("Block size to read")),
                  inputFormatters: [IntegerTextInputFormatter()],
                  controller: blockNumberController),
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  child: const Text("Read block"),
                  onPressed: () => readBlock()),
              ElevatedButton(
                  child: const Text("Read blocks"),
                  onPressed: () => readMultipleBlocks()),
              ElevatedButton(
                  child: const Text("Write"),
                  onPressed: () => showWriteDialog(false) //writeMailBoxMsg(),
                  ),
            ],
          ),
          const Text("Write protection"),
          for (int i = 0; i < passwordControllers.length; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(label: Text("PWD ${i + 1}")),
                    controller: passwordControllers[i],
                    inputFormatters: [HexadecimalTextInputFormatter()],
                  ),
                ),
                ElevatedButton(
                    child: const Text("Present"),
                    onPressed: () =>
                        presentPassword(i, passwordControllers[i].text.trim()))
              ],
            ),
          ElevatedButton(
              child: const Text("Write NDEF"),
              onPressed: () =>
                  writeNDEF("Hello from flutter") //writeMailBoxMsg(),
              ),
          ElevatedButton(
              child: const Text("Read NDEF"),
              onPressed: () => readNDEF() //writeMailBoxMsg(),
              ),
        ],
      ),
    );
  }

  Widget _buildMailBox() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          color: Colors.blue,
          child: ListTile(
            title: const Text(
              "MAILBOX INFO",
              style: TextStyle(color: Colors.white),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                ),
                onPressed: () => getMailBoxInfo(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.restore,
                  color: Colors.white,
                ),
                onPressed: () => resetMailBox(),
              ),
            ]),
          )),
      Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black12,
        child: Text(mailBoxInfo.toString()),
      ),
    ]);
  }

  Widget _buildLogs() {
    return Column(
      children: [
        Container(
            height: 50,
            color: Colors.blue,
            child: ListTile(
              //leading: Icon(Icons.code),
              title: const Text(
                "Logs",
                style: TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                onPressed: () => clearLogs(),
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
              ),
            )),
        Container(
          color: Colors.black12,
          height: 200,
          child: ListView.builder(
            itemCount: logs.length,
            controller: _scrollController,
            primary: false,
            shrinkWrap: true,
            itemBuilder: (_, int index) {
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(logs[index]), const Divider()]));
            },
          ),
        )
      ],
    );
  }
}
