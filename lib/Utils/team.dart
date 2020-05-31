import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

class Team extends StatefulWidget {
  @override
  TeamState createState() => TeamState();
}

class TeamState extends State<Team> {
  static List<int> indices = [0, 1, 2, 3, 4, 5];
  static List<String> images = [
    "images/bvkmaam.jpeg",
    "images/rk.jpg",
    "images/bharath.jpg",
    "images/yamini.jpg",
    "images/harini.jpg",
    "images/anu.JPG",
  ];
  static List<String> names = [
    "Dr.B.V.Kiranmayee",
    "P.Ramakrishna",
    "P.Bharath Kumar",
    "B.V Yamini",
    "G Harini",
    "Anuragh Yarlagadda"
  ];
  static List<String> designation = [
    "HOD- Dept. of CSE",
    "Placement Cordinator",
    "Placement Cordinator",
    "III year CSE",
    "II year CSE",
    "III year CSE"
  ];
  final List<Widget> imageSliders = indices
      .map((item) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Image.asset(images[item]),
                Padding(padding: EdgeInsets.all(10)),
                Text(
                  names[item],
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
                Text(designation[item],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ))
              ]))
      .toList();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return (SizedBox(child: imageSliders[index]));
              },
              itemCount: images.length,

              viewportFraction: 0.8,
              scale: 0.8,
              //indicatorLayout: PageIndicatorLayout.COLOR,
              pagination: new SwiperPagination(
                  builder: new DotSwiperPaginationBuilder(
                      color: Colors.grey,
                      activeSize: 11,
                      size: 8,
                      activeColor: Colors.blue[900])),
              //control: new SwiperControl(color: Colors.white),
              scrollDirection: Axis.horizontal,
            )));
  }
}
