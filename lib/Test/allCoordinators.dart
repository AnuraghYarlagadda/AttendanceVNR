import 'package:attendance/DataModels/courseCoordinatorsDetails.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AllCoordinators extends StatefulWidget {
  AllCoordinatorsState createState() => AllCoordinatorsState();
}

class AllCoordinatorsState extends State<AllCoordinators> {
  final fb = FirebaseDatabase.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: RaisedButton(onPressed: () async {
        String courseName = "machine learning";
        final ref = fb.reference();
        List keys = [];
        await ref.child("CourseCoordinators").once().then((data) {
          keys.addAll(data.value.keys);
        });
        keys.forEach((f) async {
          await ref.child("CourseCoordinators").child(f).once().then((data) {
            CourseCoordinatorsDetails coordinatorsDetails =
                CourseCoordinatorsDetails.fromSnapshot(data);
            print(coordinatorsDetails.courses);
            coordinatorsDetails.courses.removeWhere((a, b) => a == courseName);
            print(coordinatorsDetails.courses);
            if (coordinatorsDetails.courses.length == 0) {
              //del user n firebase
            } else {
              //post update in firebase

            }
          });
        });
      }),
    );
  }
}
