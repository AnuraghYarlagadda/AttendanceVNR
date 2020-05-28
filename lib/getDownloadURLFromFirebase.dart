import 'package:firebase_storage/firebase_storage.dart';

Future<String> firebaseurl(String child) async {
  StorageReference ref = FirebaseStorage.instance.ref();
  String url;
  try {
    url = await ref.child(child).getDownloadURL();
  } on Exception catch (e) {
    print("Oops! The file was not found" + e.toString());
  }
  return url;
}
