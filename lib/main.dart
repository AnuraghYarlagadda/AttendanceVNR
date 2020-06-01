import 'package:attendance/addCourse.dart';
import 'package:attendance/contacts.dart';
import 'package:attendance/home.dart';
import 'package:attendance/manageAdmins.dart';
import 'package:attendance/manageCourseCoordinators.dart';
import 'package:attendance/viewAndEditCourse.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:attendance/listOfCourses.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: MaterialApp(
          title: "VNR CSE",
          home: Home(),
          debugShowCheckedModeBanner: false,
          routes: {
            "home": (context) => Home(),
            "manageAdmins": (context) =>
                ManageAdmin(ModalRoute.of(context).settings.arguments),
            "contacts": (context) =>
                ContactsPage(ModalRoute.of(context).settings.arguments),
            "addCourse": (context) =>
                AddCourse(ModalRoute.of(context).settings.arguments),
            "listOfCourses": (context) => DisplayCoursesList(),
            "courseDetails": (context) =>
                ViewAndEditCourse(ModalRoute.of(context).settings.arguments),
            "manageCordinators": (context) =>
                ManageCordinators(ModalRoute.of(context).settings.arguments),
          },
        ));
  }
}
