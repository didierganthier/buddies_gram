import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/NotificationsPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/pages/SearchPage.dart';
import 'package:buddiesgram/pages/TimeLinePage.dart';
import 'package:buddiesgram/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = Firestore.instance.collection("users");
final StorageReference storageReference = FirebaseStorage.instance.ref().child("Posts Pictures");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followersReference = Firestore.instance.collection("followers");
final followingReference = Firestore.instance.collection("following");
final timelineReference = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  controlSignIn(GoogleSignInAccount signInAccount) async{
    if(signInAccount != null)
    {
      await saveUserInfoToFirestore();
      setState(() {
        isSignedIn = true;
      });

      configureRealTimePushNotifications();
    }
    else
    {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotifications(){
    final GoogleSignInAccount gUser = gSignIn.currentUser;

    if(Platform.isIOS){
      getIOSPermissions();
    }

    _firebaseMessaging.getToken().then((token){
      usersReference.document(gUser.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map< String, dynamic> msg) async{
        final String recipientId = msg["data"]["recipient"];
        final String body = msg["data"]["recipient"];

        if(recipientId == gUser.id){
          SnackBar snackBar = SnackBar(
            backgroundColor: Colors.grey,
            content: Text(body, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      },
    );
  }

  getIOSPermissions(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));
    
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings Registered: $settings");
    });
  }

  saveUserInfoToFirestore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await usersReference.document(gCurrentUser.id).get();

    if(!documentSnapshot.exists) {
      usersReference.document(gCurrentUser.id).setData({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "Be creative",
        "timestamp": timestamp
      });

      await followersReference.document(gCurrentUser.id).collection("userFollowers").document(gCurrentUser.id).setData({});

      documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
  }

  loginUser(){
    gSignIn.signIn();
  }

  logoutUser(){
    gSignIn.signOut();
  }

  whenPageChanges(int index){
    setState(() {
      this.getPageIndex = index;
    });
  }

  onTapChangePage(int index){
    pageController.animateToPage(index, duration: Duration(milliseconds: 400), curve: Curves.bounceInOut);
  }

  Widget buildHomeScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser),
          SearchPage(),
          UploadPage(gCurrentUser: currentUser),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser.id)
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text("Home")),
          BottomNavigationBarItem(icon: Icon(Icons.search), title: Text("Search")),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), title: Text("Add Post")),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), title: Text("Notifications")),
          BottomNavigationBarItem(icon: Icon(Icons.person), title: Text("Profile")),
        ],
      ),
    );
  }

  Scaffold buildSignInScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor]
          )
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'KikArt',
              style: TextStyle(fontSize: 92.0, color: Colors.white, fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: () => loginUser(),
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  void initState() {
    super.initState();

      pageController = PageController();

      gSignIn.onCurrentUserChanged.listen((gSignInAccount) {
        controlSignIn(gSignInAccount);
      }, onError: (gError){
        print('Error $gError');
      });

      gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount){
        controlSignIn(gSignInAccount);
      }, onError: (gError){
        print('Error $gError');
      });
  }

  @override
  Widget build(BuildContext context) {
    if(isSignedIn)
    {
      return buildHomeScreen();
    }
    else
    {
      return buildSignInScreen();
    }
  }
}
