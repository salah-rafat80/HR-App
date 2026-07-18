import 'package:flutter/material.dart';


class AppSpacing {
  static final double xs = 4.0;
  static final double sm = 8.0;
  static final double md = 16.0;
  static final double lg = 24.0;
  static final double xl = 32.0;
  static final double xxl = 48.0;

  static SizedBox get verticalXs => SizedBox(height: xs);
  static SizedBox get verticalSm => SizedBox(height: sm);
  static SizedBox get verticalMd => SizedBox(height: md);
  static SizedBox get verticalLg => SizedBox(height: lg);
  static SizedBox get verticalXl => SizedBox(height: xl);
  static SizedBox get verticalXxl => SizedBox(height: xxl);

  static SizedBox get horizontalXs => SizedBox(width: xs);
  static SizedBox get horizontalSm => SizedBox(width: sm);
  static SizedBox get horizontalMd => SizedBox(width: md);
  static SizedBox get horizontalLg => SizedBox(width: lg);
  static SizedBox get horizontalXl => SizedBox(width: xl);
  static SizedBox get horizontalXxl => SizedBox(width: xxl);
}
