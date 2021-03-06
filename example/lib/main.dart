import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String path;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/teste.pdf');
  }

  Future<File> writeCounter(Uint8List stream) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsBytes(stream);
  }

  Future<bool> existsFile() async {
    final file = await _localFile;
    return file.exists();
  }

  Future<Uint8List> fetchPost() async {
    final response = await http.get(
        'https://expoforest.com.br/wp-content/uploads/2017/05/exemplo.pdf');
    final responseJson = response.bodyBytes;

    return responseJson;
  }

  void loadPdf() async {
    await writeCounter(await fetchPost());
    await existsFile();
    path = (await _localFile).path;

    if (!mounted) return;

    setState(() {});
  }

  double _zoom;
  Size _currentPdfSize;

  void zoomChanged(double zoom) {
    setState(() {
      _zoom = zoom;
    });
  }

  void sizeChanged(Size size) {
    _currentPdfSize = size;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Plugin example app'),
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              if (path != null)
                Container(
                  height: 700,
                  child: PdfViewer(
                    filePath: path,
                    onPdfViewerCreated: (int id) => null,
                    onZoomLevelChanged: zoomChanged,
                    onSizeChanged: sizeChanged,
                  ),
                )
              else
                Text("Pdf is not Loaded"),
              RaisedButton(
                child: Text("Load pdf"),
                onPressed: loadPdf,
              ),
              Positioned(bottom: 10,
                  left: 10,
                  child: Text("Zoom Level: " + _zoom.toString())
              ),
              Positioned(bottom: 30,
                  left: 10,
                  child: Text("Size: " + _currentPdfSize.toString())
              ),
            ],
          ),
        ),
      ),
    );
  }
}
