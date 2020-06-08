import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class BackupAttendance {
  String courseName, year;
  LinkedHashMap dates;
  BackupAttendance(this.courseName, this.year, this.dates);
  BackupAttendance.fromSnapshot(DataSnapshot snapshot)
      : courseName = snapshot.value["courseName"],
        year = snapshot.value["year"],
        dates = snapshot.value["dates"];

  toJson() {
    return {
      "courseName": courseName,
      "year": year,
      "dates": dates,
    };
  }

  BackupAttendance.fromJson(LinkedHashMap<dynamic, dynamic> data)
      : courseName = data["courseName"],
        year = data["year"],
        dates = data["dates"];
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

  TimeAttendance.fromJson(LinkedHashMap<dynamic, dynamic> data)
      : times = data["times"];
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

  PresentAbsent.fromJson(LinkedHashMap<dynamic, dynamic> data)
      : presentees = data["presentees"],
        absentees = data["absentees"];
}
