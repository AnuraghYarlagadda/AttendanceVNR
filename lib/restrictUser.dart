import 'package:flutter/material.dart';

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
    Future.delayed(const Duration(milliseconds: 3000), () {
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
            ? Text("You've no access to view the content!")
            : CircularProgressIndicator(),
      ),
    );
  }
}
