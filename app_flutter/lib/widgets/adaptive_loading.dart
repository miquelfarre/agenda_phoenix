import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveLoading extends StatelessWidget {
  final double? radius;
  final Color? color;

  const AdaptiveLoading({super.key, this.radius, this.color});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(radius: radius ?? 10, color: color);
    }
    return CircularProgressIndicator(color: color);
  }
}
