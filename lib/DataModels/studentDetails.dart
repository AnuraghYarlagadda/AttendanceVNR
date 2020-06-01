import 'package:firebase_database/firebase_database.dart';

class StudentDetails {
  String rollNum, name;

  StudentDetails(this.rollNum, this.name);

  StudentDetails.fromSnapshot(DataSnapshot snapshot)
      : rollNum = snapshot.value["rollNum"],
        name = snapshot.value["name"];

  toJson() {
    return {"rollNum": rollNum, "name": name};
  }
}
