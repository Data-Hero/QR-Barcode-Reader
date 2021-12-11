import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR & Barcode Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'QR & Barcode Reader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String result = "https://www.example.com/";
  String COLOR_CODE = "#87CEFA";
  String CANCEL_BUTTON_TEXT = "Cancel";
  bool isShowFlashIcon = false;
  ScanMode scanMode = ScanMode.QR;

  @override
  void initState() {
    super.initState();
    _scanQR();
  }

  Future _scanQR() async {
    try {
      String scanResult = await FlutterBarcodeScanner.scanBarcode(
          COLOR_CODE, CANCEL_BUTTON_TEXT, isShowFlashIcon, scanMode);
      setState(() {
        result = scanResult;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  _launchURL() async {
    if (await canLaunch(result)) {
      await launch(result);
    } else {
      throw 'Could not launch $result';
    }
  }

  _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If canceled
    if (result == "-1") {
      result = "https://www.example.com/";
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(result),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  label: Text('Open'),
                  icon: Icon(Icons.link_rounded),
                  onPressed: () {
                    _launchURL();
                  },
                ),
                OutlinedButton.icon(
                  label: Text('Copy'),
                  icon: Icon(Icons.content_copy),
                  onPressed: () {
                    _copyToClipboard();
                  },
                )
              ],
            ),
            OutlinedButton.icon(
              label: Text('Start Scan'),
              icon: Icon(Icons.camera_alt_outlined),
              onPressed: () {
                _scanQR();
              },
            ),
          ],
        )));
  }
}
