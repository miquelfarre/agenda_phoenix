import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptivePrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isDestructive;

  const AdaptivePrimaryButton({super.key, required this.onPressed, required this.text, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton.filled(onPressed: onPressed, child: Text(text));
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: isDestructive ? ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white) : null,
      child: Text(text),
    );
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const AdaptiveTextButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(onPressed: onPressed, child: Text(text));
    }
    return TextButton(onPressed: onPressed, child: Text(text));
  }
}
