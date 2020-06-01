import 'dart:collection';
import 'package:attendance/DataModels/courseCoordinatorsDetails.dart';
import 'package:attendance/DataModels/courseDetails.dart';
import 'package:attendance/Utils/settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_buttons/grouped_buttons.dart';

enum Status { loading, loaded }

class DisplayCoursesList extends StatefulWidget {
  DisplayCoursesListState createState() => DisplayCoursesListState();
}

class DisplayCoursesListState extends State<DisplayCoursesList> {
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
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.courses.length);
    });
    ref.onChildChanged.listen((onData) {
      courseDetails = CourseDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this.courses.forEach((value) {
            if (courseDetails.courseName == value.courseName) {
              value.lock = courseDetails.lock;
            }
          });
          this.items.forEach((value) {
            if (courseDetails.courseName == value.courseName) {
              value.lock = courseDetails.lock;
            }
          });
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.courses.length);
    });
    ref.onChildRemoved.listen((onData) {
      courseDetails = CourseDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this.courses.removeWhere(
              (value) => value.courseName == courseDetails.courseName);
          this.items.removeWhere(
              (value) => value.courseName == courseDetails.courseName);
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.courses.length);
    });
  }

  changeLockFirebase(String courseName, bool lock) {
    final ref = fb.reference();
    print(courseName);
    ref.child("Courses").child(courseName).child("lock").set(lock);
  }

  delFirebase(String courseName) async {
    final ref = fb.reference();
    ref.child("Courses").child(courseName).remove();
    List keys = [];
    await ref.child("CourseCoordinators").once().then((data) {
      keys.addAll(data.value.keys);
    });
    keys.forEach((f) async {
      await ref.child("CourseCoordinators").child(f).once().then((data) {
        CourseCoordinatorsDetails coordinatorsDetails =
            CourseCoordinatorsDetails.fromSnapshot(data);
        print(coordinatorsDetails.courses);
        coordinatorsDetails.courses.removeWhere((a, b) => a == courseName);
        print(coordinatorsDetails.courses);
        if (coordinatorsDetails.courses.length == 0) {
          //del user n firebase
          String id = coordinatorsDetails.email.replaceAll('.', ',');
          id = id.replaceAll('@', ',');
          id = id.replaceAll('#', ',');
          id = id.replaceAll('[', ',');
          id = id.replaceAll(']', ',');
          ref.child("CourseCoordinators").child(id).remove();
        } else {
          String id = coordinatorsDetails.email.replaceAll('.', ',');
          id = id.replaceAll('@', ',');
          id = id.replaceAll('#', ',');
          id = id.replaceAll('[', ',');
          id = id.replaceAll(']', ',');
          ref
              .child("CourseCoordinators")
              .child(id)
              .set(coordinatorsDetails.toJson());
        }
      });
    });
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
          title: Text("Courses"),
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
                      color: Colors.blue, type: SpinKitWaveType.start))
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
                                style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 15,
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
                                    print("Year = " + this.year);
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
                            ? Center(child: Text("😕 No Courses found..!"))
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
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                IconButton(
                                                    icon: items
                                                            .elementAt(index)
                                                            .lock
                                                        ? Icon(
                                                            Icons.lock,
                                                            color: Colors
                                                                .redAccent,
                                                          )
                                                        : Icon(
                                                            Icons.lock_open,
                                                            color: Colors.green,
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
                                                          changeLockFirebase(
                                                              items
                                                                  .elementAt(
                                                                      index)
                                                                  .courseName
                                                                  .toString()
                                                                  .toLowerCase(),
                                                              !(items
                                                                  .elementAt(
                                                                      index)
                                                                  .lock));
                                                          (items
                                                                      .elementAt(
                                                                          index)
                                                                      .lock ==
                                                                  true)
                                                              ? Fluttertoast.showToast(
                                                                  msg: "Course UnLocked! " +
                                                                      items
                                                                          .elementAt(
                                                                              index)
                                                                          .courseName
                                                                          .toString()
                                                                          .toUpperCase(),
                                                                  toastLength:
                                                                      Toast
                                                                          .LENGTH_LONG,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                  textColor:
                                                                      Colors
                                                                          .white)
                                                              : Fluttertoast.showToast(
                                                                  msg: "Course Locked! " +
                                                                      items
                                                                          .elementAt(
                                                                              index)
                                                                          .courseName
                                                                          .toString()
                                                                          .toUpperCase(),
                                                                  toastLength: Toast
                                                                      .LENGTH_LONG,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  textColor:
                                                                      Colors
                                                                          .white);
                                                        }
                                                      });
                                                    }),
                                                IconButton(
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
                                                                  "courseDetails",
                                                                  arguments: {
                                                                "courseName": items
                                                                    .elementAt(
                                                                        index)
                                                                    .courseName
                                                                    .toString()
                                                                    .toLowerCase(),
                                                                "route":
                                                                    "listOfCourses"
                                                              });
                                                        }
                                                      });
                                                    }),
                                                IconButton(
                                                    icon: Icon(
                                                      Icons.delete_forever,
                                                      color: Colors.redAccent,
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
                                                          showAlertDialog(
                                                              context,
                                                              items
                                                                  .elementAt(
                                                                      index)
                                                                  .courseName
                                                                  .toUpperCase());
                                                        }
                                                      });
                                                    }),
                                              ],
                                            ),
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

  showAlertDialog(BuildContext context, String courseName) {
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
        await delFirebase(courseName.toLowerCase());
        Fluttertoast.showToast(
            msg: courseName + " Deleted!",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white);
        Navigator.of(context).pop(); // dismiss dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete Course?"),
      content: Text(courseName),
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
