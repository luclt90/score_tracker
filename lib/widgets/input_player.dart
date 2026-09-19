import 'package:flutter/material.dart';
import 'package:score_tracker/l10n/app_localizations.dart';

import '../styles.dart';

// ignore: must_be_immutable
class InputPlayer extends StatelessWidget {
  InputPlayer({
    required this.playerController,
    this.hint = "",
  }) : super();

  final TextEditingController playerController;
  String hint = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 15.0),
      child: TextFormField(
          maxLength: 10,
          controller: playerController,
          keyboardType: TextInputType.text,
          style: TextStyle(color: foregroundColor),
          decoration: InputDecoration(
              labelStyle: TextStyle(color: foregroundHintColor),
              counterStyle: TextStyle(color: foregroundHintColor),
              enabledBorder: const OutlineInputBorder(
                // width: 0.0 produces a thin "hairline" border
                borderSide:
                    const BorderSide(color: backgroundHeaderColor, width: 0.0),
              ),
              focusedBorder: const OutlineInputBorder(
                // width: 0.0 produces a thin "hairline" border
                borderSide: const BorderSide(
                    color: backgroundButtonColorBlue, width: 1.0),
              ),
              border: const OutlineInputBorder(),
              // ignore: unnecessary_null_comparison
              hintText: hint != null
                  ? hint
                  : AppLocalizations.of(context)!.player_name_hint,
              hintStyle: TextStyle(color: foregroundHintColor))),
    );
  }
}
