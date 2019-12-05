import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mad_histime/create.dart';

import 'record.dart';
import 'timetableDB.dart';
//import 'create.dart';

double _panelHeightClosed = 30.0;

class SearchPanel extends StatefulWidget {
  TimeTable tt;
  Function callback;

  SearchPanel({Key key, @required this.tt, @required this.callback}) : super(key: key);

  @override
  _SearchPanelState createState() => _SearchPanelState(tt: tt) ;
}

class _SearchPanelState extends State<SearchPanel> {
  TimeTable tt;
  bool is_favorite = false;
  String _searchFaculty = '';
  String _searchName = '';

  _SearchPanelState({Key key, @required this.tt, });

  TextEditingController searchController ;
  @override
  initState() {
    _facultyMenuItems = getFacultyItems();
    _currentFaculty = _facultyMenuItems[0].value;
    searchController = new TextEditingController();
    super.initState();
  }

  final db = Firestore.instance.collection('subjects');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: searchpanel(context),
    );
  }

  Widget searchpanel(BuildContext context) {

    Stream<QuerySnapshot> streamSelect () {
      if (is_favorite)
        return db.where('like', isEqualTo: true).snapshots();
      else if (_currentFaculty != '전체')
        return db.where('faculty', isEqualTo: _searchFaculty).snapshots();
//      else if (searchController.text.isNotEmpty)
//        return db.where('name', isEqualTo: _searchName).snapshots();
      else
        return db.snapshots();
    }
    return Column(
      children: <Widget>[
        _panelheader(), //위에 손잡이 부분
        is_favorite ? _favoritePart(context) : _searchPart(context), //검색창 있는 부분
        StreamBuilder<QuerySnapshot>(
            stream: streamSelect(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return LinearProgressIndicator();
              return _subjectList(context, snapshot.data.documents);
            }),
      ],
    );
  }

  Widget _panelheader() {
    return  Container(
      decoration: BoxDecoration(
        color: Color(0xFF225B95),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      width: 100,
      height: _panelHeightClosed,
      child: Center(
        child: Text(
          "Search",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _searchPart(BuildContext context) {
    return Container(
      color: Color(0xFF225B95),
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.favorite),
              color: Color(0xFFFFCA55),
              onPressed: () {
                setState(() {
                  is_favorite = true ;
                });
              },
            ),
            Expanded(
              child: CupertinoTextField(
                controller: searchController,
                placeholder: "과목명 혹은 교수님명",
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFFFCA55)),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.tune),
              onPressed: () {
                filterDialog(context);
              },
              color: Color(0xFFFFCA55),
              iconSize: 25,
            ),
            Container(
              padding: EdgeInsets.only(right: 5,),
              child: SizedBox(
                width: 60,
                child: RaisedButton(
                  child: Text('검색', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (searchController.text.isNotEmpty) _searchName = searchController.text;
                  },
                  color: Color(0xFFFFCA55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoritePart(BuildContext context) {
    return Container(
      color: Color(0xFF225B95),
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.storage),
              color: Color(0xFFFFCA55),
              onPressed: () {
                setState(() {
                  is_favorite = false ;
                });
              },
            ),
            Expanded(
              child: Container(),
            ),
            Container(
              padding: EdgeInsets.only(right: 5,),
              child: SizedBox(
                width: 100,
                child: RaisedButton(
                  child: Text('모두 추가', style: TextStyle(color: Colors.white)),
                  onPressed: () {},
                  color: Color(0xFFFFCA55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Expanded(
        child: ListView(
          children:
          snapshot.map((data) => _subjectListItem(data)).toList(),
        )
    );
  }

  Widget _subjectListItem(DocumentSnapshot data) {
    final record = Record.fromSnapshot(data) ;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF225B95), width: 2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Text('[${record.code}] ${record.name}',
                  style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(record.type),
                          Text(record.time),
                          Text('${record.credit}학점')
                        ],
                      ),
                    ),
                    Expanded(
                      child:  Column(
                        children: <Widget>[
                          Text(record.prof),
                          Text('영어 ${record.english}%')
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              record.like ? IconButton(
                icon: Icon(Icons.star),
                color: Color(0xFFFFCA55),
                onPressed: () async {
                  record.reference.updateData({'like' : false});
                },
              )
              : IconButton(
                icon: Icon(Icons.star_border),
                color: Color(0xFFFFCA55),
                onPressed: () async {
                  record.reference.updateData({'like' : true});
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  int day = 0;
                  int period = 0;
                  List<int> subjectsIdx = [];

                  List<String> times = record.time.split(',');
                  times.forEach((e) {
                    period = int.parse(e.substring(1));
                    switch (e[0]) {
                      case '월':
                        day = 6;
                        break;
                      case '화':
                        day = 5;
                        break;
                      case '수':
                        day = 4;
                        break;
                      case '목':
                        day = 3;
                        break;
                      case '금':
                        day = 2;
                        break;
                      case '토':
                        day = 1;
                        break;
                    }
                    subjectsIdx.add(7 * period - day);
                  });

                  if (canAdd(subjectsIdx))
                    addSubjects(subjectsIdx, record);
                  else ; // TODO "이미 과목이 찼다고 알려주기"

                  this.widget.callback(new CreatePage(tt: tt));
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  bool canAdd(List<int> subjectsIdx) {
    bool isOk = true;

    subjectsIdx.forEach((idx) {
      if (tt.subject[idx] != null)
        isOk = false;
    });

    return isOk;
  }

  addSubjects(List<int> subjectsIdx, Record subject) {
    super.setState(() {
      subjectsIdx.forEach((idx) => tt.subject[idx] = subject.code);
    });
  }

  List<DropdownMenuItem<String>> _facultyMenuItems;
  List<DropdownMenuItem<String>> _fieldMenuItems;
  List<DropdownMenuItem<String>> _typeMenuItems;
  List<DropdownMenuItem<int>> _englishMenuItems;
  String _currentFaculty;
  String _currentField;
  String _currentType;
  int _currentEng;

  List<DropdownMenuItem<String>> getFacultyItems() {
    List<DropdownMenuItem<String>> facultyItems = List();
    for (String _faculty in faculty) {
      facultyItems.add(new DropdownMenuItem(
          value: _faculty,
          child: Text(_faculty)
      ));
    }
    return facultyItems;
  }

  void changedFaculty(String selectedFaculty)  {
    setState(() {
      _currentFaculty = selectedFaculty;
    });
  }

  Future<void> filterDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF225B95), width: 3),
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            height: 450,
            padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('학 부',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton<String>(
                      value: _currentFaculty,
                      items: _facultyMenuItems,
                      onChanged: changedFaculty,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('이수구분', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButton(
                      value: _currentFaculty,
                      items: _facultyMenuItems,
                      onChanged: changedFaculty,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('교양영역',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton(
                      value: _currentFaculty,
                      items: _facultyMenuItems,
                      onChanged: changedFaculty,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('학 점',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton(
                      value: _currentFaculty,
                      items: _facultyMenuItems,
                      onChanged: changedFaculty,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('영어비율',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton(
                      value: _currentFaculty,
                      items: _facultyMenuItems,
                      onChanged: changedFaculty,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('시간대',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: RaisedButton(
                        child: Text('시간대 선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        color: Color(0xFF225B95),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: RaisedButton(
                    padding: EdgeInsets.fromLTRB(40, 5, 40, 5),
                    child: Text('검색하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    color: Color(0xFFFFCA55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onPressed: () {
                      _searchFaculty = _currentFaculty;
                      Navigator.pop(context) ;
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

