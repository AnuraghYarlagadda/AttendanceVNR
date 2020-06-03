import 'dart:collection';

import 'package:attendance/DataModels/courseAttendance.dart';
import 'package:attendance/DataModels/studentDetails.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_buttons/grouped_buttons.dart';

class YearAttendance extends StatefulWidget {
  final LinkedHashMap args;
  const YearAttendance(this.args);
  YearAttendanceState createState() => YearAttendanceState();
}

enum Status { loading, loaded }

class YearAttendanceState extends State<YearAttendance> {
  String what;
  final fb = FirebaseDatabase.instance;

  //PDF Utils
  String generatedPdfFilePath;
  List rows = [];
  var con;

  //final List and Hashset inside LinkedHashMap of years as keys
  LinkedHashMap display, displayList;
  var resultList;
  List<String> years = ["1", "2", "3", "4"];
  String year;
  int _status;

  @override
  void initState() {
    super.initState();
    print(widget.args);
    if (widget.args != null) {
      this.what = widget.args["what"];
    }
    this._status = Status.loading.index;
    this.display = new LinkedHashMap<dynamic, List>();
    this.displayList = new LinkedHashMap<dynamic, List>();
    this.resultList = new List<StudentDetails>();
    years.forEach((f) {
      this.display[f] = new List();
      this.displayList[f] = new List<StudentDetails>();
    });
    getData();
  }

  getData() async {
    final ref = fb.reference();
    List keys = [];
    await ref.child("CourseAttendance").once().then((onValue) {
      if (onValue.value != null) keys.addAll(onValue.value.keys);
    });
    for (String key in keys) {
      await ref.child("CourseAttendance").child(key).once().then((data) {
        CourseAttendance courseAttendance = CourseAttendance.fromSnapshot(data);
        if (this.what == "present") {
          if (courseAttendance.presentees != null) {
            setState(() {
              this
                  .display[courseAttendance.year]
                  .addAll(courseAttendance.presentees);
            });
          }
        } else {
          if (courseAttendance.absentees != null) {
            setState(() {
              this
                  .display[courseAttendance.year]
                  .addAll(courseAttendance.absentees);
            });
          }
        }
      });
    }
    years.forEach((f) {
      if (this.display[f].length != 0) {
        this.display[f].forEach((v) {
          setState(() {
            this
                .displayList[f]
                .add(new StudentDetails(v["rollNum"], v["name"]));
          });
        });
      }
    });
    years.forEach((f) {
      setState(() {
        this.displayList[f]
          ..sort((StudentDetails a, StudentDetails b) =>
              a.rollNum.toUpperCase().compareTo(b.rollNum.toUpperCase()));
      });
    });
    setState(() {
      this.resultList = this.displayList["1"];
      this.year = "1";
      this._status = Status.loaded.index;
      genList();
    });
  }

  void filterSearchResults(String year) {
    setState(() {
      this.resultList = this.displayList[year];
      genList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text("Year Report"),
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
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.fromLTRB(5, 20, 5, 15),
                          child: Card(
                            child: ListTile(
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
                                  labels: this.years,
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
                                          padding: EdgeInsets.all(10),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          )),
                      this.resultList.length == 0
                          ? Center(child: Text("😕 No Students found..!"))
                          : Scrollbar(
                              child: ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: this.resultList.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                        child: Card(
                                            elevation: 5,
                                            child: ListTile(
                                              leading: Text(
                                                (index + 1).toString(),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontStyle: FontStyle.normal,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              title: Text(
                                                this.resultList[index].rollNum,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                this.resultList[index].name,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )));
                                  })),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: RaisedButton(
                            child: Text("Generate Report"),
                            onPressed: () async {
                              await generateExampleDocument();
                            },
                            color: Colors.teal,
                            textColor: Colors.white),
                      )
                    ],
                  ),
                ),
        ));
  }

  genList() {
    int i = 1;
    this.rows.clear();
    for (var student in this.resultList) {
      this.rows.add(
          "<tr><td style='text-align:center'>${i.toString()}</td><td style='text-align:center'>${student.rollNum.toString()}</td><td style='text-align:center'>${student.name.toString()}</td></tr>");
      i++;
    }
    this.con = this.rows.join();
  }

  Future<void> generateExampleDocument() async {
    var htmlContent = """
    <!DOCTYPE html>
    <html>
      <head>
        <style>
        table, th, td {
          border: 1px solid black;
          border-collapse: collapse;
        }
        th, td, p {
          padding: 5px;
          text-align: left;
        }
        </style>
      </head>
      <body>
      <img src="https://img.techpowerup.org/200530/logo-new-1-converted-1.png" width="1100" height="300" alt="web-img">
        <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:Teal;font-size:20px;'>Year</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Attendance</th>
        </tr>
        </thead>
        <tbody>
          <tr>
          <td style='text-align:center'>${this.year}</td>
          <td style='text-align:center'>${this.what.toUpperCase()}</td>
          </tr>
        </tbody>
        </table>
        <br><br>
        <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>S. No.</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>H. T. No.</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>Name of the Student</th>
        </tr>
        </thead>
        <tbody>
          $con
        </tbody>
        </table>
      </body>
    </html>
    """;

    var targetPath = "/storage/emulated/0" + "/Attendance";
    var targetFileName = this.year + "_" + this.what;

    var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent, targetPath, targetFileName);
    generatedPdfFilePath = generatedPdfFile.path;
    if (generatedPdfFilePath.isNotEmpty) {
      Fluttertoast.showToast(
          msg: "Year " + this.year + " Report Generated Successfully!",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.blue,
          textColor: Colors.white);
    }
  }
}
