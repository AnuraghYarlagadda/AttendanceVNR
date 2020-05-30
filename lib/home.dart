import 'package:attendance/Settings.dart';
import 'package:attendance/StoragePermissions.dart';
import 'package:attendance/addCourse.dart';
import 'package:attendance/login.dart';
import 'package:attendance/restrictUser.dart';
import 'package:attendance/signin.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'DataModels/adminDetails.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

enum Status { start, running, completed }

class HomeState extends State<Home> {
  bool userLoggedIn;
  FirebaseUser user;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  String userEmail, userName;
  var currentAdmins;
  var defaultAdmins;
  final fb = FirebaseDatabase.instance;
  AdminDetails adminDetails;

  @override
  void initState() {
    super.initState();
    this.user = null;
    this.userLoggedIn = null;
    this.currentAdmins = <AdminDetails>{};
    this.defaultAdmins = <dynamic>{
      "anuraghyarlagadda@gmail.com",
      "ramakrishna_p@vnrvjiet.in",
      "bharathkumarchowdary@gmail.com"
    };
    checkUserStatus();
    getCurrentAdmins();
    getPermissions(context);
  }

  checkUserStatus() async {
    await googleSignIn.isSignedIn().then((onValue) {
      setState(() {
        this.userLoggedIn = onValue;
      });
    });
    if (this.userLoggedIn == true) {
      getUserDetails();
    }
  }

  getCurrentAdmins() {
    final ref = fb.reference().child("Admins");
    ref.onChildAdded.listen((onData) {
      adminDetails = AdminDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this.currentAdmins.add(adminDetails);
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.currentAdmins.length);
    });
    ref.onChildRemoved.listen((onData) {
      adminDetails = AdminDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this
              .currentAdmins
              .removeWhere((value) => value.email == adminDetails.email);
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.currentAdmins.length);
    });
    ref.onChildChanged.listen((onData) {
      adminDetails = AdminDetails.fromSnapshot(onData.snapshot);
      setState(() {
        try {
          this.currentAdmins.forEach((value) {
            if (adminDetails.email == value.email) {
              value.permission = adminDetails.permission;
            }
          });
        } catch (identifier) {
          print(identifier);
        }
      });
      print(this.currentAdmins.length);
    });
  }

  getUserDetails() async {
    await FirebaseAuth.instance.currentUser().then((onValue) {
      setState(() {
        this.user = onValue;
        this.userEmail = onValue.email;
        this.userName = onValue.displayName;
        Fluttertoast.showToast(
            msg: "Welcome " + this.userName,
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.blue,
            textColor: Colors.white);
      });
    });
  }

  void handleClick(String value) async {
    await signOutGoogle().then((onValue) {
      Navigator.of(context).pushReplacementNamed("home");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          leading: Icon(Icons.home),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: handleClick,
              itemBuilder: (BuildContext context) {
                return ['Sign-Out'].map((String choice) {
                  return PopupMenuItem<String>(
                    enabled: this.userLoggedIn,
                    height: MediaQuery.of(context).size.height / 18,
                    value: choice,
                    child: Text(
                      choice,
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: this.userLoggedIn == null
            ? Center(child: CircularProgressIndicator())
            : this.userLoggedIn == false
                ? Login()
                : this.user == null
                    ? Center(child: CircularProgressIndicator())
                    : this
                                .currentAdmins
                                .where((item) => item.email == this.userEmail)
                                .length >
                            0
                        ? SingleChildScrollView(
                            child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      this
                                              .defaultAdmins
                                              .contains(this.userEmail)
                                          ? ListTile(
                                              //isThreeLine: true,
                                              title: Text(
                                                "Manage Admins",
                                                style: TextStyle(
                                                    fontSize: 25,
                                                    color: Colors.indigo,
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FontStyle.normal),
                                              ),
                                              trailing: IconButton(
                                                  icon: Icon(
                                                    Icons.settings,
                                                    size: 35,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                            "manageAdmins");
                                                  }))
                                          : Padding(
                                              padding: EdgeInsets.all(0),
                                            ),
                                      this
                                              .defaultAdmins
                                              .contains(this.userEmail)
                                          ? new Divider(
                                              height: 2.0,
                                              thickness: 2.5,
                                            )
                                          : Padding(
                                              padding: EdgeInsets.all(0),
                                            ),
                                      ListTile(
                                          title: Text(
                                            "Add Course",
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.normal),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.add),
                                            iconSize: 35,
                                            color: Colors.green,
                                            onPressed: () async {
                                              await (Connectivity()
                                                      .checkConnectivity())
                                                  .then((onValue) {
                                                if (onValue ==
                                                    ConnectivityResult.none) {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          "No Active Internet Connection!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      backgroundColor:
                                                          Colors.red,
                                                      textColor: Colors.white);
                                                  openWIFISettingsVNR();
                                                } else {
                                                  if (this
                                                          .currentAdmins
                                                          .where((item) => (item
                                                                      .email ==
                                                                  this.userEmail &&
                                                              item.permission))
                                                          .length >
                                                      0) {
                                                    Navigator.of(context)
                                                        .pushNamed("addCourse");
                                                  } else {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Permission Denied ",
                                                        toastLength:
                                                            Toast.LENGTH_LONG,
                                                        backgroundColor:
                                                            Colors.red,
                                                        textColor:
                                                            Colors.white);
                                                  }
                                                }
                                              });
                                            },
                                          )),
                                      new Divider(
                                        height: 2.0,
                                        thickness: 2.5,
                                      ),
                                      ListTile(
                                          title: Text(
                                            "Courses",
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.normal),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.remove_red_eye),
                                            iconSize: 35,
                                            color: Colors.orange,
                                            onPressed: () async {
                                              await (Connectivity()
                                                      .checkConnectivity())
                                                  .then((onValue) {
                                                if (onValue ==
                                                    ConnectivityResult.none) {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          "No Active Internet Connection!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      backgroundColor:
                                                          Colors.red,
                                                      textColor: Colors.white);
                                                  openWIFISettingsVNR();
                                                } else {
                                                  if (this
                                                          .currentAdmins
                                                          .where((item) => (item
                                                                      .email ==
                                                                  this.userEmail &&
                                                              item.permission))
                                                          .length >
                                                      0) {
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                            "listOfCourses");
                                                  } else {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Permission Denied ",
                                                        toastLength:
                                                            Toast.LENGTH_LONG,
                                                        backgroundColor:
                                                            Colors.red,
                                                        textColor:
                                                            Colors.white);
                                                  }
                                                }
                                              });
                                            },
                                          )),
                                      new Divider(
                                        height: 2.0,
                                        thickness: 2.5,
                                      ),
                                    ])))
                        : NoAccess());
  }
}
