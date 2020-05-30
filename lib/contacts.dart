import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

class ContactsPage extends StatefulWidget {
  final LinkedHashMap args;
  const ContactsPage(this.args);
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  Iterable<Contact> _contacts;
  LinkedHashSet items;
  String numbers;
  TextEditingController editingController = TextEditingController();
  @override
  void initState() {
    getContacts();
    print(widget.args);
    super.initState();
  }

  Future<void> getContacts() async {
    //Make sure we already have permissions for contacts when we get to this
    //page, so we can just retrieve it
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      _contacts = contacts;
      this.items = new LinkedHashSet<Contact>();
      this.items.addAll(_contacts.toList());
      print(this.items.length);
    });
  }

  void filterSearchResults(String query) {
    List dummySearchList = List<Contact>();
    dummySearchList.addAll(this._contacts);
    if (query.isNotEmpty) {
      List dummyListData = List<Contact>();
      dummySearchList.forEach((item) {
        if (item.displayName.toString().toLowerCase().contains(query)) {
          dummyListData.add(item);
        }
        item.phones.forEach((f) {
          if (f.value.toString().toLowerCase().contains(query)) {
            dummyListData.add(item);
          }
        });
      });
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(this._contacts);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: TextField(
                controller: editingController,
                cursorColor: Colors.white,
                cursorWidth: 2.5,
                style: new TextStyle(
                  color: Colors.white,
                ),
                onChanged: (value) {
                  filterSearchResults(value.toLowerCase().trim());
                },
                decoration: new InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "Search ",
                    hintStyle: new TextStyle(color: Colors.white)),
              ),
              actions: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      editingController.clear();
                      WidgetsBinding.instance.focusManager.primaryFocus
                          ?.unfocus();
                      filterSearchResults("");
                    })
              ],
            ),
            body: this.items == null
                ? Center(child: const CircularProgressIndicator())
                : this.items.length != 0
                    ? ListView.builder(
                        itemCount: this.items?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          Contact contact = this.items.elementAt(index);
                          this.numbers = "";
                          if (contact.phones != null) {
                            contact.phones.forEach((f) {
                              this.numbers = f.value.toString() + " ";
                            });
                          }
                          return GestureDetector(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 18),
                              leading: (contact.avatar != null &&
                                      contact.avatar.isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          MemoryImage(contact.avatar),
                                    )
                                  : CircleAvatar(
                                      child: Text(contact.initials()),
                                      backgroundColor:
                                          Theme.of(context).accentColor,
                                    ),
                              title: Text(contact.displayName ?? ''),
                              subtitle: Text(this.numbers),
                              //This can be further expanded to showing contacts detail
                              // onPressed().
                            ),
                            onTap: () {
                              if (widget.args["route"] == "addCourse") {
                                Navigator.of(context)
                                    .popUntil(ModalRoute.withName('addCourse'));
                                Navigator.of(context).pushReplacementNamed(
                                    "addCourse",
                                    arguments: {
                                      "contact": this.items?.elementAt(index),
                                      "courseName": widget.args["courseName"],
                                      "facultyName": widget.args["facultyName"],
                                      "venue": widget.args["venue"],
                                      "year": widget.args["year"],
                                    });
                              } else if (widget.args["route"] ==
                                  "manageAdmins") {
                                Navigator.of(context).popUntil(
                                    ModalRoute.withName('manageAdmins'));
                                Navigator.of(context).pushReplacementNamed(
                                    "manageAdmins",
                                    arguments: {
                                      "contact": this.items?.elementAt(index),
                                      "email": widget.args["email"],
                                    });
                              }
                            },
                          );
                        },
                      )
                    : Center(
                        child: Text("No such Company found..!"),
                      )));
  }

  Future<bool> _onBackPressed() {
    if (widget.args["route"] == "addCourse") {
      Navigator.of(context).popUntil(ModalRoute.withName('addCourse'));
      Navigator.of(context).pushReplacementNamed("addCourse", arguments: {
        "contact": null,
        "courseName": widget.args["courseName"],
        "facultyName": widget.args["facultyName"],
        "venue": widget.args["venue"],
        "year": widget.args["year"],
      });
    } else if (widget.args["route"] == "manageAdmins") {
      Navigator.of(context).popUntil(ModalRoute.withName('manageAdmins'));
      Navigator.of(context).pushReplacementNamed("manageAdmins", arguments: {
        "contact": null,
        "email": widget.args["email"],
      });
    }
  }
}
