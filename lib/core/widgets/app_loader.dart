import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({
    super.key,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lottie/loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
