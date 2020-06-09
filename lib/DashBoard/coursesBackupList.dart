import 'dart:collection';
import 'package:attendance/DataModels/courseDetails.dart';
import 'package:attendance/Utils/settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_buttons/grouped_buttons.dart';

enum Status { loading, loaded }

class DisplayCoursesListBackup extends StatefulWidget {
  DisplayCoursesListBackupState createState() =>
      DisplayCoursesListBackupState();
}

class DisplayCoursesListBackupState extends State<DisplayCoursesListBackup> {
  final fb = FirebaseDatabase.instance;

  LinkedHashSet courses, items;
  int _status;

  CourseDetails courseDetails;

  List<String> yearTypes = ["1", "2", "3", "4"];
  String year;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    this._status = Status.loading.index;
    this.courses = new LinkedHashSet<CourseDetails>();
    this.items = new LinkedHashSet<CourseDetails>();
    firebaseListeners();
    super.initState();
  }

  firebaseListeners() {
    final ref = fb.reference().child("Courses");
    ref.onChildAdded.listen((onData) {
      courseDetails = CourseDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this.courses.add(courseDetails);
          this.items.add(courseDetails);
          this._status = Status.loaded.index;
        } catch (identifier) {}
      });
    });
    if (this.items.length == 0 && courseDetails == null) {
      setState(() {
        this._status = Status.loaded.index;
      });
    }
  }

  void filterSearchResults(String year) {
    List dummySearchList = List<CourseDetails>();
    dummySearchList.addAll(this.courses.toList());
    if (["1", "2", "3", "4"].contains(year)) {
      List dummyListData = List<CourseDetails>();
      dummySearchList.forEach((item) {
        if (item.year == year) {
          dummyListData.add(item);
        }
      });
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(this.courses.toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text("Backup Courses",
              style: GoogleFonts.acme(
                textStyle: TextStyle(),
              )),
        ),
        body: OfflineBuilder(
          connectivityBuilder: (
            BuildContext context,
            ConnectivityResult connectivity,
            Widget child,
          ) {
            final bool connected = connectivity != ConnectivityResult.none;
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
          child: this._status == Status.loading.index
              ? Center(
                  child: SpinKitWave(
                      color: Colors.cyan, type: SpinKitWaveType.center))
              : Container(
                  padding: EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.fromLTRB(0, 20, 0, 15),
                          child: Card(
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  Icons.assistant_photo,
                                  size: 30,
                                  color: Colors.pink,
                                ),
                                onPressed: () {
                                  setState(() {
                                    this.year = "";
                                  });
                                  filterSearchResults("all");
                                },
                              ),
                              subtitle: Text(
                                'Filter Year!',
                                style: GoogleFonts.lora(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              title: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: RadioButtonGroup(
                                  orientation:
                                      GroupedButtonsOrientation.HORIZONTAL,
                                  onSelected: (String selected) => setState(() {
                                    year = selected;

                                    filterSearchResults(this.year);
                                  }),
                                  labels: yearTypes,
                                  labelStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                  picked: year,
                                  activeColor: Colors.green,
                                  itemBuilder: (Radio rb, Text text, int i) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        rb,
                                        text,
                                        Padding(
                                          padding: EdgeInsets.all(4),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          )),
                      Expanded(
                        child: items.length == 0
                            ? Center(
                                child: Text("😕 No Courses found..!",
                                    style: GoogleFonts.robotoSlab(
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 18,
                                      ),
                                    )))
                            : Scrollbar(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      child: Card(
                                          elevation: 5,
                                          child: ListTile(
                                            title: Text(
                                                '${items.elementAt(index).courseName.toUpperCase()}',
                                                style: GoogleFonts.headlandOne(
                                                  textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                )),
                                            trailing: IconButton(
                                                icon: Icon(
                                                  Icons.remove_red_eye,
                                                  color: Colors.blue,
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
                                                              Colors.white);
                                                      openWIFISettingsVNR();
                                                    } else {
                                                      Navigator.of(context)
                                                          .pushNamed(
                                                              "displayDates",
                                                              arguments: items
                                                                  .elementAt(
                                                                      index)
                                                                  .courseName);
                                                    }
                                                  });
                                                }),
                                          )),
                                    );
                                  },
                                ),
                              ),
                      )
                    ],
                  ),
                ),
        ));
  }
}
