import 'dart:collection';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:flutter/material.dart';
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
      <img src="https://img.techpowerup.org/200530/logo-new-1-converted-1.png" width="1100" height="300" alt="web-img">
        
        <h1 style='text-align:center;color:red;font-size:30px'>Smart Interviews</h1>
        <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:Teal;font-size:20px;'>Time Stamp</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Year</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Attendance</th>
        </tr>
        </thead>
        <tbody>
          <tr>
          <td style='text-align:center'>12/22/2020 18:04:22</td>
          <td style='text-align:center'>III</td>
          <td style='text-align:center'>Present</td>
          </tr>
        </tbody>
        </table>
        <br><br>
        <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>S. No.</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>H. T. No.</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>Name of the Student</th>
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
