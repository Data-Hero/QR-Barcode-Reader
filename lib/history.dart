import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box<String> box;
  List<String> entries = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    box = Hive.box<String>('history');
  }

  @override
  Widget build(BuildContext context) {
    entries = box.toMap().values.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF293133),
      appBar: AppBar(
        title: const Text('Choose from past codes'),
      ),
      body: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                trailing: TextButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(''),
                  onPressed: () {
                    box.deleteAt(index);
                    setState(() {
                      box = Hive.box<String>('history');
                    });
                  },
                ),
                title: TextButton(
                    onPressed: () {
                      Navigator.pop(context, entries[index]);
                    },
                    child: Center(child: Text("$index:  ${entries[index]}"))));
          }),
    );
  }
}
