import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:attendance/Settings.dart';
import './Storagedirectory.dart';
import 'package:flutter/material.dart';

grantStoragePermissionAndCreateDir(BuildContext context) {
  Permission.storage.request().then((onValue) {
    if (onValue == PermissionStatus.permanentlyDenied) {
      Fluttertoast.showToast(
          msg: "Enable Storage Permission in Settings!",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
          textColor: Colors.white);
      openAppSettingsVNR();
    } else if (onValue == PermissionStatus.denied)
      grantStoragePermissionAndCreateDir(context);
    else if (onValue == PermissionStatus.granted)
      createandgetDirectory(context);
  });
}
