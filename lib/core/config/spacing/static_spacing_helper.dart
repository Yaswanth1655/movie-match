//spacing helper
import 'package:flutter/material.dart';

class Spacing {
  static Widget verticalSpace(double height) {
    return SizedBox(
      height: height,
    );
  }

  static Widget horizontalSpace(double width) {
    return SizedBox(
      width: width,
    );
  }
}
