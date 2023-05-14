import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter(); //
  await Hive.openBox<List<String>>('history');
  await Hive.openBox<bool>('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR & Barcode Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'QR & Barcode Reader', showCamera: true),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.showCamera})
      : super(key: key);
  final String title;
  final bool showCamera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String text = "-1";
  String COLOR_CODE = "#F44336";
  String CANCEL_BUTTON_TEXT = "Cancel";
  bool isShowFlashIcon = false;
  ScanMode scanMode = ScanMode.QR;

  Box<List<String>> box = Hive.box<List<String>>('history');
  List<String> entries = [];

  Box<bool> settings = Hive.box<bool>('settings');
  bool leftSideFloatButton = false;

  @override
  void initState() {
    super.initState();
    if (widget.showCamera) {
      _scanQR();
    } else {
      text = widget.title;
    }

    if (!settings.toMap().keys.contains("leftSideFloatButton")) {
      settings.put("leftSideFloatButton", false);
    } else {
      leftSideFloatButton = settings.get("leftSideFloatButton")!;
    }
  }

  Future _scanQR() async {
    try {
      String scanResult = await FlutterBarcodeScanner.scanBarcode(
          COLOR_CODE, CANCEL_BUTTON_TEXT, isShowFlashIcon, scanMode);
      setState(() {
        text = scanResult;
        if (text != "-1") {
          entries.insert(0, text);
        }
      });
    } on PlatformException catch (e) {
      // nothing
    }
  }

  _launchURL() async {
    var url = Uri.parse(text);
    await launchUrl(url);
  }

  _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
      ),
    );
  }

  _share() async {
    Share.share(text);
  }

  _deleteAll() async {
    entries = [];
    box.put(0, entries);
    text = "Nothing was scanned";
    setState(() {});
  }

  Future<void> _dialogBuilder(BuildContext context, Color buttonColor) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            title: const Text("Select an action:"),
            backgroundColor: const Color(0xFFd6cecc),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  _copyToClipboard();
                },
                child: const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.content_copy_rounded),
                    SizedBox(width: 10),
                    Text('Copy')
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  _share();
                },
                child: const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.share_rounded),
                    SizedBox(width: 10),
                    Text('Share')
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  _launchURL();
                },
                child: const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.link_rounded),
                    SizedBox(width: 10),
                    Text('Open')
                  ],
                ),
              ),
            ]);
      },
    );
  }

  Future<void> _confirmDialogBuilder() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This action will delete all previous scans.'),
                Text('Would you like to approve of this?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                _deleteAll();
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
    // If canceled
    if (text == "-1") {
      text = "Nothing was scanned";
    }
    box.put(0, entries);

    const buttonColor = Color(0xFF293133);
    const gap = 15.0;
    entries = box.get(0)!;
    var padding = MediaQuery.of(context).viewPadding;
    var height =
        MediaQuery.of(context).size.height - padding.top - padding.bottom;
    return Scaffold(
        backgroundColor: const Color(0xFF333d40),
        appBar: AppBar(
          title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      _confirmDialogBuilder();
                    },
                    icon: const Icon(Icons.delete_rounded)),
                Text(text),
                Switch(
                    value: leftSideFloatButton,
                    activeColor: const Color(0xFF293133),
                    onChanged: (bool value) {
                      settings.put("leftSideFloatButton", !leftSideFloatButton);
                      leftSideFloatButton = !leftSideFloatButton;
                      setState(() {});
                    })
              ]),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 0.71 * height),
              child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text(''),
                          onPressed: () {
                            entries.removeAt(index);
                            box.put(0, entries);
                            setState(() {});
                          },
                        ),
                        title: TextButton(
                            onPressed: () {
                              text = entries[index];
                              _dialogBuilder(context, buttonColor);
                            },
                            child: Align(
                                alignment: Alignment.topLeft,
                                child: Text("$index:  ${entries[index]}"))));
                  }),
            ),
            const SizedBox(height: gap),
          ],
        ),
        floatingActionButton: Row(
            mainAxisAlignment: leftSideFloatButton
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 30),
              SizedBox(
                  height: 100,
                  width: 100,
                  child: FittedBox(
                    child: FloatingActionButton(
                      onPressed: () {
                        _scanQR();
                      },
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.camera_alt_rounded),
                    ),
                  ))
            ]));
  }
}
