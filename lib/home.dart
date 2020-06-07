import 'package:attendance/Utils/Settings.dart';
import 'package:attendance/Utils/StoragePermissions.dart';
import 'package:attendance/Utils/login.dart';
import 'package:attendance/Utils/restrictUser.dart';
import 'package:attendance/Utils/signin.dart';
import 'package:attendance/dashboard.dart';
import 'package:attendance/team.dart';
import 'package:connectivity/connectivity.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _currentIndex = 0;

  bool userLoggedIn;
  FirebaseUser user;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  String userEmail, userName;
  var currentAdmins;
  var defaultAdmins;
  final fb = FirebaseDatabase.instance;
  AdminDetails adminDetails;
  List<Widget> _children = [Home(), DashBoard(""), Team()];
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
        this._children[1] = DashBoard(this.userEmail);
        this.userName = onValue.displayName;
        Fluttertoast.showToast(
            msg: "Welcome " + this.userName,
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.cyan,
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
      appBar: this._currentIndex == 0
          ? AppBar(
              title: Text("Home",
                  style: GoogleFonts.acme(
                    textStyle: TextStyle(),
                  )),
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
                          child: ListTile(
                            leading: Icon(Icons.exit_to_app),
                            title: Text(choice,
                                style: GoogleFonts.slabo27px(
                                  textStyle: TextStyle(fontSize: 15),
                                )),
                          ));
                    }).toList();
                  },
                ),
              ],
            )
          : this._currentIndex == 1
              ? AppBar(
                  title: Text("DashBoard",
                      style: GoogleFonts.acme(
                        textStyle: TextStyle(),
                      )),
                  leading: Icon(Icons.dashboard),
                )
              : AppBar(
                  title: Text("Team",
                      style: GoogleFonts.acme(
                        textStyle: TextStyle(),
                      )),
                  leading: Icon(Icons.group)),
      body: this._currentIndex == 0
          ? this.userLoggedIn == null
              ? Center(
                  child: SpinKitFadingCube(color: Colors.cyan),
                )
              : this.userLoggedIn == false
                  ? Login()
                  : this.user == null
                      ? Center(
                          child: SpinKitFadingCube(color: Colors.cyan),
                        )
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
                                                title: Text("Manage Admins",
                                                    style: GoogleFonts.nunito(
                                                        textStyle: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle: FontStyle
                                                                .normal))),
                                                trailing: IconButton(
                                                    icon: Icon(
                                                      Icons.settings,
                                                      size: 25,
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
                                              style: GoogleFonts.nunito(
                                                  textStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FontStyle.normal)),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.add),
                                              iconSize: 25,
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
                                                        textColor:
                                                            Colors.white);
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
                                                              "addCourse");
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
                                              style: GoogleFonts.nunito(
                                                  textStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FontStyle.normal)),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.remove_red_eye),
                                              iconSize: 25,
                                              color: Colors.blue,
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
                                                        textColor:
                                                            Colors.white);
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
                                        ListTile(
                                            title: Text(
                                              "Year Report Present Attendance",
                                              style: GoogleFonts.nunito(
                                                  textStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FontStyle.normal)),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.person_outline),
                                              iconSize: 25,
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
                                                        textColor:
                                                            Colors.white);
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
                                                              "yearAttendance",
                                                              arguments: {
                                                            "what": "present"
                                                          });
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
                                              "Year Report Absent Attendance",
                                              style: GoogleFonts.nunito(
                                                  textStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FontStyle.normal)),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.person_outline),
                                              iconSize: 25,
                                              color: Colors.red,
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
                                                        textColor:
                                                            Colors.white);
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
                                                              "yearAttendance",
                                                              arguments: {
                                                            "what": "absent"
                                                          });
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
                          : NoAccess()
          : this._children[this._currentIndex],
      bottomNavigationBar: (this.userLoggedIn != false &&
              this
                      .currentAdmins
                      .where((item) => item.email == this.userEmail)
                      .length >
                  0)
          ? FancyBottomNavigation(
              onTabChangedListener: (position) {
                setState(() {
                  this._currentIndex = position;
                });
              },
              tabs: [
                TabData(iconData: Icons.home, title: "Home"),
                TabData(iconData: Icons.dashboard, title: "Dashboard"),
                TabData(iconData: Icons.group, title: "Team")
              ],
              inactiveIconColor: Colors.blueGrey,
              textColor: Colors.blueGrey,
            )
          : Padding(padding: EdgeInsets.all(0)),
    );
  }
}
