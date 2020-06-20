import 'dart:async';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/CommentsPage.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/CImageWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final String postId, ownerId, profileName, username, description, location, url;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.description,
    this.location,
    this.url,
    this.likes,
    this.profileName
  });

  factory Post.fromDocument(DocumentSnapshot documentSnapshot){
    return Post(
      postId: documentSnapshot["postId"],
      ownerId: documentSnapshot["ownerId"],
      likes: documentSnapshot["likes"],
      profileName: documentSnapshot["profileName"],
      username: documentSnapshot["username"],
      description: documentSnapshot["description"],
      location: documentSnapshot["location"],
      url: documentSnapshot["url"],
    );
  }

  int getTotalNumberOfLikes(likes){
    if(likes == null){
      return 0;
    }

    int counter = 0;
    likes.values.forEach((eachValue){
      if(eachValue == true){
        counter++;
      }
    });
    return counter;
  }

  @override
  _PostState createState() => _PostState(
      postId: this.postId,
      ownerId: this.ownerId,
      profileName: this.profileName,
      username: this.username,
      description: this.description,
      location: this.location,
      url: this.url,
      likes: this.likes,
      likeCount: getTotalNumberOfLikes(this.likes)
  );
}

class _PostState extends State<Post> {

  final String postId, ownerId, profileName, username, description, location, url;
  Map likes;
  int likeCount;
  bool isLiked;
  bool showHeart = false;
  final String currentOnlineUserId = currentUser?.id;

  _PostState({
    this.postId,
    this.ownerId,
    this.profileName,
    this.username,
    this.description,
    this.location,
    this.url,
    this.likes,
    this.likeCount
  });

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentOnlineUserId] == true);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          createPostHead(),
          createPostPicture(),
          createPostFooter()
        ],
      ),
    );
  }

  createPostHead(){
    return FutureBuilder(
      future: usersReference.document(ownerId).get(),
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        bool isPostOwner = currentOnlineUserId == ownerId;

        return ListTile(
          leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.url), backgroundColor: Colors.grey),
          title: GestureDetector(
            onTap: ()=> displayUserProfile(context, profileId: user.id),
            child: Text(
              user.profileName,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(location, style: TextStyle(color: Colors.white)),
          trailing: isPostOwner? IconButton(icon: Icon(Icons.more_vert, color: Colors.white,),
              onPressed: ()=> print("deleted")
          ): Text(""),
        );
      },
    );
  }

  displayUserProfile(BuildContext context, {String profileId}) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfilePage(userProfileId: profileId)));
  }

  removeLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;

    if(isNotPostOwner){
      activityFeedReference.document(ownerId).collection("feedItems").document(postId).get().then((document){
        if(document.exists){
          document.reference.delete();
        }
      });
    }
  }

  addLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;

    if(isNotPostOwner){
      activityFeedReference.document(ownerId).collection("feedItems").document(postId).setData({
        "type": "like",
        "userId": currentUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "postId": postId,
        "profileName": currentUser.profileName,
        "userProfileImg": currentUser.url
      });
    }
  }

  controlUserPostLike(){
    bool _liked = likes[currentOnlineUserId] == true;

    if(_liked){
      postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"likes.$currentOnlineUserId": false});
      removeLike();

      setState(() {
        likeCount--;
        isLiked = false;
        likes[currentOnlineUserId] = false;
      });
    }
    else if(!_liked){
      postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"likes.$currentOnlineUserId": true});
      addLike();

      setState(() {
        likeCount++;
        isLiked = true;
        likes[currentOnlineUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 800), (){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  createPostPicture(){
    return GestureDetector(
      onDoubleTap: ()=> controlUserPostLike(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.network(url),
          showHeart? Icon(Icons.favorite, size: 140.0, color: Colors.pinkAccent) : Text("")
        ],
      ),
    );
  }

  createPostFooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: ()=> controlUserPostLike(),
              child: Icon(
                isLiked? Icons.favorite: Icons.favorite_border,
                size: 20.0,
                color: Colors.red,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: ()=> displayComments(context, postId: postId, ownerId: ownerId, url: url),
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$likeCount likes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$profileName ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text('$description', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ],
    );
  }

  displayComments(BuildContext context, {String postId, String ownerId, String url}) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> CommentsPage(postId: postId, postOwnerId: ownerId, postImageUrl: url)));
  }
}
