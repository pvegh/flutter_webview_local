import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
  copyFromAsset();
}

Future<Directory> getInternalStorageDirectory() async {
  Directory libraryDir;
  if (Platform.isIOS) {
    libraryDir = await getLibraryDirectory();
  } else if (Platform.isAndroid) {
    libraryDir = await getApplicationDocumentsDirectory();
  }
  print("Using root path in Flutter: " + libraryDir.path);
  return libraryDir;
}

copyFromAsset() async {
  final directory = await getInternalStorageDirectory();
  await copyFile(directory, "foo.html");
  await copyFile(directory, "bar.html");
}

Future copyFile(Directory directory, String fileName) async {
  final path = directory.path + "/$fileName";
  ByteData data = await rootBundle.load("assets/$fileName");
  writeToFile(data, path);
}

void writeToFile(ByteData data, String path) {
  final buffer = data.buffer;
  final file = new File(path);
  return file.writeAsBytesSync(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestWebPage(title: "Local html test"),
    );
  }
}

class TestWebPage extends StatefulWidget {
  TestWebPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _TestWebPageState createState() => _TestWebPageState();
}

class _TestWebPageState extends State<TestWebPage> {
  var encoding = Encoding.getByName('utf-8');
  WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebView(
        onWebResourceError: (WebResourceError error) {
          print("Error: $error");
        },
        onPageStarted: (String url) {
          print("started $url");
        },
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest request) {
          var requestUrl = request.url;
          print("requestUrl: $requestUrl");
          String httpsRemoved = requestUrl.replaceAll(RegExp("(https://|/)"), "");
          loadLocalHTML(httpsRemoved);
          return NavigationDecision.prevent;
        },
        initialUrl: "",
        onWebViewCreated: (WebViewController tmp) {
          webViewController = tmp;
          loadLocalHTML("foo.html");
        },
      ),
    );
  }

  loadLocalHTML(String fileName) async {
    var directory = await getInternalStorageDirectory();
    var dirPath = directory.path;
    print("dirpath: $dirPath");
    print("fileName: $fileName");
    var file = File("$dirPath/$fileName");
    String content = file.readAsStringSync();
    var uri = Uri.dataFromString(content, mimeType: 'text/html', encoding: encoding);
    var string = uri.toString();
    webViewController.loadUrl(string);
  }
}
