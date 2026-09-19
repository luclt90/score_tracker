import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_detail_state_model.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/screens/select_player.dart';
import 'package:score_tracker/widgets/game_card_item.dart';
import 'package:score_tracker/widgets/share_app.dart';

import '../styles.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final model = Provider.of<GameStateModel>(context, listen: false);
      model.loadGames().then(
        (value) => {
          setState(() {
            _isLoading = false;
          }),
        },
      );
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<GameStateModel>(context);
    final fetchedGames = model.availableGames;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.home_page_list_title,
          style: TextStyle(color: foregroundColor),
        ),
        centerTitle: true,
        backgroundColor: backgroundHeaderColor,
      ),
      drawer: buildMenu(context),
      body: FutureBuilder(
        future: _initGoogleMobileAds(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasData) {
            return _isLoading
                ? Center(child: CircularProgressIndicator())
                : model.countGame() > 0
                ? Consumer<GameDetailStateModel>(
                    builder: (context, model, child) {
                      return ListView.builder(
                        itemCount: fetchedGames.length,
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 0.0,
                        ),
                        itemBuilder: (context, index) {
                          return GameCardItem(
                            game: fetchedGames[index],
                            index: ++index,
                          );
                        },
                      );
                    },
                  )
                : _buildEmptyList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 150.0),
              child: CircularProgressIndicator(),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 150.0),
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectPlayer()),
          );
        },
        child: Icon(Icons.add_circle_outline, color: foregroundButtonColor),
        backgroundColor: backgroundButtonColorBlue,
      ),
    );
  }

  Theme buildMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Color(0xff35363b)),
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.app_name,
                    style: TextStyle(
                      color: foregroundColor,
                      fontFamily: fontFamilySFProText,
                      fontWeight: FontWeight.w600,
                      fontSize: 22.0,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(height: 5.0),
                  // FutureBuilder<PackageInfo>(
                  //     future: PackageInfo.fromPlatform(),
                  //     builder: (context, snapshot) {
                  //       String text = '';
                  //       if (snapshot.data != null) {
                  //         final buildVersion = snapshot.data?.version;
                  //         text = 'Version ' + buildVersion!;
                  //       }
                  //       return Text(
                  //         text,
                  //         style: TextStyle(
                  //             color: foregroundColor,
                  //             fontFamily: fontFamilySFProText,
                  //             fontWeight: FontWeight.w600,
                  //             fontSize: 15.0,
                  //             fontStyle: FontStyle.italic),
                  //       );
                  //     }),
                ],
              ),
              decoration: BoxDecoration(color: const Color(0xff35363b)),
            ),
            ShareAppBtn(),
            RateFeedBackBtn(),
            PolicyBtn(),
          ],
        ),
      ),
    );
  }

  Padding _buildEmptyList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 150.0),
      child: Column(
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.empty_list,
            style: TextStyle(
              color: foregroundColor,
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 22.0,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 20.0),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 50.0, right: 50.0),
              child: Text(
                AppLocalizations.of(context)!.alway_beside,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor,
                  fontFamily: fontFamilySFProText,
                  fontWeight: FontWeight.normal,
                  fontSize: 18.0,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          Container(
            margin: EdgeInsets.only(
              left: 50.0,
              top: 10.0,
              right: 50.0,
              bottom: 10.0,
            ),
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundButtonColorBlue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectPlayer()),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.create_new,
                style: TextStyle(
                  color: foregroundColor,
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                  fontStyle: FontStyle.normal,
                ),
              ),
              // shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(6.0)),
            ),
          ),
        ],
      ),
    );
  }

  Future<InitializationStatus> _initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }
}
