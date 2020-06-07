import 'package:attendance/DataModels/adminDetails.dart';
import 'package:attendance/Utils/Settings.dart';
import 'package:attendance/Utils/restrictUser.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class DashBoard extends StatefulWidget {
  final String email;
  const DashBoard(this.email);
  DashBoardState createState() => DashBoardState();
}

enum Status { data, nodata }

class DashBoardState extends State<DashBoard> {
  final fb = FirebaseDatabase.instance;
  AdminDetails adminDetails;
  int status;
  bool permission;
  @override
  void initState() {
    super.initState();
    print(widget.email);
    getCurrentAdmins(widget.email);
    this.status = Status.nodata.index;
    this.permission = false;
  }

  getCurrentAdmins(String email) {
    String id = email.replaceAll('.', ',');
    id = id.replaceAll('@', ',');
    id = id.replaceAll('#', ',');
    id = id.replaceAll('[', ',');
    id = id.replaceAll(']', ',');
    final ref = fb.reference().child("Admins").child(id);
    ref.once().then((onValue) {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.data.index;
        });
      } else {
        setState(() {
          try {
            this.adminDetails = AdminDetails.fromSnapshot(onValue);
            this.status = Status.data.index;
            this.permission = this.adminDetails.permission;
          } catch (identifier) {
            print(identifier);
          }
        });
      }
      print(this.adminDetails);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: this.status == Status.nodata.index
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (this.status == Status.data.index && this.permission == false)
              ? NoAccess()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(10),
                  scrollDirection: Axis.vertical,
                  child: Column(children: <Widget>[
                    ListTile(
                        title: Text(
                          "Course Attendance Backup",
                          style: GoogleFonts.nunito(
                              textStyle: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal)),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.backup),
                          iconSize: 25,
                          color: Colors.green,
                          onPressed: () async {
                            await (Connectivity().checkConnectivity())
                                .then((onValue) {
                              if (onValue == ConnectivityResult.none) {
                                Fluttertoast.showToast(
                                    msg: "No Active Internet Connection!",
                                    toastLength: Toast.LENGTH_SHORT,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white);
                                openWIFISettingsVNR();
                              } else {
                                Navigator.of(context)
                                    .pushNamed("listOfCoursesBackup");
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
                          "Student Report",
                          style: GoogleFonts.nunito(
                              textStyle: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal)),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.grade),
                          iconSize: 25,
                          color: Colors.purple,
                          onPressed: () async {
                            await (Connectivity().checkConnectivity())
                                .then((onValue) {
                              if (onValue == ConnectivityResult.none) {
                                Fluttertoast.showToast(
                                    msg: "No Active Internet Connection!",
                                    toastLength: Toast.LENGTH_SHORT,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white);
                                openWIFISettingsVNR();
                              } else {
                                Navigator.of(context)
                                    .pushNamed("studentReport");
                              }
                            });
                          },
                        )),
                    new Divider(
                      height: 2.0,
                      thickness: 2.5,
                    ),
                  ]),
                ),
    );
  }
}
