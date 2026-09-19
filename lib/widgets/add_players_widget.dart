import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/game_board.dart';

import '../ad_manager.dart';
import '../styles.dart';

class AddPlayersWidget extends StatefulWidget {
  const AddPlayersWidget({super.key});

  @override
  State<AddPlayersWidget> createState() => _AddPlayersWidgetState();
}

class _AddPlayersWidgetState extends State<AddPlayersWidget> {
  static const _playerOptions = [2, 3, 4, 5, 6];
  int _selectedPlayers = 4;
  bool _isStarting = false;
  final List<TextEditingController> _controllers = [];
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _createControllers(_selectedPlayers);
    _loadBanner();
  }

  void _createControllers(int count) {
    for (var index = 0; index < count; index++) {
      final controller = TextEditingController();
      controller.addListener(_onNameChanged);
      _controllers.add(controller);
    }
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  void _loadBanner() {
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitAddPlayerId
          : AdManager.bannerAdUnitIdTest,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          log('Failed to load add-player banner: ${error.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void _changePlayerCount(int count) {
    if (count == _selectedPlayers) return;
    setState(() {
      for (final controller in _controllers) {
        controller
          ..removeListener(_onNameChanged)
          ..dispose();
      }
      _controllers.clear();
      _selectedPlayers = count;
      _createControllers(count);
    });
  }

  bool get _canStart =>
      _controllers.length >= 2 && _controllers.every((item) => item.text.trim().isNotEmpty);

  Future<void> _startGame() async {
    if (!_canStart || _isStarting) return;
    setState(() => _isStarting = true);
    final now = DateFormat('yyyy-MM-dd H:m').format(DateTime.now());
    final players = _controllers
        .map((controller) => Player(name: controller.text.trim(), memo: '', createAt: now))
        .toList();

    try {
      final playerModel = context.read<PlayerStateModel>();
      final gameModel = context.read<GameStateModel>();
      final playerIds = await playerModel.insertPlayers(players, isNotify: false);
      final gameId = await gameModel.addGame(
        Game(numberOfPlayers: players.length, createAt: now),
        playerIds,
      );
      final game = await gameModel.getGameWithId(gameId);
      if (!mounted || game == null) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameBoard(game: game, playerIds: playerIds),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onNameChanged)
        ..dispose();
    }
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroCard(title: t.select_2to6player),
            const SizedBox(height: 20),
            Text(
              t.player_number,
              style: const TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _playerOptions.map((count) {
                final selected = count == _selectedPlayers;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  onSelected: (_) => _changePlayerCount(count),
                  backgroundColor: backgroundHeaderColor,
                  selectedColor: backgroundButtonColorBlue,
                  labelStyle: TextStyle(
                    color: selected ? foregroundButtonColor : foregroundColor,
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(color: selected ? backgroundButtonColorBlue : foregroundHintColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              t.player_name_hint,
              style: const TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _controllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlayerNameField(
                  controller: _controllers[index],
                  index: index + 1,
                  hint: '${t.player_name_hint} ${index + 1}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _canStart && !_isStarting ? _startGame : null,
                style: FilledButton.styleFrom(
                  backgroundColor: backgroundButtonColorBlue,
                  disabledBackgroundColor: backgroundHeaderColor,
                  foregroundColor: foregroundButtonColor,
                  disabledForegroundColor: foregroundHintColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: foregroundButtonColor),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  t.let_start,
                  style: const TextStyle(
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: AdSize.banner.height.toDouble(),
              child: _bannerAd == null
                  ? null
                  : Center(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundHeaderColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundButtonColorBlue.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.group_add_outlined, color: backgroundButtonColorBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({required this.controller, required this.index, required this.hint});
  final TextEditingController controller;
  final int index;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 10,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: foregroundButtonColor, fontFamily: fontFamilySFProText),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: foregroundHintColor, fontFamily: fontFamilySFProText),
        prefixIcon: Container(
          width: 38,
          alignment: Alignment.center,
          margin: const EdgeInsets.all(7),
          decoration: const BoxDecoration(color: backgroundButtonColorBlue, shape: BoxShape.circle),
          child: Text('$index', style: const TextStyle(color: foregroundButtonColor, fontFamily: fontFamilySFProText, fontWeight: FontWeight.w700)),
        ),
        filled: true,
        fillColor: backgroundHeaderColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: backgroundHeaderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: backgroundButtonColorBlue, width: 1.5)),
      ),
    );
  }
}
