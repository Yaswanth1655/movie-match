import 'package:flutter/material.dart';

extension ExtendedNavigator on BuildContext {
  Future<dynamic> push(Widget page) async {
    Navigator.push(this, MaterialPageRoute(builder: (_) => page));
  }

  Future<dynamic> pushReplacement(Widget page) async {
    Navigator.pushReplacement(this, MaterialPageRoute(builder: (_) => page));
  }

  Future<dynamic> pushAndRemoveUntil(Widget page) async {
    Navigator.pushAndRemoveUntil(
        this, MaterialPageRoute(builder: (_) => page), (route) => false);
  }

  Future<void> pop([result]) async {
    return Navigator.of(this).pop(result);
  }
}