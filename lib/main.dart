import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'history.dart';

void main() async {
  await Hive.initFlutter(); //
  await Hive.openBox<String>('history');

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
  String text = "-1";
  String COLOR_CODE = "#F44336";
  String CANCEL_BUTTON_TEXT = "Cancel";
  bool isShowFlashIcon = false;
  ScanMode scanMode = ScanMode.QR;
  Box<String> box = Hive.box<String>('history');

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
        text = scanResult;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  _launchURL() async {
    if (await canLaunch(text)) {
      await launch(text);
    } else {
      throw 'Could not launch $text';
    }
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

  void _navigateAndDisplaySelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );

    setState(() {
      text = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If canceled
    if (text == "-1") {
      text = "Placeholder for a scanned code";
    } else {
      Hive.box<String>('history').put(DateTime.now().toString(), text);
    }
    return Scaffold(
        backgroundColor: const Color(0xFF293133),
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
                maxLines: 16,
                style: const TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                textAlign: TextAlign.center),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  label: const Text('Copy'),
                  icon: const Icon(Icons.content_copy_rounded),
                  onPressed: () {
                    _copyToClipboard();
                  },
                ),
                OutlinedButton.icon(
                  label: const Text('Share'),
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    _share();
                  },
                ),
                OutlinedButton.icon(
                  label: const Text('Open'),
                  icon: const Icon(Icons.link_rounded),
                  onPressed: () {
                    _launchURL();
                  },
                ),
              ],
            ),
            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    label: const Text('History'),
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      _navigateAndDisplaySelection(context);
                    },
                  ),
                  OutlinedButton.icon(
                    label: const Text('Start Scan'),
                    icon: const Icon(Icons.camera_alt_rounded),
                    onPressed: () {
                      _scanQR();
                    },
                  )
                ]),
          ],
        )));
  }
}
