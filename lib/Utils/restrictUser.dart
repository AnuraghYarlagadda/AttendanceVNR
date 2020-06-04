import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class NoAccess extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoAccessState();
  }
}

class NoAccessState extends State<NoAccess> {
  bool anuragh = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 6000), () {
      setState(() {
        this.anuragh = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: anuragh
            ? Text("You've no access to view the content!",
                style: GoogleFonts.anton(
                  textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 19,
                      color: Colors.red),
                ))
            : SpinKitFadingCube(color: Colors.cyan),
      ),
    );
  }
}
