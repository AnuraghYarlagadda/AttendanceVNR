import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:attendance/Utils/Settings.dart';

Directory applicationStorageDirectory;

Future<Directory> createandgetDirectory(context, String dir) async {
  if (await Permission.storage.isPermanentlyDenied) {
    Fluttertoast.showToast(
        msg: "Enable Storage Permission in Settings!",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white);
    openAppSettingsVNR();
  } else {
    if (await (Directory(dir).exists())) {
      print("Directory Exists!");
      applicationStorageDirectory = Directory(dir);
    } else {
      new Directory(dir).create(recursive: true)
          // The created directory is returned as a Future.
          .then((Directory directory) {
        applicationStorageDirectory = directory;
        print("created directory" + applicationStorageDirectory.path);
      });
    }
  }
  return applicationStorageDirectory;
}
