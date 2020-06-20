import 'dart:developer';

import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/PostScreenPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/HeaderPage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}



class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Notifications"),
      body: Container(
        child: FutureBuilder(
          future: retrieveNotifications(),
          builder: (context, dataSnapshot){
            if(!dataSnapshot.hasData){
              return circularProgress();
            }
            return ListView(children: dataSnapshot.data);
          },
        ),
      ),
    );
  }

  retrieveNotifications() async{
    QuerySnapshot querySnapshot = await activityFeedReference.document(currentUser.id)
        .collection("feedItems").orderBy("timestamp", descending: true)
        .limit(60).getDocuments();

    List<NotificationsItem> notificationsItem = [];

    querySnapshot.documents.forEach((document) {
      notificationsItem.add(NotificationsItem.fromDocument(document));
    });
    return notificationsItem;
  }
}

String notificationItemText;
Widget mediaPreview;

class NotificationsItem extends StatelessWidget {
  final String profileName;
  final String type;
  final String commentData;
  final String postId;
  final String userId;
  final String userProfileImg;
  final String url;
  final Timestamp timestamp;

  NotificationsItem({
    this.profileName,
    this.type,
    this.commentData,
    this.postId,
    this.userId,
    this.userProfileImg,
    this.url,
    this.timestamp
  });

  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot){
    return NotificationsItem(
      profileName: documentSnapshot["profileName"],
      type: documentSnapshot["type"],
      commentData: documentSnapshot["commentData"],
      url: documentSnapshot["url"],
      postId: documentSnapshot["postId"],
      userId: documentSnapshot["userId"],
      userProfileImg: documentSnapshot["userProfileImg"],
      timestamp: documentSnapshot["timestamp"],
    );
  }
  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=> displayUserProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0, color: Colors.black),
                children: [
                  TextSpan(text: profileName, style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "$notificationItemText")
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(tAgo.format(timestamp.toDate()), overflow: TextOverflow.ellipsis,),
          trailing: mediaPreview,
        ),
      ),
    );
  }

  configureMediaPreview(context){
    if(type == "comment" || type == "like"){
      mediaPreview = GestureDetector(
        onTap: ()=> displayFullPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(fit: BoxFit.cover, image: CachedNetworkImageProvider(url))
              ),
            ),
          ),
        ),
      );
    }
    else{
      mediaPreview = Text("");
    }
    if(type == "like"){
      notificationItemText = " liked your post";
    }
    else if(type == "comment"){
      notificationItemText = " replied $commentData";
    }
    else  if(type == "follow"){
      notificationItemText = " started following you";
    }
    else{
      notificationItemText = "Error, unknown type = $type";
    }
  }
  displayFullPost(BuildContext context){
    Navigator.push(context, MaterialPageRoute(builder: (context)=> PostScreenPage(userId: currentUser.id, postId: postId)));
  }

  displayUserProfile(BuildContext context, {String profileId}) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfilePage(userProfileId: profileId)));
  }
}
