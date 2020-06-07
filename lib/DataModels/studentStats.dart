import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class StudentStats {
  String rollNum, name, year, courseName;
  int present, absent;
  StudentStats(this.rollNum, this.name, this.year, this.courseName,
      this.present, this.absent);

  StudentStats.fromSnapshot(DataSnapshot snapshot)
      : rollNum = snapshot.value["rollNum"],
        name = snapshot.value["name"],
        year = snapshot.value["year"],
        courseName = snapshot.value["courseName"],
        present = snapshot.value["present"],
        absent = snapshot.value["absent"];
  StudentStats.fromJson(LinkedHashMap<dynamic, dynamic> data)
      : rollNum = data["rollNum"],
        name = data["name"],
        year = data["year"],
        courseName = data["courseName"],
        present = data["present"],
        absent = data["absent"];

  toJson() {
    return {
      "rollNum": rollNum,
      "name": name,
      "year": year,
      "courseName": courseName,
      "present": present,
      "absent": absent
    };
  }
}
