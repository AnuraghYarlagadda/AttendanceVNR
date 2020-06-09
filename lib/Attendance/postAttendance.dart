import 'dart:collection';
import 'package:attendance/DataModels/attendanceBackup.dart';
import 'package:attendance/DataModels/courseAttendance.dart';
import 'package:attendance/DataModels/studentAttendanceDetails.dart';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PostAttendance extends StatefulWidget {
  final LinkedHashMap args;
  const PostAttendance(this.args);
  PostAttendanceState createState() => PostAttendanceState();
}

enum Status { data, nodata }

class PostAttendanceState extends State<PostAttendance> {
  final fb = FirebaseDatabase.instance;
  String courseName, year;
  CourseAttendance courseAttendance;

  LinkedHashSet display;
  var total, presentees, absentees, displayList;

  int status;

  @override
  void initState() {
    super.initState();
    this.status = Status.data.index;
    this.total = new List();
    this.presentees = new List();
    this.absentees = new List();
    this.displayList = new List<StudentAttendanceDetails>();
    this.display = LinkedHashSet<StudentAttendanceDetails>();
    if (widget.args != null) {
      if (widget.args["route"] == "courseDetails") {
        this.courseName = widget.args["courseName"];
        this.year = widget.args["year"];
      }
    }
    getData();
  }

