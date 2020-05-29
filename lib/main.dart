import 'package:attendance/contacts.dart';
import 'package:attendance/home.dart';
import 'package:attendance/manageAdmins.dart';
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
          },
        ));
  }
}
