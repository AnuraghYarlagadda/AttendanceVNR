import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:attendance/DataModels/attendanceBackup.dart';
import 'package:attendance/Utils/Settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DisplayDates extends StatefulWidget {
  final String courseName;
  const DisplayDates(this.courseName);
  DisplayDatesState createState() => DisplayDatesState();
}

enum Status { data, nodata }

class DisplayDatesState extends State<DisplayDates> {
  String courseName, year;
  final fb = FirebaseDatabase.instance;
  BackupAttendance backupAttendance;
  int status;
  LinkedHashMap dates;
  @override
  void initState() {
    super.initState();
    this.status = Status.nodata.index;
    this.courseName = widget.courseName;
    this.year = "";
    this.dates = new LinkedHashMap<dynamic, TimeAttendance>();
    getData();
  }

  getData() async {
    final ref = fb.reference();
    await ref.child("Backup").once().then((onValue) {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.data.index;
        });
      } else {
        if (onValue.value.keys.contains(this.courseName)) {
          setState(() {
            this.status = Status.data.index;
            this.backupAttendance =
                BackupAttendance.fromJson(onValue.value[this.courseName]);
            this.year = this.backupAttendance.year;
            this.dates = this.backupAttendance.dates;
          });
        } else {
          setState(() {
            this.status = Status.data.index;
          });
        }
      }
    });
    setState(() {
      this.dates.forEach((k, v) {
        this.dates[k] = TimeAttendance.fromJson(v);
      });
      DateFormat dateFormat = new DateFormat("dd-MM-yyyy");
      var sortedKeys = this.dates.keys.toList(growable: false)
        ..sort((a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
      setState(() {
        this.dates = new LinkedHashMap.fromIterable(sortedKeys,
            key: (k) => k, value: (k) => this.dates[k]);
      });
    });
  }

  delFirebaseBackup(String date, String time) async {
    final ref = fb.reference();

    setState(() {
      this.dates.forEach((k, v) {
        if (k == date) {
          TimeAttendance timeAttendance = this.dates[date];

          timeAttendance.times.remove(time);
        }
      });
      this.backupAttendance.dates.clear();
      this.backupAttendance.dates.addAll(this.dates);
      this.backupAttendance.dates.forEach((k, v) {
        this.backupAttendance.dates[k] = v.toJson();
      });
    });
    try {
      await ref
          .child("Backup")
          .child(backupAttendance.courseName)
          .set(backupAttendance.toJson());
    } on PlatformException catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(this.courseName,
              style: GoogleFonts.acme(
                textStyle: TextStyle(),
              )),
        ),
        body: this.status == Status.nodata.index
            ? Center(
                child: CircularProgressIndicator(),
              )
            : this.dates.length == 0
                ? Center(
                    child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Text(
                      "No Backup Data Found!",
                      style: GoogleFonts.architectsDaughter(
                          textStyle:
                              TextStyle(color: Colors.black, fontSize: 18)),
                    ),
                  ))
                : SingleChildScrollView(
                    child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Scrollbar(
                            child: ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: this.dates.length,
                                itemBuilder: (context, index) {
                                  String key = this.dates.keys.elementAt(index);
                                  TimeAttendance timeAttendance =
                                      this.dates[key];
                                  var sortedKeys = timeAttendance.times.keys
                                      .toList(growable: false)
                                        ..sort((a, b) => a.compareTo(b));
                                  timeAttendance.times =
                                      new LinkedHashMap.fromIterable(sortedKeys,
                                          key: (k) => k,
                                          value: (k) =>
                                              timeAttendance.times[k]);
                                  return (Card(
                                      child: ExpansionTile(
                                    trailing: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.indigo,
                                      size: 25,
                                    ),
                                    title: Text(key,
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.normal),
                                        )),
                                    children: <Widget>[
                                      ListView.builder(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount:
                                              timeAttendance.times.length,
                                          itemBuilder: (context, index) {
                                            String keytime = timeAttendance
                                                .times.keys
                                                .elementAt(index);
                                            PresentAbsent presentAbsent =
                                                PresentAbsent.fromJson(
                                                    timeAttendance
                                                        .times[keytime]);
                                            return (ListTile(
                                              title: Text(
                                                keytime,
                                                style: GoogleFonts.openSans(
                                                    textStyle: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  IconButton(
                                                      icon: Icon(
                                                        Icons.remove_red_eye,
                                                        color: Colors.teal,
                                                      ),
                                                      onPressed: () async {
                                                        await (Connectivity()
                                                                .checkConnectivity())
                                                            .then((onValue) {
                                                          if (onValue ==
                                                              ConnectivityResult
                                                                  .none) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    "No Active Internet Connection!",
                                                                toastLength: Toast
                                                                    .LENGTH_SHORT,
                                                                backgroundColor:
                                                                    Colors.red,
                                                                textColor:
                                                                    Colors
                                                                        .white);
                                                            openWIFISettingsVNR();
                                                          } else {
                                                            Navigator.of(
                                                                    context)
                                                                .pushNamed(
                                                                    "showAttendance",
                                                                    arguments: {
                                                                  "route":
                                                                      "displayDates",
                                                                  "timeStamp":
                                                                      key +
                                                                          " " +
                                                                          keytime,
                                                                  "courseName":
                                                                      this.courseName,
                                                                  "year":
                                                                      this.year,
                                                                  "data":
                                                                      presentAbsent
                                                                });
                                                          }
                                                        });
                                                      }),
                                                  IconButton(
                                                      icon: Icon(
                                                        Icons.delete_forever,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () async {
                                                        await (Connectivity()
                                                                .checkConnectivity())
                                                            .then((onValue) {
                                                          if (onValue ==
                                                              ConnectivityResult
                                                                  .none) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    "No Active Internet Connection!",
                                                                toastLength: Toast
                                                                    .LENGTH_SHORT,
                                                                backgroundColor:
                                                                    Colors.red,
                                                                textColor:
                                                                    Colors
                                                                        .white);
                                                            openWIFISettingsVNR();
                                                          } else {
                                                            if (timeAttendance
                                                                    .times
                                                                    .length >
                                                                2) {
                                                              showAlertDialog(
                                                                  context,
                                                                  key,
                                                                  keytime);
                                                            } else {
                                                              Fluttertoast.showToast(
                                                                  msg:
                                                                      "Can't delete a date with less than two times!",
                                                                  toastLength: Toast
                                                                      .LENGTH_SHORT,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  textColor:
                                                                      Colors
                                                                          .white);
                                                            }
                                                          }
                                                        });
                                                      }),
                                                ],
                                              ),
                                            ));
                                          })
                                    ],
                                  )));
                                })))));
  }

  showAlertDialog(BuildContext context, String date, String time) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text(
        "Cancel",
        style: TextStyle(
            color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
      },
    );
    Widget continueButton = FlatButton(
      child: Text(
        "Continue",
        style: TextStyle(
            color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      onPressed: () async {
        Navigator.of(context).pop(); // dismiss dialog
        await delFirebaseBackup(date, time);
        Fluttertoast.showToast(
            msg: time + " Deleted!",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete records at Time?"),
      content: Text(time),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
