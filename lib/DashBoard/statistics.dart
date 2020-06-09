import 'dart:collection';
import 'package:attendance/DataModels/attendanceBackup.dart';
import 'package:attendance/DataModels/studentStats.dart';
import 'package:attendance/Utils/StoragePermissions.dart';
import 'package:attendance/Utils/openFileFromLocalStorage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/foundation.dart';

class Statistics extends StatefulWidget {
  final StudentStats studentStats;
  const Statistics(this.studentStats);
  @override
  _StatisticsState createState() => _StatisticsState();
}

enum Status { data, nodata }

class _StatisticsState extends State<Statistics> {
  StudentStats studentStats;
  final fb = FirebaseDatabase.instance;
  int status;
  LinkedHashMap dates;
  LinkedHashMap attendance;
  Map presentAbsentCount;
  BackupAttendance backupAttendance;
  List bars;
  List<charts.Series<ChartSeries, String>> series;
  List<Widget> swipingWidgets = [];
  double width, height;
  List chartTypes = ["Pie Chart", "Bar Graph"];
  String what;
  //PDF Utils
  String generatedPdfFilePath;
  List rows = [];
  var con;
  //FileUtils
  var targetPath;
  var targetFileName;
  @override
  void initState() {
    super.initState();
    this.studentStats = new StudentStats(
        widget.studentStats.rollNum,
        widget.studentStats.name,
        widget.studentStats.year,
        widget.studentStats.courseName,
        widget.studentStats.present,
        widget.studentStats.absent);
    grantStoragePermissionAndCreateDir(
        context,
        "/storage/emulated/0" +
            "/Attendance/" +
            "Students/" +
            this.studentStats.rollNum);
    this.targetPath = "/storage/emulated/0" +
        "/Attendance/" +
        "Students/" +
        this.studentStats.rollNum;
    this.targetFileName = this.studentStats.rollNum + "_Report";
    this.status = Status.nodata.index;
    this.what = chartTypes[0];
    this.dates = new LinkedHashMap<dynamic, TimeAttendance>();
    this.attendance = new LinkedHashMap<dynamic, bool>();
    this.presentAbsentCount = new Map<String, double>();
    this.bars = new List<ChartSeries>();
    this.presentAbsentCount["Present"] = 0.0;
    this.presentAbsentCount["Absent"] = 0.0;
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
        if (onValue.value.keys.contains(this.studentStats.courseName)) {
          setState(() {
            this.backupAttendance = BackupAttendance.fromJson(
                onValue.value[this.studentStats.courseName]);
            this.dates = this.backupAttendance.dates;
            this.dates.forEach((k, v) {
              this.dates[k] = TimeAttendance.fromJson(v);
            });
            DateFormat dateFormat = new DateFormat("dd-MM-yyyy");
            var sortedKeys = this.dates.keys.toList(growable: false)
              ..sort(
                  (a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
            this.dates = new LinkedHashMap.fromIterable(sortedKeys,
                key: (k) => k, value: (k) => this.dates[k]);

            this.dates.forEach((k, v) {
              TimeAttendance timeAttendance = v;
              var sortedKeys = timeAttendance.times.keys.toList(growable: false)
                ..sort((a, b) => a.compareTo(b));
              timeAttendance.times = new LinkedHashMap.fromIterable(sortedKeys,
                  key: (k) => k, value: (k) => timeAttendance.times[k]);
              PresentAbsent presentAbsent =
                  PresentAbsent.fromJson(timeAttendance.times[sortedKeys.last]);
              if (presentAbsent.presentees == null &&
                  presentAbsent.absentees != null) {
                //add false
                this.attendance[k] = false;
                this.bars.add(new ChartSeries(
                      date: k,
                      count: 1,
                      barColor: charts.ColorUtil.fromDartColor(Colors.red),
                    ));
              } else if (presentAbsent.absentees == null &&
                  presentAbsent.presentees != null) {
                //add true
                this.attendance[k] = true;
                this.bars.add(new ChartSeries(
                      date: k,
                      count: 1,
                      barColor: charts.ColorUtil.fromDartColor(Colors.cyan),
                    ));
              } else {
                List presentRolls = new List<String>();
                presentAbsent.presentees.forEach((f) {
                  presentRolls.add(f["rollNum"]);
                });
                if (presentRolls.contains(this.studentStats.rollNum)) {
                  //add true
                  this.attendance[k] = true;
                  this.bars.add(new ChartSeries(
                        date: k,
                        count: 1,
                        barColor: charts.ColorUtil.fromDartColor(Colors.cyan),
                      ));
                } else {
                  //add false
                  this.attendance[k] = false;
                  this.bars.add(new ChartSeries(
                        date: k,
                        count: 1,
                        barColor: charts.ColorUtil.fromDartColor(Colors.red),
                      ));
                }
              }
            });
            this.series = [
              charts.Series(
                  id: "Dates",
                  data: this.bars,
                  domainFn: (ChartSeries series, _) => series.date,
                  measureFn: (ChartSeries series, _) => series.count,
                  colorFn: (ChartSeries series, _) => series.barColor)
            ];
            var sortedAttKeys = this.attendance.keys.toList(growable: false)
              ..sort(
                  (a, b) => dateFormat.parse(a).compareTo(dateFormat.parse(b)));
            this.attendance = new LinkedHashMap.fromIterable(sortedAttKeys,
                key: (k) => k, value: (k) => this.attendance[k]);
            this.attendance.forEach((k, v) {
              if (v) {
                this.studentStats.present++;
              } else {
                this.studentStats.absent++;
              }
            });

            this.presentAbsentCount["Present"] =
                this.studentStats.present.toDouble();
            this.presentAbsentCount["Absent"] =
                this.studentStats.absent.toDouble();
            genList();
            this.status = Status.data.index;
          });
        } else {
          setState(() {
            this.status = Status.data.index;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    this.width = MediaQuery.of(context).size.width;
    this.height = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
          title: Text(
            this.studentStats.rollNum,
            style: GoogleFonts.acme(),
          ),
        ),
        body: this.status == Status.nodata.index
            ? Center(
                child: CircularProgressIndicator(),
              )
            : this.attendance.length == 0
                ? Center(
                    child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Text(
                      "No Data !",
                      style: GoogleFonts.architectsDaughter(
                          textStyle:
                              TextStyle(color: Colors.black, fontSize: 18)),
                    ),
                  ))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(10),
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text("Name: " + this.studentStats.name,
                                style: GoogleFonts.oswald(
                                    textStyle: TextStyle(
                                  fontSize: 20,
                                )))),
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                                "Roll No.: " + this.studentStats.rollNum,
                                style: GoogleFonts.raleway(
                                    textStyle: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)))),
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text("Year: " + this.studentStats.year,
                                style: GoogleFonts.raleway(
                                    textStyle: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)))),
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                                "Course Enrolled: " +
                                    this.studentStats.courseName.toUpperCase(),
                                style: GoogleFonts.raleway(
                                    textStyle: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)))),
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: ListTile(
                            title: Text(what,
                                style: GoogleFonts.raleway(
                                    textStyle: TextStyle(
                                        fontSize: 17,
                                        color: this.what == chartTypes[1]
                                            ? Colors.teal
                                            : Colors.deepPurple,
                                        fontWeight: FontWeight.w600))),
                            trailing: Switch(
                              value: this.what == chartTypes[0],
                              onChanged: (value) {
                                setState(() {
                                  this.what == chartTypes[0]
                                      ? this.what = chartTypes[1]
                                      : this.what = chartTypes[0];
                                });
                              },
                              activeTrackColor: Colors.deepPurple,
                              activeColor: Colors.white,
                              inactiveTrackColor: Colors.teal,
                            ),
                          ),
                        ),
                        this.what == chartTypes[1]
                            ? Padding(
                                padding: EdgeInsets.all(5),
                                child: Center(
                                    child: Container(
                                  height: ((this.dates.length) * 75).toDouble(),
                                  width: width - 10,
                                  child: Card(
                                    color: Colors.white,
                                    borderOnForeground: true,
                                    elevation: 15,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(25),
                                            topLeft: Radius.circular(25),
                                            bottomLeft: Radius.circular(25),
                                            topRight: Radius.circular(25)),
                                        side: BorderSide(
                                            width: 1.5,
                                            color: Colors.blueGrey)),
                                    child: charts.BarChart(
                                      series,
                                      animate: true,
                                      vertical: false,
                                    ),
                                  ),
                                )),
                              )
                            : Padding(
                                padding: EdgeInsets.all(10),
                                child: Card(
                                  color: Colors.white,
                                  borderOnForeground: true,
                                  elevation: 15,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(25),
                                          topLeft: Radius.circular(25),
                                          bottomLeft: Radius.circular(25),
                                          topRight: Radius.circular(25)),
                                      side: BorderSide(
                                          width: 1.5, color: Colors.blueGrey)),
                                  child: PieChart(
                                    dataMap: this.presentAbsentCount,
                                    animationDuration:
                                        Duration(milliseconds: 800),
                                    chartLegendSpacing: 30.0,
                                    chartRadius:
                                        MediaQuery.of(context).size.width / 1.4,
                                    showChartValuesInPercentage: true,
                                    showChartValues: true,
                                    showChartValuesOutside: false,
                                    chartValueBackgroundColor: Colors.white,
                                    colorList: [
                                      Colors.cyan,
                                      Colors.red,
                                    ],
                                    showLegends: true,
                                    legendPosition: LegendPosition.bottom,
                                    decimalPlaces: 1,
                                    showChartValueLabel: true,
                                    initialAngle: 0,
                                    chartValueStyle:
                                        defaultChartValueStyle.copyWith(
                                      color:
                                          Colors.blueGrey[900].withOpacity(0.9),
                                    ),
                                    chartType: ChartType.disc,
                                  ),
                                ),
                              ),
                        Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                RaisedButton(
                                    child: Text("Generate Report"),
                                    onPressed: () async {
                                      await generateExampleDocument();
                                    },
                                    color: Colors.teal,
                                    textColor: Colors.white),
                                RaisedButton(
                                    child: Text("Open Report"),
                                    onPressed: () {
                                      openFile(
                                          context,
                                          this.targetPath +
                                              "/" +
                                              this.targetFileName +
                                              ".pdf",
                                          "pdf");
                                    },
                                    color: Colors.deepOrange,
                                    textColor: Colors.white),
                              ],
                            ))
                      ],
                    ),
                  ));
  }

  genList() {
    int i = 1;
    this.attendance.forEach((k, v) {
      String status = v ? "Present" : "Absent";
      this.rows.add(
          "<tr><td style='text-align:center'>${i.toString()}</td><td style='text-align:center'>${k.toString()}</td><td style='text-align:center'>${status.trim()}</td></tr>");
      i++;
    });

    this.con = this.rows.join();
  }

  Future<void> generateExampleDocument() async {
    int totalDuration = this.studentStats.present + this.studentStats.absent;
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
        <h1 style='text-align:center;color:Crimson;font-size:30px;font-family:Almendra;'>${this.studentStats.name.toUpperCase()}</h1>
        <br />
       <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:Teal;font-size:20px;'>Student Name</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Student Roll No.</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Year</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Course Enrolled</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>Course Duration</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>No. of Days Present</th>
        <th style='text-align:center;color:Teal;font-size:20px;'>No. of Days Absent</th>
        </tr>
        </thead>
        <tbody>
          <tr>
          <td style='text-align:center'>${this.studentStats.name.toUpperCase()}</td>
          <td style='text-align:center'>${this.studentStats.rollNum}</td>
          <td style='text-align:center'>${this.studentStats.year}</td>
          <td style='text-align:center'>${this.studentStats.courseName.toUpperCase()}</td>
          <td style='text-align:center'>${totalDuration.toString()}</td>
          <td style='text-align:center'>${this.studentStats.present.toString()}</td>
          <td style='text-align:center'>${this.studentStats.absent.toString()}</td>
          </tr>
        </tbody>
        </table>
        <br><br>
        <br><br>
        <table style="width:100%">
        <thead>
        <tr>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>S. No.</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>Date</th>
        <th style='text-align:center;color:DarkBlue;font-size:20px;'>Status</th>
        </tr>
        </thead>
        <tbody>
          $con
        </tbody>
        </table>
      </body>
    </html>
    """;
    try {
      var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
          htmlContent, targetPath, targetFileName);
      generatedPdfFilePath = generatedPdfFile.path;
      if (generatedPdfFilePath.isNotEmpty) {
        Fluttertoast.showToast(
            msg: this.studentStats.rollNum + " Report Generated Successfully!",
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.blue,
            textColor: Colors.white);
      }
    } catch (identifier) {
      print(identifier);
    }
  }
}

class ChartSeries {
  final String date;
  final int count;
  final charts.Color barColor;

  ChartSeries(
      {@required this.date, @required this.count, @required this.barColor});
}
