import 'package:flutter/material.dart';
import 'package:score_tracker/l10n/app_localizations.dart';

import '../styles.dart';
import '../widgets/add_players_widget.dart';

class AddPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.add_player,
          style: TextStyle(color: foregroundColor),
        ),
        backgroundColor: backgroundHeaderColor,
      ),
      body: SingleChildScrollView(
        child: AddPlayersWidget(),
      ),
    );
  }
}
