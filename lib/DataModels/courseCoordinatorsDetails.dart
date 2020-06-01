import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';

class CourseCoordinatorsDetails {
  String email;
  List phone;
  LinkedHashMap courses;
  CourseCoordinatorsDetails(this.email, this.phone, this.courses);

  CourseCoordinatorsDetails.fromSnapshot(DataSnapshot snapshot)
      : email = snapshot.value["email"],
        phone = snapshot.value["phone"],
        courses = snapshot.value["courses"];

  toJson() {
    return {"email": email, "phone": phone, "courses": courses};
  }
}
