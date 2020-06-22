import 'package:buddiesgram/widgets/HeaderPage.dart';
import 'package:flutter/material.dart';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';

class TimeLinePage extends StatefulWidget {
  final User gCurrentUser;

  TimeLinePage({this.gCurrentUser});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  List<Post> posts;
  List<String> followingsList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  retrieveTimeline() async {
    QuerySnapshot querySnapshot = await timelineReference.document(widget.gCurrentUser.id).collection("timelinePosts").orderBy("timestamp", descending: true).getDocuments();

    List<Post> allPosts = querySnapshot.documents.map((document) => Post.fromDocument(document)).toList();

    setState(() {
      this.posts = allPosts;
    });
  }

  retrieveFollowings() async {
    QuerySnapshot querySnapShot = await followingReference.document(currentUser.id).collection("userFollowing").getDocuments();

    setState(() {
      followingsList = querySnapShot.documents.map((document) => document.documentID).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    retrieveTimeline();
    retrieveFollowings();
  }

  createUserTimeline(){
    if(posts == null){
      return circularProgress();
    }
    else{
      return ListView(children: posts);
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(child: createUserTimeline(), onRefresh: ()=> retrieveTimeline()),
    );
  }
}
