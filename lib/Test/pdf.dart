import 'dart:collection';
import 'dart:convert';

import 'package:attendance/DataModels/studentDetails.dart';
import 'package:attendance/StoragePermissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/flutter_full_pdf_viewer.dart';

import 'dart:io';

import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';

class PDF extends StatefulWidget {
  final LinkedHashSet students;
  const PDF(this.students);
  PDFState createState() => PDFState();
}

class PDFState extends State<PDF> {
  LinkedHashSet students;
  String generatedPdfFilePath;
  List rows = [];
  var con;
  @override
  void initState() {
    super.initState();
    this.students = new LinkedHashSet<StudentDetails>();
    this.students = widget.students;
    grantStoragePermissionAndCreateDir(context);
    genList();
  }

  genList() {
    int i = 1;
    for (var student in this.students) {
      this.rows.add(
          "<tr><td style='text-align:center'>${i.toString()}</td><td style='text-align:center'>${student.rollNum.toString()}</td><td style='text-align:center'>${student.name.toString()}</td></tr>");
      i++;
    }

    this.con = this.rows.join();
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
        <caption>Smart Interviews</caption>
        <thead>
        <tr>
        <th style='text-align:center'>S. No. </th>
        <th style='text-align:center'>HT No.</th>
        <th style='text-align:center'>Student Name</th>
        </tr>
        </thead>
        <tbody>
          $con
        </tbody>
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
    return Scaffold(
        appBar: AppBar(
          title: Text("PDF"),
        ),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: <Widget>[
                RaisedButton(
                  onPressed: () async {
                    await generateExampleDocument();
                  },
                  child: Text("PDF"),
                )
              ],
            )));
  }
}
