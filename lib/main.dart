import 'package:attendance/Attendance/postAttendance.dart';
import 'package:attendance/Attendance/showAttendance.dart';
import 'package:attendance/Attendance/showYearAttendance.dart';
import 'package:attendance/Course/addCourse.dart';
import 'package:attendance/Course/listOfCourses.dart';
import 'package:attendance/Course/viewAndEditCourse.dart';
import 'package:attendance/DashBoard/coursesBackupList.dart';
import 'package:attendance/DashBoard/displayDates.dart';
import 'package:attendance/DashBoard/statistics.dart';
import 'package:attendance/DashBoard/studentReport.dart';
import 'package:attendance/ManageUsers/manageAdmins.dart';
import 'package:attendance/ManageUsers/manageCourseCoordinators.dart';
import 'package:attendance/contacts.dart';
import 'package:attendance/home.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

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
            "listOfCoursesBackup": (context) => DisplayCoursesListBackup(),
            "courseDetails": (context) =>
                ViewAndEditCourse(ModalRoute.of(context).settings.arguments),
            "manageCordinators": (context) =>
                ManageCordinators(ModalRoute.of(context).settings.arguments),
            "postAttendance": (context) =>
                PostAttendance(ModalRoute.of(context).settings.arguments),
            "showAttendance": (context) =>
                ShowAttendance(ModalRoute.of(context).settings.arguments),
            "yearAttendance": (context) =>
                YearAttendance(ModalRoute.of(context).settings.arguments),
            "displayDates": (context) =>
                DisplayDates(ModalRoute.of(context).settings.arguments),
            "studentReport": (context) => StudentReport(),
            "statistics": (context) =>
                Statistics(ModalRoute.of(context).settings.arguments)
          },
        ));
  }
}