  getData() async {
    final ref = fb.reference().child("CourseAttendance");
    await ref.once().then((onValue) async {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.nodata.index;
        });
      } else {
        await ref.child(this.courseName).once().then((data) {
          if (data.value == null) {
            setState(() {
              this.status = Status.nodata.index;
            });
          } else {
            setState(() {
              this.status = Status.data.index;
              this.courseAttendance = CourseAttendance.fromSnapshot(data);
              if (this.courseAttendance.students != null)
                this.total.addAll(this.courseAttendance.students);
              if (this.courseAttendance.presentees != null)
                this.presentees.addAll(this.courseAttendance.presentees);
              if (this.courseAttendance.absentees != null)
                this.absentees.addAll(this.courseAttendance.absentees);
            });
            setState(() {
              if (this.presentees == null && this.absentees == null) {
                this.total.forEach((f) {
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], false));
                });
              } else if (this.presentees == null && this.absentees != null) {
                this.total.forEach((f) {
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], true));
                });
                this.absentees.forEach((f) {
                  this
                      .display
                      .removeWhere((item) => item.rollNum == f["rollNum"]);
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], false));
                });
              } else if (this.presentees != null && this.absentees == null) {
                this.total.forEach((f) {
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], false));
                });
                this.presentees.forEach((f) {
                  this
                      .display
                      .removeWhere((item) => item.rollNum == f["rollNum"]);
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], true));
                });
              } else if (this.presentees != null && this.absentees != null) {
                this.total.forEach((f) {
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], false));
                });
                this.presentees.forEach((f) {
                  this
                      .display
                      .removeWhere((item) => item.rollNum == f["rollNum"]);
                  this.display.add(new StudentAttendanceDetails(
                      f["rollNum"], f["name"], true));
                });
              }
            });
            setState(() {
              this.displayList.addAll(this.display.toList());
              this.displayList
                ..sort((StudentAttendanceDetails a,
                        StudentAttendanceDetails b) =>
                    a.rollNum.toUpperCase().compareTo(b.rollNum.toUpperCase()));
            });
          }
        });
      }
    });
  }

  postFirebaseAttendance(CourseAttendance courseAttendance) async {
    final ref = fb.reference();
    try {
      await ref
          .child("CourseAttendance")
          .child(courseAttendance.courseName)
          .set(courseAttendance.toJson());
      String timeStamp = DateFormat.yMEd().add_jms().format(DateTime.now());
      await ref
          .child("TimeStamp")
          .child(courseAttendance.courseName)
          .set(timeStamp);
      Navigator.of(context).popUntil(ModalRoute.withName('courseDetails'));
      Navigator.of(context).pushReplacementNamed("courseDetails", arguments: {
        "courseName": courseAttendance.courseName,
        "route": "listOfCourses",
        "year": courseAttendance.year,
      });
      Fluttertoast.showToast(
          msg: courseAttendance.courseName.toLowerCase() +
              " Attendance posted Successfully!",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white);
    } on PlatformException catch (e) {}
  }

  postBackupAttendance(CourseAttendance courseAttendance) async {
    var dateinput = new DateTime.now();
    var dateFormatter = new DateFormat('dd-MM-yyyy');
    var timeFormatter = new DateFormat('HH:mm:ss');
    // var hourFormatter = new DateFormat('H');
    // var minFormatter = new DateFormat('m');
    // int hour = int.tryParse(hourFormatter.format(dateinput)) ?? 0;
    // int min = int.tryParse(minFormatter.format(dateinput)) ?? 0;
    String date = dateFormatter.format(dateinput);
    //String date = "05-07-2020";
    String time = timeFormatter.format(dateinput);
    PresentAbsent presentAbsent = new PresentAbsent(
        courseAttendance.presentees, courseAttendance.absentees);
    LinkedHashMap timemap = new LinkedHashMap<dynamic, dynamic>();
    timemap[time] = presentAbsent.toJson();
    TimeAttendance timeAttendance = new TimeAttendance(timemap);
    LinkedHashMap datemap = new LinkedHashMap<dynamic, dynamic>();
    datemap[date] = timeAttendance.toJson();

    final ref = fb.reference();
    try {
      await ref.child("Backup").once().then((onValue) async {
        if (onValue.value == null) {
          BackupAttendance backupAttendance = new BackupAttendance(
              courseAttendance.courseName, courseAttendance.year, datemap);
          try {
            await ref
                .child("Backup")
                .child(backupAttendance.courseName)
                .set(backupAttendance.toJson());
          } on PlatformException catch (e) {}
        } else {
          if (onValue.value.keys.contains(courseAttendance.courseName)) {
            try {
              await ref
                  .child("Backup")
                  .child(courseAttendance.courseName)
                  .child("dates")
                  .once()
                  .then((onValue) async {
                LinkedHashMap datemapDataBase = onValue.value;
                if (datemapDataBase.containsKey(date)) {
                  LinkedHashMap timemapDatabase =
                      datemapDataBase[date]["times"];
                  timemapDatabase[time] = presentAbsent.toJson();

                  datemapDataBase[date]["times"] = timemapDatabase;

                  await ref
                      .child("Backup")
                      .child(courseAttendance.courseName)
                      .child("dates")
                      .set(datemapDataBase);
                } else {
                  datemapDataBase[date] = timeAttendance.toJson();

                  await ref
                      .child("Backup")
                      .child(courseAttendance.courseName)
                      .child("dates")
                      .set(datemapDataBase);
                }
              });
            } on PlatformException catch (e) {}
          } else {
            BackupAttendance backupAttendance = new BackupAttendance(
                courseAttendance.courseName, courseAttendance.year, datemap);
            try {
              await ref
                  .child("Backup")
                  .child(backupAttendance.courseName)
                  .set(backupAttendance.toJson());
            } on PlatformException catch (e) {}
          }
        }
      });
    } on PlatformException catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                "Attendance",
                style: GoogleFonts.acme(),
              ),
            ),
            body: OfflineBuilder(
                connectivityBuilder: (
                  BuildContext context,
                  ConnectivityResult connectivity,
                  Widget child,
                ) {
                  final bool connected =
                      connectivity != ConnectivityResult.none;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      Positioned(
                        height: 20.0,
                        left: 0.0,
                        right: 0.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          color: connected ? Colors.transparent : Colors.red,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: connected
                                ? Text(
                                    '',
                                    style: TextStyle(color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Offline',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 8.0),
                                      SizedBox(
                                        width: 12.0,
                                        height: 12.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: (this.displayList.length == 0 &&
                        this.status == Status.data.index)
                    ? Center(child: SpinKitCircle(color: Colors.cyan))
                    : (this.displayList.length == 0 &&
                            this.status == Status.nodata.index)
                        ? Center(
                            child: Text(
                                "😕 EXCEL Sheet wasn't Added to the course yet!",
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
                                    padding:
                                        EdgeInsets.fromLTRB(10, 15, 10, 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        RaisedButton(
                                          onPressed: () {
                                            setState(() {
                                              this.displayList.forEach((f) {
                                                f.present = true;
                                              });
                                            });
                                          },
                                          child: Text("Check all"),
                                          color: Colors.green,
                                          textColor: Colors.white,
                                        ),
                                        RaisedButton(
                                            onPressed: () {
                                              setState(() {
                                                this.displayList.forEach((f) {
                                                  f.present = false;
                                                });
                                              });
                                            },
                                            child: Text("Clear all"),
                                            color: Colors.red,
                                            textColor: Colors.white),
                                      ],
                                    ),
                                  ),
                                  Scrollbar(
                                      child: ListView.builder(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: this.displayList.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                                child: Card(
                                                    elevation: 5,
                                                    child: ListTile(
                                                      title: Text(
                                                          this
                                                              .displayList[
                                                                  index]
                                                              .rollNum,
                                                          style: GoogleFonts.ptSansNarrow(
                                                              textStyle: TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700))),
                                                      subtitle: Text(
                                                          this
                                                              .displayList[
                                                                  index]
                                                              .name,
                                                          style: GoogleFonts.inconsolata(
                                                              textStyle: TextStyle(
                                                                  color: Colors
                                                                      .blueGrey,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600))),
                                                      trailing: Checkbox(
                                                          activeColor:
                                                              Colors.green,
                                                          value: this
                                                              .displayList[
                                                                  index]
                                                              .present,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              this
                                                                  .displayList[
                                                                      index]
                                                                  .present = value;
                                                            });
                                                          }),
                                                    )));
                                          })),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: RaisedButton(
                                        child: Text("Post Attendance"),
                                        onPressed: () {
                                          this.presentees.clear();
                                          this.absentees.clear();
                                          this.displayList.forEach((f) {
                                            if (f.present == true) {
                                              this.presentees.add(
                                                  new StudentDetails(
                                                          f.rollNum, f.name)
                                                      .toJson());
                                            } else {
                                              this.absentees.add(
                                                  new StudentDetails(
                                                          f.rollNum, f.name)
                                                      .toJson());
                                            }
                                          });
                                          setState(() {
                                            this.courseAttendance.presentees =
                                                this.presentees;
                                            this.courseAttendance.absentees =
                                                this.absentees;
                                          });
                                          postFirebaseAttendance(
                                              this.courseAttendance);
                                          postBackupAttendance(
                                              this.courseAttendance);
                                        },
                                        color: Colors.teal,
                                        textColor: Colors.white),
                                  ),
                                ])))));
  }

  Future<bool> _onBackPressed() {
    Widget cancelButton = FlatButton(
      child: Text(
        "YES",
        style: TextStyle(
            color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );
    Widget continueButton = FlatButton(
      child: Text(
        "NO",
        style: TextStyle(
            color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: Text("Attendance is not posted!"),
        actions: [
          cancelButton,
          continueButton,
        ],
      ),
    );
  }
}
