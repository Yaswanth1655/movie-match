//dynamic spacing
import 'package:flutter/material.dart';

extension SizeExtension on BuildContext {
  //vertical-spacing
  SizedBox verticalSpacing(double factor) =>
      SizedBox(height: MediaQuery.sizeOf(this).height * factor);

  //horizontal-spacing
  SizedBox horizontalSpacing(double factor) =>
      SizedBox(width: MediaQuery.sizeOf(this).height * factor);

  //height
  double dynamicHeight(double factor) =>
      MediaQuery.sizeOf(this).height * factor;

  //width
  double dynamicWidth(double factor) => MediaQuery.sizeOf(this).width * factor;
}
