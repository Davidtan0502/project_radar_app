import 'package:flutter/material.dart';

class Navigation {
  static void back(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  static void backToFirst(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  static void push(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pushReplacement(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void replace(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static void pushNamedReplacement(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}