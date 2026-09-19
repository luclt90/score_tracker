import 'package:flutter/material.dart';

import '../styles.dart';

// ignore: must_be_immutable
class InputScore extends StatelessWidget {
  InputScore(
      {required this.playerName,
      required this.playerId,
      // required this.onChanged,
      required this.autoFocus})
      : super();

  final String playerName;
  final int playerId;
  final bool autoFocus;
  late int score = 0;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: autoFocus,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: foregroundColor,
          fontFamily: fontFamilySFProText,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          fontStyle: FontStyle.normal),
      keyboardType:
          TextInputType.numberWithOptions(decimal: false, signed: true),
      decoration: InputDecoration(
        labelText: playerName,
        labelStyle: TextStyle(
            color: foregroundHintColor,
            fontFamily: fontFamilySFProText,
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
            fontStyle: FontStyle.normal),
      ),
      onChanged: (value) {
        score = int.tryParse(value) ?? 0;
      },
    );
  }
}
