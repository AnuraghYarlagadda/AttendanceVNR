import 'dart:collection';
import 'dart:io';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:attendance/StoragePermissions.dart';
import 'package:attendance/Test/pdf.dart';
import 'package:attendance/Test/xx.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class Excel extends StatefulWidget {
  ExcelState createState() => ExcelState();
}

class ExcelState extends State<Excel> {
  String fileType = "xlsx";
  File file;
  LinkedHashSet students;
  Future filePicker(BuildContext context) async {
    try {
      if (fileType == 'xlsx') {
        file = await FilePicker.getFile(
            type: FileType.custom, allowedExtensions: ['xlsx']);
        if (file != null) {
          print(file);
          var bytes = file.readAsBytesSync();
          var decoder = SpreadsheetDecoder.decodeBytes(bytes);
          var table = decoder.tables['Javascript Frameworks'];
          print(decoder.tables.keys);
          var j;
          for (var i = 0; i < table.maxRows; i++) {
            if (table.rows[i].contains("S. No.")) {
              j = i + 1;
            }
          }
          for (var i = j; i < table.maxRows; i++) {
            setState(() {
              this
                  .students
                  .add(new StudentDetails(table.rows[i][2], table.rows[i][1]));
            });
          }
          print(this.students.length);
        } else {}
      }
    } on PlatformException catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sorry...'),
              content: Text('Unsupported exception: $e'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }
  }

  @override
  void initState() {
    super.initState();
    this.students = new LinkedHashSet<StudentDetails>();
    grantStoragePermissionAndCreateDir(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Excel"),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                filePicker(context);
              },
              child: Text("File"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return PDF(this.students);
                    },
                  ),
                );
              },
              child: Text("pass"),
            ),
          ],
        ));
  }
}
