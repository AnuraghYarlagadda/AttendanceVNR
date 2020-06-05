import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class BackupAttendance {
  String courseName, year;
  List students;
  LinkedHashMap dates;
  BackupAttendance(this.courseName, this.year, this.students, this.dates);
  BackupAttendance.fromSnapshot(DataSnapshot snapshot)
      : courseName = snapshot.value["courseName"],
        year = snapshot.value["year"],
        students = snapshot.value["students"],
        dates = snapshot.value["dates"];

  toJson() {
    return {
      "courseName": courseName,
      "year": year,
      "students": students,
      "dates": dates,
    };
  }
}

class TimeAttendance {
  LinkedHashMap times;
  TimeAttendance(this.times);
  TimeAttendance.fromSnapshot(DataSnapshot snapshot)
      : times = snapshot.value["times"];

  toJson() {
    return {
      "times": times,
    };
  }
}

class PresentAbsent {
  List presentees, absentees;
  PresentAbsent(this.presentees, this.absentees);
  PresentAbsent.fromSnapshot(DataSnapshot snapshot)
      : presentees = snapshot.value["presentees"],
        absentees = snapshot.value["absentees"];

  toJson() {
    return {"presentees": presentees, "absentees": absentees};
  }
}
