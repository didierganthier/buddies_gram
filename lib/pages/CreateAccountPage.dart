import 'package:buddiesgram/widgets/HeaderPage.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(context, ),
    );
  }
}
