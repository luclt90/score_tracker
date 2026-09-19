import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_detail_state_model.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/navigation.dart';
import 'package:score_tracker/screens/select_player.dart';
import 'package:score_tracker/widgets/game_card_item.dart';
import 'package:score_tracker/widgets/share_app.dart';

import '../styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<InitializationStatus>? _adsInitialization;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    try {
      _adsInitialization = MobileAds.instance.initialize();
    } catch (_) {
      // Ads are optional; the score history must remain usable without them.
      _adsInitialization = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGames());
  }

  Future<void> _loadGames() async {
    if (mounted) setState(() => _isLoading = true);
    await context.read<GameStateModel>().loadGames();
    if (mounted) setState(() => _isLoading = false);
  }

  void _createGame() =>
      Navigator.push(context, smoothPageRoute(const SelectPlayer()));
  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameStateModel>().availableGames;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: buildMenu(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGame,
        backgroundColor: backgroundButtonColorBlue,
        foregroundColor: foregroundButtonColor,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.create_new),
      ),
      body: FutureBuilder<InitializationStatus>(
        future: _adsInitialization,
        builder: (context, _) {
          if (_isLoading) return const _HomeLoading();
          return SafeArea(
            child: RefreshIndicator(
              color: backgroundButtonColorBlue,
              onRefresh: _loadGames,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    backgroundColor: backgroundColor,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: Builder(
                      builder: (context) => IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .openAppDrawerTooltip,
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: Scaffold.of(context).openDrawer,
                      ),
                    ),
                    title: Text(
                      t.app_name,
                      style: const TextStyle(
                        color: foregroundButtonColor,
                        fontFamily: fontFamilySFProText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .refreshIndicatorSemanticLabel,
                        onPressed: _loadGames,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: _HistoryHeader(
                      count: games.length,
                      title: t.home_page_list_title,
                    ),
                  ),
                  if (games.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHistory(
                        title: t.empty_list,
                        message: t.alway_beside,
                      ),
                    )
                  else
                    Consumer<GameDetailStateModel>(
                      builder: (context, _, child) => SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        sliver: SliverList.separated(
                          itemCount: games.length,
                          itemBuilder: (context, index) => GameCardItem(
                            key: ValueKey(games[index].id),
                            game: games[index],
                            index: index + 1,
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Theme buildMenu(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(canvasColor: backgroundHeaderColor),
    child: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            curve: Curves.easeOut,
            decoration: const BoxDecoration(color: backgroundColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: backgroundButtonColorBlue,
                  child: Icon(
                    Icons.scoreboard_outlined,
                    color: foregroundButtonColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.app_name,
                  style: const TextStyle(
                    color: foregroundButtonColor,
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: foregroundHintColor),
          ShareAppBtn(),
          RateFeedBackBtn(),
          PolicyBtn(),
        ],
      ),
    ),
  );
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count, required this.title});
  final int count;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundHeaderColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundButtonColorBlue.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: backgroundButtonColorBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: foregroundButtonColor,
              fontFamily: fontFamilySFProText,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: backgroundHeaderColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_outlined,
              size: 52,
              color: backgroundButtonColorBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: foregroundButtonColor,
              fontFamily: fontFamilySFProText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: foregroundHintColor,
              fontFamily: fontFamilySFProText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: backgroundButtonColorBlue),
  );
}
