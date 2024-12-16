import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget? child;
  final List<Color> colors;

  const GradientContainer({
    super.key,
    this.child,
    required this.colors
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}