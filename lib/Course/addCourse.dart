import 'dart:collection';

import 'package:attendance/DataModels/courseDetails.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:gradient_widgets/gradient_widgets.dart';

class AddCourse extends StatefulWidget {
  final LinkedHashMap args;
  const AddCourse(this.args);
  AddCourseState createState() => AddCourseState();
}

class AddCourseState extends State<AddCourse> {
  String year;
  List phone;

  TextEditingController courseNameController = new TextEditingController();
  TextEditingController facultyNameController = new TextEditingController();
  TextEditingController venueController = new TextEditingController();

  List<String> yearTypes = ["1", "2", "3", "4"];

  List<Widget> contactWidget;
  LinkedHashSet phones;

  final fb = FirebaseDatabase.instance;
  @override
  void initState() {
    super.initState();
    this.contactWidget = [];
    this.phones = new LinkedHashSet<dynamic>();
    this.phone = [];
    this.year = "";
    if (widget.args != null) {
      Contact contact = widget.args["contact"];
      courseNameController.text = widget.args["courseName"];
      facultyNameController.text = widget.args["facultyName"];
      venueController.text = widget.args["venue"];
      this.year = widget.args["year"];
      if (contact != null) {
        this.contactWidget.add(Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                "Contact : ",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ));
        this.contactWidget.add(Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                contact.displayName.trim().toString(),
                style: TextStyle(
                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
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

  postFirebase(CourseDetails courseDetails) async {
    final ref = fb.reference();
    try {
      await ref
          .child("Courses")
          .child(courseDetails.courseName)
          .set(courseDetails.toJson());
      Fluttertoast.showToast(
          msg: "Added " + courseDetails.courseName,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white);
      Navigator.of(context).pushReplacementNamed("listOfCourses");
    } on PlatformException catch (e) {}
  }

  @override
  void dispose() {
    super.dispose();
    courseNameController.clear();
    facultyNameController.clear();
    venueController.clear();
    courseNameController.dispose();
    facultyNameController.dispose();
    venueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
            appBar: AppBar(
              title: Text("Add Course",
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
              child: Padding(
                padding: EdgeInsets.all(10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: courseNameController,
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
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            border: InputBorder.none,
                            labelText: 'Enter Course Name *',
                            labelStyle: TextStyle(color: Colors.blueGrey)),
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      TextField(
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
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            border: InputBorder.none,
                            labelText: 'Enter Faculty Name *',
                            labelStyle: TextStyle(color: Colors.blueGrey)),
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                "Trainer Contact",
                                style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                  icon: Icon(
                                    Icons.contacts,
                                    size: 30,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed("contacts", arguments: {
                                      "courseName": courseNameController.text
                                          .trim()
                                          .toLowerCase(),
                                      "facultyName":
                                          facultyNameController.text.trim(),
                                      "venue": venueController.text.trim(),
                                      "year": this.year,
                                      "route": "addCourse",
                                    });
                                  }),
                              this.contactWidget.length != 0
                                  ? Row(children: this.contactWidget)
                                  : Padding(padding: EdgeInsets.all(0))
                            ],
                          )),
                      Divider(
                        thickness: 1,
                        color: Colors.pink,
                        height: 2,
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      TextField(
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
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            border: InputBorder.none,
                            labelText: 'Enter Venue *',
                            labelStyle: TextStyle(color: Colors.blueGrey)),
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      Center(
                          child: Text('Year :',
                              style: GoogleFonts.lora(
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 18,
                                ),
                              ))),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: RadioButtonGroup(
                          orientation: GroupedButtonsOrientation.HORIZONTAL,
                          onSelected: (String selected) => setState(() {
                            year = selected;
                          }),
                          labels: yearTypes,
                          labelStyle: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          picked: year,
                          activeColor: Colors.green,
                          itemBuilder: (Radio rb, Text text, int i) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                rb,
                                text,
                                Padding(
                                  padding: EdgeInsets.all(11),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.pink,
                        height: 2,
                      ),
                      Padding(
                        padding: EdgeInsets.all(50),
                        child: GradientButton(
                          callback: () {
                            String courseName, trainerName, venue;
                            courseName =
                                courseNameController.text.trim().toLowerCase();
                            trainerName = facultyNameController.text.trim();
                            venue = venueController.text.trim();
                            if (courseName == null || courseName.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "Course Name can't be EMPTY!",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.deepOrange,
                                  textColor: Colors.white);
                            }
                            if (trainerName == null ||
                                trainerName.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "Trainer Name can't be EMPTY!",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.deepOrange,
                                  textColor: Colors.white);
                            }
                            if (venue == null || venue.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "Venue can't be EMPTY!",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.deepOrange,
                                  textColor: Colors.white);
                            }
                            if (this.phone == null || this.phone.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "Pick Trainer Contact!",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.deepOrange,
                                  textColor: Colors.white);
                            }
                            if (this.year == null || this.year.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "Year has to be selected!",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.deepOrange,
                                  textColor: Colors.white);
                            }
                            if (courseName.length != 0 &&
                                trainerName.length != 0 &&
                                venue.length != 0 &&
                                this.year.length != 0 &&
                                this.phone.length != 0) {
                              CourseDetails courseDetails = new CourseDetails(
                                  courseName,
                                  trainerName,
                                  venue,
                                  this.year,
                                  this.phone,
                                  true);
                              postFirebase(courseDetails);
                              WidgetsBinding.instance.focusManager.primaryFocus
                                  ?.unfocus();
                              courseNameController.clear();
                              facultyNameController.clear();
                              venueController.clear();
                            }
                          },
                          child: Text("SUBMIT"),
                          gradient: Gradients.byDesign,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
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
        content: new Text('Data not submitted!'),
        actions: [
          cancelButton,
          continueButton,
        ],
      ),
    );
  }
}
