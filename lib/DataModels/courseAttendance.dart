import 'package:firebase_database/firebase_database.dart';

class CourseAttendance {
  String courseName, year;
  List students, presentees, absentees;
  CourseAttendance(this.courseName, this.year, this.students, this.presentees,
      this.absentees);
  CourseAttendance.fromSnapshot(DataSnapshot snapshot)
      : courseName = snapshot.value["courseName"],
        year = snapshot.value["year"],
        students = snapshot.value["students"],
        presentees = snapshot.value["presentees"],
        absentees = snapshot.value["absentees"];

  toJson() {
    return {
      "courseName": courseName,
      "year": year,
      "students": students,
      "presentees": presentees,
      "absentees": absentees
    };
  }
}
