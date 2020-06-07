import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle, String strTitle, disableBackButton = false}) {
  return AppBar(
    iconTheme: IconThemeData(
      color: Colors.white
    ),
    automaticallyImplyLeading: disableBackButton ? false : true,
    title: Text(
      isAppTitle? 'KikArt': strTitle,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle? "Signatra": "",
        fontSize: isAppTitle? 45.0 : 22.0
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
