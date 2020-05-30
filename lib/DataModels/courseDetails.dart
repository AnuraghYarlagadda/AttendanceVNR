import 'package:firebase_database/firebase_database.dart';

class CourseDetails {
  String courseName, trainerName, venue, year;
  List phone;
  bool lock;
  CourseDetails(this.courseName, this.trainerName, this.venue, this.year,
      this.phone, this.lock);
  CourseDetails.fromSnapshot(DataSnapshot snapshot)
      : courseName = snapshot.value["courseName"],
        trainerName = snapshot.value["trainerName"],
        venue = snapshot.value["venue"],
        year = snapshot.value["year"],
        phone = snapshot.value["phone"],
        lock = snapshot.value["lock"];

  toJson() {
    return {
      "courseName": courseName,
      "trainerName": trainerName,
      "venue": venue,
      "year": year,
      "phone": phone,
      "lock": lock
    };
  }
}
