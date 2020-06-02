import 'package:firebase_database/firebase_database.dart';

class StudentAttendanceDetails {
  String rollNum, name;
  bool present;
  StudentAttendanceDetails(this.rollNum, this.name, this.present);

  StudentAttendanceDetails.fromSnapshot(DataSnapshot snapshot)
      : rollNum = snapshot.value["rollNum"],
        name = snapshot.value["name"],
        present = snapshot.value["present"];

  toJson() {
    return {"rollNum": rollNum, "name": name, "present": present};
  }
}
