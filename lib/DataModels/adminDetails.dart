import 'package:firebase_database/firebase_database.dart';

class AdminDetails {
  String email;
  List phone;
  bool permission;

  AdminDetails(this.email, this.permission, this.phone);

  AdminDetails.fromSnapshot(DataSnapshot snapshot)
      : email = snapshot.value["email"],
        permission = snapshot.value["permission"],
        phone = snapshot.value["phone"];

  toJson() {
    return {"email": email, "permission": permission, "phone": phone};
  }
}
