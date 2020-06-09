import 'dart:collection';
import 'package:attendance/DataModels/courseCoordinatorsDetails.dart';
import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageCordinators extends StatefulWidget {
  final LinkedHashMap args;
  const ManageCordinators(this.args);
  @override
  ManageCordinatorsState createState() => ManageCordinatorsState();
}

class ManageCordinatorsState extends State<ManageCordinators> {
  TextEditingController emailController = new TextEditingController();
  var coordinators;
  final fb = FirebaseDatabase.instance;
  double width, height;
  var defaultAdmins;
  CourseCoordinatorsDetails coordinatorsDetails;
  List<Widget> contactWidget;
  LinkedHashSet phones;

  Future<void> _launched;

  LinkedHashMap courses;
  String courseName;

  @override
  void initState() {
    super.initState();
    this.coordinators = <CourseCoordinatorsDetails>{};
    this.contactWidget = [];
    this.phones = new LinkedHashSet<dynamic>();
    this.courseName = "";
    this.courses = new LinkedHashMap<dynamic, bool>();
    print(widget.args);
    if (widget.args != null) {
      if (widget.args["route"] == "courseDetails") {
        this.courseName = widget.args["courseName"];
      } else if (widget.args["route"] == "contacts") {
        Contact contact = widget.args["contact"];
        emailController.text = widget.args["email"];
        this.courseName = widget.args["courseName"];
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
                      fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                ),
              ));
          if (contact.phones != null) {
            contact.phones.forEach((f) {
              this.phones.add(f.value.toLowerCase().trim().toString());
            });
            this.phones.forEach((v) {
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
    print(this.coordinators);
    this.defaultAdmins = <dynamic>{
      "anuraghyarlagadda@gmail.com",
      "ramakrishna_p@vnrvjiet.in",
      "bharathkumarchowdary@gmail.com"
    };
    getData();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    super.dispose();
  }

  getData() {
    final ref = fb.reference().child("CourseCoordinators");
    ref.onChildAdded.listen((onData) {
      coordinatorsDetails =
          CourseCoordinatorsDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          print("On ADDED");
          print(coordinatorsDetails.email);
          print(coordinatorsDetails.courses);
          if (coordinatorsDetails.courses.containsKey(this.courseName)) {
            this.coordinators.add(coordinatorsDetails);
          }
          print(this.coordinators.length);
        } catch (identifier) {
          print("Added  ");
          print(identifier);
        }
      });
      print(this.courseName);
      print(this.coordinators.length);
    });
    ref.onChildRemoved.listen((onData) {
      print(onData.snapshot.value);
      coordinatorsDetails =
          CourseCoordinatorsDetails.fromSnapshot(onData.snapshot);
      setState(() {
        print("On REMOVED");
        print(coordinatorsDetails.email);
        print(coordinatorsDetails.courses);
        try {
          print("Removed");
        } catch (identifier) {
          print("Removed  ");
          print(identifier);
        }
      });
      print("Manage");
      print(this.coordinators.length);
    });
    ref.onChildChanged.listen((onData) {
      coordinatorsDetails =
          CourseCoordinatorsDetails.fromSnapshot(onData.snapshot);
      setState(() {
        print("On CHANGED");
        print(coordinatorsDetails.email);
        print(coordinatorsDetails.courses);
        if (coordinatorsDetails.courses != null) {
          if (coordinatorsDetails.courses.containsKey(this.courseName)) {
            if (this
                    .coordinators
                    .where((item) => (item.email == coordinatorsDetails.email))
                    .length >
                0) {
              this.coordinators.removeWhere(
                  (item) => item.email == coordinatorsDetails.email);
              this.coordinators.add(coordinatorsDetails);
            } else {
              this.coordinators.add(coordinatorsDetails);
            }
          } else {
            print("akkada");
            if (this
                    .coordinators
                    .where((item) => (item.email == coordinatorsDetails.email))
                    .length >
                0) {
              this.coordinators.removeWhere(
                  (item) => item.email == coordinatorsDetails.email);
            }
          }
        } else {
          print("ikkada");
          if (this
                  .coordinators
                  .where((item) => (item.email == coordinatorsDetails.email))
                  .length >
              0) {
            this
                .coordinators
                .removeWhere((item) => item.email == coordinatorsDetails.email);
          }
          String id = coordinatorsDetails.email.replaceAll('.', ',');
          id = id.replaceAll('@', ',');
          id = id.replaceAll('#', ',');
          id = id.replaceAll('[', ',');
          id = id.replaceAll(']', ',');
          ref.child(id).remove();
        }
      });
      print(this.courseName);
      print(this.coordinators.length);
    });
  }

  postFirebase(CourseCoordinatorsDetails coordinatorsDetails) {
    String id = coordinatorsDetails.email.replaceAll('.', ',');
    LinkedHashMap courses = new LinkedHashMap<dynamic, bool>();
    id = id.replaceAll('@', ',');
    id = id.replaceAll('#', ',');
    id = id.replaceAll('[', ',');
    id = id.replaceAll(']', ',');
    final ref = fb.reference();
    ref
        .child("CourseCoordinators")
        .child(id)
        .child("courses")
        .once()
        .then((onValue) {
      print(onValue.value);
      if (onValue.value == null) {
        ref
            .child("CourseCoordinators")
            .child(id)
            .set(coordinatorsDetails.toJson());
      } else {
        courses = onValue.value;
        coordinatorsDetails.courses.forEach((k, v) {
          courses[k] = v;
        });
        coordinatorsDetails.courses = courses;
        ref
            .child("CourseCoordinators")
            .child(id)
            .set(coordinatorsDetails.toJson());
      }
    });
  }

  changePermissionFirebase(
      CourseCoordinatorsDetails coordinatorsDetails, bool permission) {
    String id = coordinatorsDetails.email.replaceAll('.', ',');
    LinkedHashMap courses = new LinkedHashMap<dynamic, bool>();
    id = id.replaceAll('@', ',');
    id = id.replaceAll('#', ',');
    id = id.replaceAll('[', ',');
    id = id.replaceAll(']', ',');
    final ref = fb.reference();
    ref
        .child("CourseCoordinators")
        .child(id)
        .child("courses")
        .once()
        .then((onValue) {
      print(onValue.value);
      if (onValue.value == null) {
      } else {
        courses = onValue.value;
        courses[this.courseName] = permission;
        coordinatorsDetails.courses = courses;
        ref
            .child("CourseCoordinators")
            .child(id)
            .set(coordinatorsDetails.toJson());
      }
    });
  }

  delFirebase(CourseCoordinatorsDetails coordinatorsDetails) {
    String id = coordinatorsDetails.email.replaceAll('.', ',');
    LinkedHashMap courses = new LinkedHashMap<dynamic, bool>();
    id = id.replaceAll('@', ',');
    id = id.replaceAll('#', ',');
    id = id.replaceAll('[', ',');
    id = id.replaceAll(']', ',');
    final ref = fb.reference();
    ref
        .child("CourseCoordinators")
        .child(id)
        .child("courses")
        .once()
        .then((onValue) {
      print(onValue.value);
      if (onValue.value == null) {
      } else {
        courses = onValue.value;
        courses.remove(this.courseName);
        coordinatorsDetails.courses = courses;
        ref
            .child("CourseCoordinators")
            .child(id)
            .set(coordinatorsDetails.toJson());
      }
    });
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    this.height = MediaQuery.of(context).size.height;
    this.width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text("Manage Coordinators",
              style: GoogleFonts.acme(
                textStyle: TextStyle(),
              )),
          leading: Icon(Icons.group_add),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(this.courseName.toUpperCase(),
                        style: GoogleFonts.ptSerif(
                          textStyle:
                              TextStyle(color: Colors.black, fontSize: 20),
                        )),
                  ),
                  (this.coordinators == null)
                      ? Container(
                          padding: EdgeInsets.all(15),
                          child: SpinKitWanderingCubes(color: Colors.cyan))
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: this.coordinators.length,
                          itemBuilder: (BuildContext context, int index) {
                            if (this.coordinators.elementAt(index) != null) {
                              return new Column(
                                children: <Widget>[
                                  new ListTile(
                                      title: new Text(
                                        this
                                            .coordinators
                                            .elementAt(index)
                                            .email,
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.normal),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          IconButton(
                                              icon: Icon(Icons.phone),
                                              color: Colors.blue,
                                              onPressed: () {
                                                if (this
                                                        .coordinators
                                                        .elementAt(index)
                                                        .phone
                                                        .length ==
                                                    1) {
                                                  _launched = _makePhoneCall(
                                                      'tel:' +
                                                          this
                                                              .coordinators
                                                              .elementAt(index)
                                                              .phone[0]);
                                                } else {
                                                  showContacts(
                                                      context,
                                                      this
                                                          .coordinators
                                                          .elementAt(index)
                                                          .phone);
                                                }
                                              }),
                                          !this.defaultAdmins.contains(this
                                                  .coordinators
                                                  .elementAt(index)
                                                  .email)
                                              ? Switch(
                                                  value: this
                                                      .coordinators
                                                      .elementAt(index)
                                                      .courses[this.courseName],
                                                  onChanged: (value) {
                                                    value
                                                        ? Fluttertoast.showToast(
                                                            msg: "Granted Permission to " +
                                                                this
                                                                    .coordinators
                                                                    .elementAt(
                                                                        index)
                                                                    .email,
                                                            toastLength: Toast
                                                                .LENGTH_LONG,
                                                            backgroundColor:
                                                                Colors.green,
                                                            textColor:
                                                                Colors.white)
                                                        : Fluttertoast.showToast(
                                                            msg: "Revoked Permission to " +
                                                                this
                                                                    .coordinators
                                                                    .elementAt(
                                                                        index)
                                                                    .email,
                                                            toastLength: Toast
                                                                .LENGTH_LONG,
                                                            backgroundColor:
                                                                Colors.red,
                                                            textColor:
                                                                Colors.white);
                                                    changePermissionFirebase(
                                                        this
                                                            .coordinators
                                                            .elementAt(index),
                                                        !this
                                                                .coordinators
                                                                .elementAt(index)
                                                                .courses[
                                                            this.courseName]);
                                                  },
                                                  activeTrackColor:
                                                      Colors.green,
                                                  activeColor: Colors.white,
                                                  inactiveTrackColor:
                                                      Colors.red,
                                                )
                                              : Padding(
                                                  padding: EdgeInsets.all(0)),
                                          !this.defaultAdmins.contains(this
                                                  .coordinators
                                                  .elementAt(index)
                                                  .email)
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.remove_circle_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    showAlertDialog(
                                                        context,
                                                        this
                                                            .coordinators
                                                            .elementAt(index));
                                                  })
                                              : Padding(
                                                  padding: EdgeInsets.all(0)),
                                        ],
                                      )),
                                  new Divider(
                                    height: 2.0,
                                    thickness: 2.5,
                                  ),
                                ],
                              );
                            } else {
                              return (Text(""));
                            }
                          },
                        ),
                  this.coordinators.length == 0
                      ? Padding(padding: EdgeInsets.all(0))
                      : Padding(padding: EdgeInsets.all(25)),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          SizedBox(
                            width: this.width / 1.5,
                            child: TextField(
                              controller: emailController,
                              obscureText: false,
                              autofocus: false,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.pink),
                                ),
                                border: InputBorder.none,
                                hintText: 'Enter Email-ID',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: this.width / 10,
                            child: IconButton(
                              icon: Icon(
                                Icons.contacts,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed("contacts", arguments: {
                                  "email": emailController.text.trim(),
                                  "route": "manageCordinators",
                                  "courseName": this.courseName,
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: this.width / 10,
                            child: IconButton(
                              icon: Icon(Icons.group_add),
                              onPressed: () async {
                                WidgetsBinding
                                    .instance.focusManager.primaryFocus
                                    ?.unfocus();
                                if (validateGoogleEmail(
                                        emailController.text.trim()) ||
                                    validateVnrEmail(
                                        emailController.text.trim())) {
                                  await (Connectivity().checkConnectivity())
                                      .then((onValue) {
                                    if (onValue == ConnectivityResult.none) {
                                      Fluttertoast.showToast(
                                          msg: "No Active Internet Connection!",
                                          toastLength: Toast.LENGTH_SHORT,
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white);
                                    } else {
                                      if (this.phones.length != 0) {
                                        CourseCoordinatorsDetails
                                            coordinatorsDetails;
                                        if (this.defaultAdmins.contains(
                                            emailController.text.trim())) {
                                          this.courses[this.courseName] = true;
                                          coordinatorsDetails =
                                              new CourseCoordinatorsDetails(
                                                  emailController.text.trim(),
                                                  this.phones.toList(),
                                                  this.courses);
                                        } else {
                                          this.courses[this.courseName] = false;
                                          coordinatorsDetails =
                                              new CourseCoordinatorsDetails(
                                                  emailController.text.trim(),
                                                  this.phones.toList(),
                                                  this.courses);
                                        }
                                        print(coordinatorsDetails.toJson());
                                        postFirebase(coordinatorsDetails);
                                        Fluttertoast.showToast(
                                            msg: "User Added " +
                                                coordinatorsDetails.email,
                                            toastLength: Toast.LENGTH_SHORT,
                                            backgroundColor: Colors.green,
                                            textColor: Colors.white);
                                        emailController.clear();
                                        setState(() {
                                          this.contactWidget.clear();
                                          this.phones.clear();
                                        });
                                      } else {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Contact Details can't be Empty",
                                            toastLength: Toast.LENGTH_SHORT,
                                            backgroundColor: Colors.deepOrange,
                                            textColor: Colors.white);
                                      }
                                    }
                                  });
                                } else {
                                  Fluttertoast.showToast(
                                      msg:
                                          "Enter Valid Mail\nGoogle or VNRVJIET Domain",
                                      toastLength: Toast.LENGTH_LONG,
                                      backgroundColor: Colors.orange,
                                      textColor: Colors.white);
                                  //emailController.clear();
                                }
                              },
                              color: Colors.green,
                              iconSize: 30,
                            ),
                          )
                        ],
                      )),
                  this.contactWidget.length != 0
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: this.contactWidget,
                          ),
                        )
                      : Padding(padding: EdgeInsets.all(0)),
                ],
              ),
            )));
  }

  bool validateGoogleEmail(String value) {
    int i = 0;
    bool flag = true;
    String check = "gmail.com";
    for (i = 0; i < value.length; i++) {
      if (value[i] == '@') {
        break;
      }
    }
    if (value.length - (i + 1) == check.length) {
      for (int c = i + 1, d = 0;
          c < value.length && d < check.length;
          c++, d++) {
        if (value[c] != check[d]) {
          flag = false;
          break;
        }
      }
      return flag;
    } else {
      return false;
    }
  }

  bool validateVnrEmail(String value) {
    int i = 0;
    bool flag = true;
    String check = "vnrvjiet.in";
    for (i = 0; i < value.length; i++) {
      if (value[i] == '@') {
        break;
      }
    }
    if (value.length - (i + 1) == check.length) {
      for (int c = i + 1, d = 0;
          c < value.length && d < check.length;
          c++, d++) {
        if (value[c] != check[d]) {
          flag = false;
          break;
        }
      }
      return flag;
    } else {
      return false;
    }
  }

  showAlertDialog(
      BuildContext context, CourseCoordinatorsDetails coordinatorsDetails) {
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
      onPressed: () {
        delFirebase(coordinatorsDetails);
        Fluttertoast.showToast(
            msg: "User Removed " + coordinatorsDetails.email,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white);
        Navigator.of(context).pop(); // dismiss dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete Admin"),
      content: Text(coordinatorsDetails.email),
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
}
