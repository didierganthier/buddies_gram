import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderPage.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:flutter/material.dart';

class PostScreenPage extends StatelessWidget {
  final String userId, postId;

  PostScreenPage({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsReference.document(userId).collection("usersPosts").document(postId).get(),
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData){
          return circularProgress();
        }
        Post post = Post.fromDocument(dataSnapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, strTitle: post.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
