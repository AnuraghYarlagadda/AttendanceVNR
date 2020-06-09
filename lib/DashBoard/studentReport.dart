import 'dart:collection';

import 'package:attendance/DataModels/studentStats.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_buttons/grouped_buttons.dart';

class StudentReport extends StatefulWidget {
  @override
  _StudentReportState createState() => _StudentReportState();
}

enum Status { nodata, data }

class _StudentReportState extends State<StudentReport> {
  final fb = FirebaseDatabase.instance;
  int status;
  var students, display;
  List<String> years = ["1", "2", "3", "4"];
  String year;
  TextEditingController editingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    this.status = Status.nodata.index;
    this.students = new List<StudentStats>();
    this.display = new List<StudentStats>();
    this.year = "";
    getData();
  }

  @override
  void dispose() {
    super.dispose();
    editingController.clear();
    editingController.dispose();
  }

  getData() async {
    final ref = fb.reference();
    await ref.child("Students").once().then((onValue) {
      if (onValue.value == null) {
        setState(() {
          this.status = Status.data.index;
        });
      } else {
        var keys = onValue.value.keys;
        for (var key in keys) {
          setState(() {
            this.students.add(StudentStats.fromJson(onValue.value[key]));
          });
        }
        setState(() {
          this.display.addAll(this.students);
          this.display.sort((StudentStats a, StudentStats b) =>
              a.rollNum.compareTo(b.rollNum));
          this.status = Status.data.index;
        });
        print(onValue.value.keys.length);
        print(this.students.length);
        print(this.display.length);
      }
    });
  }

  void filterSearchResults(String filter) {
    if (["1", "2", "3", "4"].contains(this.year)) {
      setState(() {
        this.status = Status.nodata.index;
        this.display.clear();
      });
      LinkedHashSet dummySearchList = LinkedHashSet<StudentStats>();
      dummySearchList.addAll(this.students);
      LinkedHashSet dummyListData = LinkedHashSet<StudentStats>();
      dummySearchList.forEach((item) {
        if (item.year == year) {
          dummyListData.add(item);
        }
      });
      if (filter.isEmpty) {
        setState(() {
          this.display.clear();
          this.display.addAll(dummyListData.toList());
          this.display.sort((StudentStats a, StudentStats b) =>
              a.rollNum.compareTo(b.rollNum));
          this.status = Status.data.index;
        });
      } else {
        dummySearchList.clear();
        dummySearchList.addAll(dummyListData);
        dummyListData.clear();
        dummySearchList.forEach((v) {
          if (v.name.toString().toLowerCase().contains(filter) ||
              v.rollNum.toString().toLowerCase().contains(filter) ||
              v.courseName.toString().toLowerCase().contains(filter)) {
            dummyListData.add(v);
          }
        });
        setState(() {
          this.display.clear();
          this.display.addAll(dummyListData.toList());
          this.display.sort((StudentStats a, StudentStats b) =>
              a.rollNum.compareTo(b.rollNum));
          this.status = Status.data.index;
        });
      }
    } else {
      setState(() {
        this.status = Status.nodata.index;
        this.display.clear();
      });
      if (filter.isEmpty) {
        setState(() {
          this.display.clear();
          this.display.addAll(this.students);
          this.display.sort((StudentStats a, StudentStats b) =>
              a.rollNum.compareTo(b.rollNum));
          this.status = Status.data.index;
        });
      } else {
        LinkedHashSet dummySearchList = LinkedHashSet<StudentStats>();
        dummySearchList.addAll(this.students);
        LinkedHashSet dummyListData = LinkedHashSet<StudentStats>();
        dummySearchList.forEach((v) {
          if (v.name.toString().toLowerCase().contains(filter) ||
              v.rollNum.toString().toLowerCase().contains(filter) ||
              v.courseName.toString().toLowerCase().contains(filter)) {
            dummyListData.add(v);
          }
        });
        setState(() {
          this.display.clear();
          this.display.addAll(dummyListData.toList());
          this.display.sort((StudentStats a, StudentStats b) =>
              a.rollNum.compareTo(b.rollNum));
          this.status = Status.data.index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: TextField(
            controller: editingController,
            cursorColor: Colors.white,
            cursorWidth: 2.5,
            style: new TextStyle(
              color: Colors.white,
            ),
            onChanged: (value) {
              filterSearchResults(value.toLowerCase().trim());
            },
            decoration: new InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                // hintText: "Search ",
                // hintStyle: new TextStyle(color: Colors.white)
                labelStyle:
                    GoogleFonts.acme(textStyle: TextStyle(color: Colors.white)),
                labelText: "Student Report"),
          ),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  editingController.clear();
                  WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                  filterSearchResults("");
                })
          ],
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
          child: this.status == Status.nodata.index
              ? Center(
                  child: SpinKitThreeBounce(
                  size: 25,
                  color: Colors.cyan,
                ))
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
                              leading: IconButton(
                                icon: Icon(
                                  Icons.assistant_photo,
                                  size: 30,
                                  color: Colors.pink,
                                ),
                                onPressed: () {
                                  setState(() {
                                    this.year = "";
                                    editingController.clear();
                                  });
                                  filterSearchResults("");
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
                                    print("Year = " + this.year);
                                    editingController.clear();
                                    filterSearchResults("");
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
                                          padding: EdgeInsets.all(5),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          )),
                      this.display.length == 0
                          ? Center(
                              child: Text("😕 No Students found..!",
                                  style: GoogleFonts.robotoSlab(
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 18,
                                    ),
                                  )))
                          : Scrollbar(
                              child: ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: this.display.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: Text(
                                        (index + 1).toString() + ".",
                                        style: GoogleFonts.nanumGothic(
                                            textStyle: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      title: Text(this.display[index].rollNum,
                                          style: GoogleFonts.ptSansNarrow(
                                              textStyle: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.black,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      subtitle: Text(
                                        this.display[index].name,
                                        style: GoogleFonts.lora(
                                            textStyle: TextStyle(
                                                fontSize: 15,
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      trailing: IconButton(
                                          icon: Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.pink,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                "statistics",
                                                arguments: this.display[index]);
                                          }),
                                    );
                                  })),
                    ],
                  ),
                ),
        ));
  }
}
