import 'dart:collection';
import 'package:attendance/DataModels/attendanceBackup.dart';
import 'package:attendance/DataModels/courseAttendance.dart';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:attendance/Utils/StoragePermissions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance/Utils/openFileFromLocalStorage.dart';

class ShowAttendance extends StatefulWidget {
  final LinkedHashMap args;
  const ShowAttendance(this.args);
  ShowAttendanceState createState() => ShowAttendanceState();
}

enum Status { data, nodata }

class ShowAttendanceState extends State<ShowAttendance> {
  String courseName, what, timeStamp, year;
  CourseAttendance courseAttendance;
  final fb = FirebaseDatabase.instance;
  int status;
  var display, displayList;
  bool thereStudents;
  //PDF Utils
  String generatedPdfFilePath;
  List rows = [];
  var con;

  //Backup Utils
  var dataFromBackup;
  PresentAbsent presentAbsent;

  //FileUtils
  var targetPath;
  var targetFileName;
  @override
  void initState() {
    super.initState();
    this.status = Status.nodata.index;
    this.timeStamp = "";
    this.courseName = "";
    this.what = "";
    this.year = "";
    this.display = new List();
    this.displayList = new List<StudentDetails>();
    this.dataFromBackup = new LinkedHashMap<dynamic, dynamic>();
    if (widget.args != null) {
      if (widget.args["route"] == "courseDetails") {
        this.thereStudents = false;
        this.courseName = widget.args["courseName"];
        this.what = widget.args["what"];
        grantStoragePermissionAndCreateDir(
            context, "/storage/emulated/0" + "/Attendance/" + this.courseName);
        getData();
      } else if (widget.args["route"] == "displayDates") {
        this.courseName = widget.args["courseName"];
        this.year = widget.args["year"];
        this.thereStudents = true;
        this.timeStamp = widget.args["timeStamp"];
        this.presentAbsent = widget.args["data"];
        this.what = "present";
        this.con = "";
        grantStoragePermissionAndCreateDir(
            context,
            "/storage/emulated/0" +
                "/Attendance/" +
                this.courseName +
                "/" +
                widget.args["date"]);
        arrangeList();
      }
    }
  }

  arrangeList() {
    this.display.clear();
    this.displayList.clear();
    this.rows.clear();
    this.con = "";
    if (widget.args["route"] == "displayDates") {
      this.targetPath = "/storage/emulated/0" +
          "/Attendance/" +
          this.courseName +
          "/" +
          widget.args["date"];
      this.targetFileName = this.courseName +
          "_" +
          this.year +
          "_" +
          this.what +
          "_" +
          widget.args["time"];
    }
    if (this.what == "present") {
      if (this.presentAbsent.presentees != null)
        this.display.addAll(this.presentAbsent.presentees);
    } else if (this.what == "absent") {
      if (this.presentAbsent.absentees != null)
        this.display.addAll(this.presentAbsent.absentees);
    }
    setState(() {
      this.display.forEach((f) {
        this.displayList.add(new StudentDetails(f["rollNum"], f["name"]));
      });
      this.displayList
        ..sort((StudentDetails a, StudentDetails b) =>
            a.rollNum.toUpperCase().compareTo(b.rollNum.toUpperCase()));
      genList();
    });
  }

