import 'dart:collection';
import 'package:attendance/DataModels/courseAttendance.dart';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:attendance/Utils/StoragePermissions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShowAttendance extends StatefulWidget {
  final LinkedHashMap args;
  const ShowAttendance(this.args);
  ShowAttendanceState createState() => ShowAttendanceState();
}

class ShowAttendanceState extends State<ShowAttendance> {
  String courseName, what, timeStamp;
  CourseAttendance courseAttendance;
  final fb = FirebaseDatabase.instance;

  var display, displayList;

  //PDF Utils
  String generatedPdfFilePath;
  List rows = [];
  var con;
  @override
  void initState() {
    super.initState();
    print(widget.args);
    grantStoragePermissionAndCreateDir(context);
    this.timeStamp = "";
    this.display = new List();
    this.displayList = new List<StudentDetails>();
    if (widget.args != null) {
      if (widget.args["route"] == "courseDetails") {
        this.courseName = widget.args["courseName"];
        this.what = widget.args["what"];
      }
      getData();
    }
  }

  getData() async {
    final ref = fb.reference();
    await ref
        .child("CourseAttendance")
        .child(this.courseName)
        .once()
        .then((data) {
      setState(() {
        this.courseAttendance = CourseAttendance.fromSnapshot(data);
        if (this.what == "present") {
          if (this.courseAttendance.presentees != null)
            this.display.addAll(this.courseAttendance.presentees);
        } else if (this.what == "absent") {
          if (this.courseAttendance.absentees != null)
            this.display.addAll(this.courseAttendance.absentees);
        }
      });
    });
    await ref.child("TimeStamp").child(this.courseName).once().then((onValue) {
      setState(() {
        this.timeStamp = onValue.value;
      });
    });
    setState(() {
      this.display.forEach((f) {
        this.displayList.add(new StudentDetails(f["rollNum"], f["name"]));
      });
      this.displayList
        ..sort((StudentDetails a, StudentDetails b) =>
            a.rollNum.toUpperCase().compareTo(b.rollNum.toUpperCase()));
    });
    genList();
    print(this.displayList.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance"),
      ),
      body: (this.courseAttendance == null || this.timeStamp.length == 0)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 15, 10, 10),
                    child: ListTile(
                      isThreeLine: true,
                      title: Text(
                        this.courseAttendance.courseName.toUpperCase(),
                        style: TextStyle(
                            color: Colors.indigo,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        "Last Posted on: " +
                            this.timeStamp +
                            "\n" +
                            this.what.toUpperCase() +
                            " Details",
                        style: TextStyle(
                          color: Colors.deepOrange[900],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  this.displayList.length == 0
                      ? Center(child: Text("No Data"))
                      : Scrollbar(
                          child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: this.displayList.length,
                              itemBuilder: (context, index) {
                                return Container(
                                    child: Card(
                                        elevation: 5,
                                        child: ListTile(
                                          leading: Text(
                                            (index + 1).toString(),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontStyle: FontStyle.normal,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          title: Text(
                                            this.displayList[index].rollNum,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            this.displayList[index].name,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )));
                              })),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: RaisedButton(
                        child: Text("Generate Report"),
                        onPressed: () async {
                          await generateExampleDocument();
                        },
                        color: Colors.teal,
                        textColor: Colors.white),
                  )
                ],
              ),
            ),
    );
  }

  genList() {
    int i = 1;
    for (var student in this.displayList) {
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
        
        <h1 style='text-align:center;color:red;font-size:30px'>${this.courseName.toUpperCase()}</h1>
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
          <td style='text-align:center'>${this.timeStamp}</td>
          <td style='text-align:center'>${this.courseAttendance.year}</td>
          <td style='text-align:center'>${this.what.toUpperCase()}</td>
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
    var targetFileName =
        this.courseName + "_" + this.courseAttendance.year + "_" + this.what;

    var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent, targetPath, targetFileName);
    generatedPdfFilePath = generatedPdfFile.path;
    if (generatedPdfFilePath.isNotEmpty) {
      Fluttertoast.showToast(
          msg: courseAttendance.courseName.toLowerCase() +
              " Report Generated Successfully!",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.blue,
          textColor: Colors.white);
    }
  }
}
