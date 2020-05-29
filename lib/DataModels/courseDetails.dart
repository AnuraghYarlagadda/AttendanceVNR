import 'dart:collection';

import 'package:attendance/DataModels/adminDetails.dart';
import 'package:firebase_database/firebase_database.dart';

class CourseDetails {
  String courseName, facultyName, venue;
  int phoneFaculty, year;
  LinkedHashSet<AdminDetails> courseAdmins;

  CourseDetails(
    this.courseName,
    this.facultyName,
  );

  CourseDetails.fromSnapshot(DataSnapshot snapshot)
      : courseName = snapshot.value["courseName"],
        facultyName = snapshot.value["facultyName"],
        venue = snapshot.value["venue"],
        phoneFaculty = snapshot.value["phoneFaculty"],
        year = snapshot.value["year"],
        courseAdmins = snapshot.value["courseAdmins"];

  toJson() {
    return {
      "courseName": courseName,
      "facultyName": facultyName,
      "venue": venue,
      "phoneFaculty": phoneFaculty,
      "year": year,
      "courseAdmins": courseAdmins
    };
  }
}
