import 'dart:async';
import 'dart:io';

import 'package:attendance/StoragePermissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/flutter_full_pdf_viewer.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

class XX extends StatefulWidget {
  @override
  _XXState createState() => _XXState();
}

class _XXState extends State<XX> {
  String generatedPdfFilePath;
  String a, b;
  List rows = [];
  var con;
  @override
  void initState() {
    super.initState();
    this.a = "anuragh";
    this.b = "suppu";
    this.rows.add("<tr><th>{$a}</th><th>{$b}</th></tr>");
    this.rows.add("<tr><th>{$a}</th><th>{$b}</th></tr>");
    this.rows.add("<tr><th>{$a}</th><th>{$b}</th></tr>");
    this.con = this.rows.join();
    grantStoragePermissionAndCreateDir(context);
    generateExampleDocument();
  }

  Future<void> generateExampleDocument() async {
    var htmlContent = """
    <!DOCTYPE html>
    <html>
      <head>
        <style>
        table, th, td {
          border: 1px solid black;
          border-collapse: collapse;
        }
        th, td, p {
          padding: 5px;
          text-align: left;
        }
        </style>
      </head>
      <body>
      <img src="https://raw.githubusercontent.com/AnuraghYarlagadda/Admin/master/app/src/main/res/drawable-v24/pdfimage.jpg" alt="web-img">
        <table style="width:100%">
          $con
        </table>
      </body>
    </html>
    """;

    var targetPath = "/storage/emulated/0" + "/Attendance";
    var targetFileName = "example-pdf";

    var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent, targetPath, targetFileName);
    generatedPdfFilePath = generatedPdfFile.path;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(),
      body: Center(
        child: RaisedButton(
          child: Text("Open Generated PDF Preview"),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PDFViewerScaffold(
                    appBar: AppBar(title: Text("Generated PDF Document")),
                    path: generatedPdfFilePath)),
          ),
        ),
      ),
    ));
  }
}