  getData() async {
    final ref = fb.reference();
    await ref.child("CourseAttendance").once().then((onValue) async {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.data.index;
        });
      } else {
        await ref
            .child("CourseAttendance")
            .child(this.courseName)
            .once()
            .then((data) {
          if (data.value == null) {
            setState(() {
              this.status = Status.data.index;
            });
          } else {
            setState(() {
              this.status = Status.data.index;
              this.courseAttendance = CourseAttendance.fromSnapshot(data);
              this.year = this.courseAttendance.year;
              if (this.courseAttendance.students != null) {
                this.thereStudents = true;
              }
              if (this.what == "present") {
                if (this.courseAttendance.presentees != null)
                  this.display.addAll(this.courseAttendance.presentees);
              } else if (this.what == "absent") {
                if (this.courseAttendance.absentees != null)
                  this.display.addAll(this.courseAttendance.absentees);
              }
              setState(() {
                this.display.forEach((f) {
                  this
                      .displayList
                      .add(new StudentDetails(f["rollNum"], f["name"]));
                });
                this.displayList
                  ..sort((StudentDetails a, StudentDetails b) => a.rollNum
                      .toUpperCase()
                      .compareTo(b.rollNum.toUpperCase()));
              });
            });
          }
        });
      }
    });
    await ref.child("TimeStamp").once().then((onValue) async {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.data.index;
        });
      } else {
        await ref
            .child("TimeStamp")
            .child(this.courseName)
            .once()
            .then((onValue) {
          if (onValue.value == null) {
            setState(() {
              this.status = Status.data.index;
            });
          } else {
            setState(() {
              this.status = Status.data.index;
              this.timeStamp = onValue.value;
            });
          }
        });
      }
    });
    if (widget.args["route"] == "courseDetails") {
      this.targetPath =
          "/storage/emulated/0" + "/Attendance/" + this.courseName;
      this.targetFileName = this.courseName + "_" + this.year + "_" + this.what;
    }
    genList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Attendance",
          style: GoogleFonts.acme(),
        ),
        actions: <Widget>[
          Card(
            color: Colors.white,
            child: widget.args["route"] == "displayDates"
                ? Switch(
                    value: this.what == "present",
                    onChanged: (value) {
                      setState(() {
                        this.what == "present"
                            ? this.what = "absent"
                            : this.what = "present";
                      });
                      arrangeList();
                    },
                    activeTrackColor: Colors.green,
                    activeColor: Colors.white,
                    inactiveTrackColor: Colors.red,
                  )
                : Padding(padding: EdgeInsets.all(0)),
          )
        ],
      ),
      body: (this.displayList.length == 0 &&
              this.status == Status.nodata.index &&
              this.timeStamp.length == 0)
          ? Center(child: SpinKitFadingFour(color: Colors.cyan))
          : ((this.thereStudents == false) && this.status == Status.data.index)
              ? Center(
                  child: Text("😕 EXCEL Sheet wasn't Added to the course yet!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoSlab(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 17,
                        ),
                      )))
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
                          title: Text(this.courseName.toUpperCase(),
                              style: GoogleFonts.ptSerif(
                                  textStyle: TextStyle(
                                      color: Colors.indigo[900],
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700))),
                          subtitle: Text(
                              "Last Posted on: " +
                                  this.timeStamp +
                                  "\n" +
                                  this.what.toUpperCase() +
                                  " Details",
                              style: GoogleFonts.quicksand(
                                  textStyle: TextStyle(
                                      color: Colors.deepOrangeAccent[400],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500))),
                        ),
                      ),
                      this.displayList.length == 0
                          ? Center(
                              child: Padding(
                              padding: EdgeInsets.all(50),
                              child: Text(
                                "No Data !",
                                style: GoogleFonts.architectsDaughter(
                                    textStyle: TextStyle(
                                        color: Colors.black, fontSize: 18)),
                              ),
                            ))
                          : Scrollbar(
                              child: ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: this.displayList.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: Text(
                                        (index + 1).toString() + ".",
                                        style: GoogleFonts.nanumGothic(
                                            textStyle: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      title: Text(
                                          this.displayList[index].rollNum,
                                          style: GoogleFonts.ptSansNarrow(
                                              textStyle: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.black,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      subtitle: Text(
                                        this.displayList[index].name,
                                        style: GoogleFonts.lora(
                                            textStyle: TextStyle(
                                                fontSize: 15,
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    );
                                  })),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              RaisedButton(
                                  child: Text("Generate Report"),
                                  onPressed: () async {
                                    await generateExampleDocument();
                                  },
                                  color: Colors.teal,
                                  textColor: Colors.white),
                              RaisedButton(
                                  child: Text("Open Report"),
                                  onPressed: () {
                                    openFile(
                                        context,
                                        this.targetPath +
                                            "/" +
                                            this.targetFileName +
                                            ".pdf",
                                        "pdf");
                                  },
                                  color: Colors.deepOrange,
                                  textColor: Colors.white),
                            ],
                          ))
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
        <h1 style='text-align:center;color:Crimson;font-size:30px;font-family:Almendra;'>${this.courseName.toUpperCase()}</h1>
        <br />
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
          <td style='text-align:center'>${this.year}</td>
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
    try {
      var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
          htmlContent, targetPath, targetFileName);
      generatedPdfFilePath = generatedPdfFile.path;
      if (generatedPdfFilePath.isNotEmpty) {
        Fluttertoast.showToast(
            msg: this.courseName.toLowerCase() +
                " Report Generated Successfully!",
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.blue,
            textColor: Colors.white);
      }
    } catch (identifier) {
      print(identifier);
    }
  }
}
