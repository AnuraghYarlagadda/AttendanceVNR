import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:attendance/navigateToPlayStore.dart';
import './Settings.dart';

Future<void> openFile(
    BuildContext context, String filePath, String fileFormat) async {
  final result = await OpenFile.open(filePath);
  if (result.type == ResultType.fileNotFound) {
    Fluttertoast.showToast(
        msg: "File Not Found! \nRetry Downloading..",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }
  if (result.type == ResultType.noAppToOpen) {
    Fluttertoast.showToast(
        msg: "No APP found to open this File!",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white);
    if (fileFormat == "xlsx")
      goToExcelViewerFromPlayStore();
    else if (fileFormat == "pdf") goToPDFViewerFromPlayStore();
  }
  if (result.type == ResultType.permissionDenied) {
    Fluttertoast.showToast(
        msg: "Grant Storage Permission",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM);
    openAppSettingsVNR();
  }
  print(result.message);
  print(result.type);
}
