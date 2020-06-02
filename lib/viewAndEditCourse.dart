import 'dart:collection';
import 'dart:io';
import 'package:attendance/DataModels/courseAttendance.dart';
import 'package:attendance/DataModels/courseDetails.dart';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:attendance/Utils/StoragePermissions.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewAndEditCourse extends StatefulWidget {
  final LinkedHashMap args;
  const ViewAndEditCourse(this.args);
  ViewAndEditCourseState createState() => ViewAndEditCourseState();
}

class ViewAndEditCourseState extends State<ViewAndEditCourse> {
  CourseDetails courseDetails;
  String courseName, year;
  final fb = FirebaseDatabase.instance;

  Future<void> _launched;

  //WidgetControllers
  bool editTrainerDetails, editVenueDetails;
  bool update;

  //TextEditingControllers
  TextEditingController facultyNameController = new TextEditingController();
  TextEditingController venueController = new TextEditingController();

  //Contact Vars
  List phone;

  List<Widget> contactWidget;
  LinkedHashSet phones;

  //File utils
  String fileType = "xlsx";
  File file;
  LinkedHashSet students;
  List studentDetails;

  @override
  void initState() {
    super.initState();
    this.contactWidget = [];
    this.phones = new LinkedHashSet<dynamic>();
    this.studentDetails = [];
    grantStoragePermissionAndCreateDir(context);
    this.students = new LinkedHashSet<StudentDetails>();
    this.phone = [];
    print(widget.args);
    if (widget.args != null) {
      if (widget.args["route"] != null) {
        if (widget.args["route"] == "listOfCourses") {
          this.editTrainerDetails = false;
          this.update = false;
          this.editVenueDetails = false;
          if (widget.args["courseName"] != null) {
            this.courseName = widget.args["courseName"];
            getData(this.courseName);
          }
          if (widget.args["year"] != null) {
            this.year = widget.args["year"];
          }
        } else if (widget.args["route"] == "contacts") {
          Contact contact = widget.args["contact"];
          this.courseDetails = widget.args["courseDetails"];
          this.courseName = this.courseDetails.courseName;
          this.year = this.courseDetails.year;
          facultyNameController.text = widget.args["trainerName"];
          venueController.text = widget.args["venue"];
          this.update = widget.args["update"];
          this.editTrainerDetails = widget.args["editTrainer"];
          this.editVenueDetails = widget.args["editVenue"];
          if (contact != null) {
            this.contactWidget.add(Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    "Contact : ",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ));
            this.contactWidget.add(Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    contact.displayName.trim().toString(),
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600),
                  ),
                ));
            if (contact.phones != null) {
              contact.phones.forEach((f) {
                this.phones.add(f.value.toLowerCase().trim().toString());
              });
              this.phones.forEach((v) {
                this.phone.add(v);
                this.contactWidget.add(Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        v,
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600),
                      ),
                    ));
              });
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    facultyNameController.clear();
    facultyNameController.clear();
    venueController.clear();
    venueController.dispose();
  }

  getData(String courseName) {
    final ref = fb.reference();
    String id = courseName.trim().toLowerCase();
    ref.child("Courses").child(id).once().then((DataSnapshot data) {
      setState(() {
        this.courseDetails = CourseDetails.fromSnapshot(data);
        this.courseName = this.courseDetails.courseName;
        this.year = this.courseDetails.year;
      });
    });
  }

  postFirebase(CourseDetails courseDetails) {
    print(courseDetails.courseName);
    final ref = fb.reference();
    try {
      ref
          .child("Courses")
          .child(courseDetails.courseName)
          .set(courseDetails.toJson());
      Fluttertoast.showToast(
          msg:
              courseDetails.courseName.toLowerCase() + " Updated Successfully!",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white);
      Navigator.of(context).pushReplacementNamed("courseDetails", arguments: {
        "courseName": courseDetails.courseName,
        "route": "listOfCourses"
      });
    } on PlatformException catch (e) {
      print("Oops! " + e.toString());
    }
  }

  postFirebaseCourseAttendance(CourseAttendance courseAttendance) {
    print(courseAttendance.courseName);
    final ref = fb.reference();
    try {
      ref
          .child("CourseAttendance")
          .child(courseAttendance.courseName)
          .set(courseAttendance.toJson());
      Fluttertoast.showToast(
          msg: courseDetails.courseName.toLowerCase() +
              "Excel Added Successfully!",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white);
      Navigator.of(context).pushReplacementNamed("courseDetails", arguments: {
        "courseName": courseDetails.courseName,
        "route": "listOfCourses",
        "year": courseDetails.year,
      });
    } on PlatformException catch (e) {
      print("Oops! " + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          appBar: AppBar(
            title: Text(this.courseName.toUpperCase()),
          ),
          body: this.courseDetails == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Card(
                          elevation: 5,
                          child: ListTile(
                              title: (this.editTrainerDetails == false)
                                  ? Text(
                                      this.courseDetails.trainerName,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : TextField(
                                      controller: facultyNameController,
                                      obscureText: false,
                                      autofocus: false,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.multiline,
                                      inputFormatters: [
                                        new WhitelistingTextInputFormatter(
                                            RegExp("[A-Za-z0-9 ]")),
                                      ],
                                      decoration: InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.blue),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.pink),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    (this.editTrainerDetails == false)
                                        ? IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.deepOrange),
                                            onPressed: () {
                                              setState(() {
                                                this.update = true;
                                                this.editTrainerDetails = true;
                                                facultyNameController.text =
                                                    this
                                                        .courseDetails
                                                        .trainerName;
                                              });
                                            })
                                        : IconButton(
                                            icon: Icon(Icons.check,
                                                color: Colors.green),
                                            onPressed: () {
                                              print(facultyNameController.text);
                                              if (facultyNameController.text
                                                      .trim()
                                                      .length ==
                                                  0) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Trainer Name Can't be Empty",
                                                    toastLength:
                                                        Toast.LENGTH_LONG,
                                                    backgroundColor:
                                                        Colors.deepOrange,
                                                    textColor: Colors.white);
                                              } else {
                                                setState(() {
                                                  this
                                                          .courseDetails
                                                          .trainerName =
                                                      facultyNameController.text
                                                          .trim();
                                                  this.editTrainerDetails =
                                                      false;
                                                });
                                              }
                                            }),
                                    (this.editTrainerDetails == false)
                                        ? IconButton(
                                            icon: Icon(Icons.phone),
                                            color: Colors.green,
                                            onPressed: () {
                                              if (this
                                                      .courseDetails
                                                      .phone
                                                      .length ==
                                                  1) {
                                                _launched = _makePhoneCall(
                                                    'tel:' +
                                                        this
                                                            .courseDetails
                                                            .phone[0]);
                                              } else {
                                                showContacts(context,
                                                    this.courseDetails.phone);
                                              }
                                            })
                                        : IconButton(
                                            icon: Icon(
                                              Icons.contacts,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                  "contacts",
                                                  arguments: {
                                                    "courseDetails":
                                                        this.courseDetails,
                                                    "editTrainer":
                                                        this.editTrainerDetails,
                                                    "editVenue":
                                                        this.editVenueDetails,
                                                    "update": this.update,
                                                    "trainerName":
                                                        facultyNameController
                                                            .text
                                                            .trim(),
                                                    "venue": venueController
                                                        .text
                                                        .trim(),
                                                    "route": "courseDetails",
                                                  });
                                            },
                                          ),
                                  ])),
                        ),
                        this.contactWidget.length != 0
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: this.contactWidget)),
                              )
                            : Padding(padding: EdgeInsets.all(0)),
                        Card(
                          elevation: 5,
                          child: ListTile(
                              title: (this.editVenueDetails == false)
                                  ? Text(
                                      this.courseDetails.venue,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : TextField(
                                      controller: venueController,
                                      obscureText: false,
                                      autofocus: false,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.multiline,
                                      inputFormatters: [
                                        new WhitelistingTextInputFormatter(
                                            RegExp("[A-Za-z0-9 ]")),
                                      ],
                                      decoration: InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.blue),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.pink),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    (this.editVenueDetails == false)
                                        ? IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.deepOrange),
                                            onPressed: () {
                                              setState(() {
                                                this.update = true;
                                                this.editVenueDetails = true;
                                                venueController.text =
                                                    this.courseDetails.venue;
                                              });
                                            })
                                        : IconButton(
                                            icon: Icon(Icons.check,
                                                color: Colors.green),
                                            onPressed: () {
                                              print(venueController.text);
                                              if (venueController.text
                                                      .trim()
                                                      .length ==
                                                  0) {
                                                Fluttertoast.showToast(
                                                    msg: "Venue Can't be Empty",
                                                    toastLength:
                                                        Toast.LENGTH_LONG,
                                                    backgroundColor:
                                                        Colors.deepOrange,
                                                    textColor: Colors.white);
                                              } else {
                                                setState(() {
                                                  this.courseDetails.venue =
                                                      venueController.text
                                                          .trim();
                                                  this.editVenueDetails = false;
                                                });
                                              }
                                            }),
                                  ])),
                        ),
                        (this.update == false)
                            ? Padding(
                                padding: EdgeInsets.all(0),
                              )
                            : GradientButton(
                                callback: () {
                                  if (this.editTrainerDetails == true ||
                                      this.editVenueDetails == true) {
                                    Fluttertoast.showToast(
                                        msg:
                                            "Modified details are not saved..!",
                                        toastLength: Toast.LENGTH_LONG,
                                        backgroundColor: Colors.deepOrange,
                                        textColor: Colors.white);
                                  } else if (this.editTrainerDetails == false &&
                                      this.editVenueDetails == false) {
                                    setState(() {
                                      if (this.phone.length != 0) {
                                        this.courseDetails.phone = this.phone;
                                      }
                                    });
                                    postFirebase(this.courseDetails);
                                  }
                                },
                                child: Text("Update"),
                                gradient: Gradients.cosmicFusion,
                              ),
                        Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text(
                                "Manage Course Co-Ordinators",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Icons.settings,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        "manageCordinators",
                                        arguments: {
                                          "route": "courseDetails",
                                          "courseName": this.courseName,
                                          "year": this.year,
                                        });
                                  }),
                            )),
                        Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text(
                                "Upload Excel Sheet",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Icons.cloud_upload,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    filePicker(
                                        context, this.courseName, this.year);
                                  }),
                            )),
                        Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text(
                                "Post Attendance",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Icons.group,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        "postAttendance",
                                        arguments: {
                                          "route": "courseDetails",
                                          "courseName": this.courseName,
                                          "year": this.year,
                                        });
                                  }),
                            )),
                        Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text(
                                "Show Present Attendance",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Icons.person_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        "showAttendance",
                                        arguments: {
                                          "route": "courseDetails",
                                          "courseName": this.courseName,
                                          "what": "present"
                                        });
                                  }),
                            )),
                        Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text(
                                "Show Absent Attendance",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Icons.person_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        "showAttendance",
                                        arguments: {
                                          "route": "courseDetails",
                                          "courseName": this.courseName,
                                          "what": "absent"
                                        });
                                  }),
                            ))
                      ],
                    ),
                  ),
                ),
        ));
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  showContacts(BuildContext context, List phone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Multiple Numbers"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: phone.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(phone[index]),
                          trailing: IconButton(
                              icon: Icon(Icons.phone),
                              color: Colors.green,
                              onPressed: () {
                                _launched =
                                    _makePhoneCall('tel:' + phone[index]);
                                Navigator.of(context).pop(); // dismiss dialog
                              }),
                        );
                      }),
                )
              ],
            ));
      },
    );
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
        actions: [
          cancelButton,
          continueButton,
        ],
      ),
    );
  }

  Future filePicker(
      BuildContext context, String courseName, String year) async {
    try {
      if (fileType == 'xlsx') {
        file = await FilePicker.getFile(
            type: FileType.custom, allowedExtensions: ['xlsx']);
        if (file != null) {
          print(file);
          var bytes = file.readAsBytesSync();
          var decoder = SpreadsheetDecoder.decodeBytes(bytes);
          print(decoder.tables.keys);
          if (decoder.tables.keys.contains(this.courseName)) {
            var table = decoder.tables[this.courseName];
            var j;
            for (var i = 0; i < table.maxRows; i++) {
              if (table.rows[i].contains("Name of the Student")) {
                j = i + 1;
              }
            }
            for (var i = j; i < table.maxRows; i++) {
              setState(() {
                this.students.add(
                    new StudentDetails(table.rows[i][2], table.rows[i][1]));
              });
            }
            print(this.students.length);
            this.students.forEach((f) {
              this.studentDetails.add(f.toJson());
            });
            print(this.studentDetails.length);
            CourseAttendance courseAttendance = new CourseAttendance(
                this.courseName, this.year, this.studentDetails, null, null);
            postFirebaseCourseAttendance(courseAttendance);
            this.studentDetails.clear();
            this.students.clear();
          } else {
            Fluttertoast.showToast(
                msg: "Couldn't found " + this.courseName + " in Excel Sheet",
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: Colors.green,
                textColor: Colors.white);
          }
        } else {
          Fluttertoast.showToast(
              msg: "UnSuccessful Upload!\nTry Again.",
              toastLength: Toast.LENGTH_LONG,
              backgroundColor: Colors.green,
              textColor: Colors.white);
        }
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
}
