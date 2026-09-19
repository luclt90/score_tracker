import 'package:flutter/material.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/share_icon_icons.dart';
//import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';

import '../styles.dart';

const style = TextStyle(
  fontSize: 16.0,
  fontFamily: "SF Pro Display",
  color: foregroundColor,
);

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

    // await Share.share(
    //   "${AppLocalizations.of(context)!.download}\n\n\n\n"
    //   "https://play.google.com/store/apps/details?id=ywmluclt.score_tracker",
    //   sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.055,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundButtonColorBlue,
          ),
          onPressed: () => share(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share,
                size: MediaQuery.of(context).size.height * 0.025,
                color: const Color(0xffcccccc),
              ),
              Text(
                AppLocalizations.of(context)!.share_application,
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RateFeedBackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.055,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundButtonColorBlue,
          ),
          onPressed: () => launchAppStorePage(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ShareIcon.google_play,
                size: MediaQuery.of(context).size.height * 0.025,
                color: const Color(0xffcccccc),
              ),
              Text(
                AppLocalizations.of(context)!.vote_application,
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void launchAppStorePage() async {
    final String packageName = 'ywmluclt.score_tracker';
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    // if (await canLaunchUrl(url)) {
    //   await launchUrl(url);
    // } else {
    //   throw 'Could not launch app store page';
    // }
  }
}

// ignore: must_be_immutable
class PolicyBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.055,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundButtonColorBlue,
          ),
          onPressed: () => (), // _launchURL,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.policy,
                size: MediaQuery.of(context).size.height * 0.025,
                color: const Color(0xffcccccc),
              ),
              Text(AppLocalizations.of(context)!.privacy_policy, style: style),
            ],
          ),
        ),
      ),
    );
  }

  final policyUrl = Uri.parse('https://ywmluclt.github.io/scoretracker/');
  // void _launchURL() async => await canLaunchUrl(policyUrl)
  //     ? await launchUrl(policyUrl)
  //     : throw 'Could not launch $policyUrl';
}
