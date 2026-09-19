import 'package:flutter/material.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/share_icon_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles.dart';

class ShareAppBtn extends StatefulWidget {
  @override
  _ShareAppBtnState createState() => _ShareAppBtnState();
}

class _ShareAppBtnState extends State<ShareAppBtn> {
  String text =
      "Download the latest Ghi Diem Danh Bai App on Google Play Store\n\n\n\n"
      "https://play.google.com/store/apps/details?id=ywmluclt.score_tracker";

  void share(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox;

    await Share.share(
      "${AppLocalizations.of(context)!.download}\n\n\n\n"
      "https://play.google.com/store/apps/details?id=ywmluclt.score_tracker",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.share_rounded, color: foregroundColor),
      title: Text(
        AppLocalizations.of(context)!.share_application.trim(),
        style: const TextStyle(
          color: foregroundColor,
          fontFamily: fontFamilySFProText,
          fontSize: 16,
        ),
      ),
      onTap: () => share(context),
    );
  }
}

class RateFeedBackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(ShareIcon.google_play, color: foregroundColor),
      title: Text(
        AppLocalizations.of(context)!.vote_application.trim(),
        style: const TextStyle(
          color: foregroundColor,
          fontFamily: fontFamilySFProText,
          fontSize: 16,
        ),
      ),
      onTap: launchAppStorePage,
    );
  }

  void launchAppStorePage() async {
    final String packageName = 'ywmluclt.score_tracker';
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch app store page';
    }
  }
}

// ignore: must_be_immutable
class PolicyBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.policy_rounded, color: foregroundColor),
      title: Text(
        AppLocalizations.of(context)!.privacy_policy.trim(),
        style: const TextStyle(
          color: foregroundColor,
          fontFamily: fontFamilySFProText,
          fontSize: 16,
        ),
      ),
      onTap: _launchURL,
    );
  }

  final policyUrl = Uri.parse('https://ywmluclt.github.io/scoretracker/');
  void _launchURL() async => await canLaunchUrl(policyUrl)
      ? await launchUrl(policyUrl)
      : throw 'Could not launch $policyUrl';
}
