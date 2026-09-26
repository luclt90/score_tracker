import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/ad_manager.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/game_detail_state_model.dart';
import 'package:score_tracker/models/player_in_game.dart';
import 'package:score_tracker/models/player_score.dart';
import 'package:score_tracker/services/iap_service.dart';
import 'package:score_tracker/widgets/remove_ads_offer.dart';

import '../styles.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({required this.game, required this.playerIds, super.key});

  final Game game;
  final List<int> playerIds;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  BannerAd? _bannerAd;
  bool _bannerRequested = false;
  bool _isLoading = true;
  bool _showEditHint = true;
  Object? _loadError;
  late final IAPService _iapService;

  @override
  void initState() {
    super.initState();
    _iapService = context.read<IAPService>()..addListener(_onIAPChanged);
    _loadGame();
    if (_iapService.isEntitlementResolved && !_iapService.isPurchased) {
      _loadBanner();
    }
  }

  Future<void> _loadGame() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      await context.read<GameDetailStateModel>().loadGameDetails(
        widget.game.id!,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      log('Failed to load game board', error: error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error;
        });
      }
    }
  }

  void _loadBanner() {
    if (_bannerRequested ||
        !_iapService.isEntitlementResolved ||
        _iapService.isPurchased) {
      return;
    }
    _bannerRequested = true;
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitId
          : AdManager.bannerAdUnitIdTest,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _iapService.isPurchased) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          log('Failed to load game-board banner: ${error.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void _onIAPChanged() {
    if (_iapService.isPurchased) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) setState(() {});
    } else if (_iapService.isEntitlementResolved) {
      _loadBanner();
    }
  }

  Future<void> _openAddScoreSheet(
    List<PlayerInGame> players,
    int nextRound,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddScoreSheet(
        players: players,
        onSave: (scores) => context
            .read<GameDetailStateModel>()
            .addScoresToGame(nextRound, widget.game.id!, scores),
      ),
    );
    if (saved == true && mounted) await _loadGame();
  }

  Future<void> _openEditScoreSheet(
    GameDetail detail,
    PlayerInGame player,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditScoreSheet(
        playerName: player.playerName,
        initialScore: detail.score,
        onSave: (score) => context
            .read<GameDetailStateModel>()
            .updateGameDetailScore(detail.id!, score, widget.game.id!),
      ),
    );
    if (saved == true && mounted && detail.id != null) {
      setState(() {
        _showEditHint = false;
      });
    }
  }

  void _showEditHelp() {
    final t = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundHeaderColor,
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: backgroundButtonColorBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.edit_score_help_title,
                style: const TextStyle(
                  color: foregroundButtonColor,
                  fontFamily: fontFamilySFProText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          t.edit_score_hint,
          style: const TextStyle(
            color: foregroundColor,
            fontFamily: fontFamilySFProText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  Future<void> _finishGame() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundHeaderColor,
        title: const Text(
          'Kết thúc ván',
          style: TextStyle(
            color: foregroundButtonColor,
            fontFamily: fontFamilySFProText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Ván đã được lưu trong lịch sử. Bạn có thể mở lại sau.',
          style: TextStyle(
            color: foregroundColor,
            fontFamily: fontFamilySFProText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục ghi điểm'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: backgroundButtonColorBlue,
            ),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (shouldFinish != true || !mounted) return;
    if (!_iapService.isPurchased) {
      await showRemoveAdsOfferDialog(context);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIAPChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final model = context.watch<GameDetailStateModel>();
    final players = model.playersInGame;
    final details = model.availableGameDetails;
    final rounds = groupBy(details, (detail) => detail.gameIndex);
    final nextRound = details.isEmpty ? 1 : details.first.gameIndex + 1;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          t.score_board,
          style: const TextStyle(
            color: foregroundButtonColor,
            fontFamily: fontFamilySFProText,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: foregroundButtonColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Kết thúc ván',
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: foregroundButtonColor,
            ),
            onPressed: _finishGame,
          ),
          IconButton(
            tooltip: t.edit_score_help_title,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: foregroundButtonColor,
            ),
            onPressed: _showEditHelp,
          ),
        ],
      ),
      body: _isLoading
          ? const _BoardLoading()
          : _loadError != null
          ? _BoardLoadError(onRetry: _loadGame, label: t.retry)
          : players.isEmpty
          ? const _BoardEmpty()
          : Column(
              children: [
                if (_showEditHint && details.isNotEmpty)
                  _EditScoreHint(
                    text: t.edit_score_hint,
                    onPressed: _showEditHelp,
                  ),
                Expanded(
                  child: details.isEmpty
                      ? _BoardEmpty(
                          onAddScore: () =>
                              _openAddScoreSheet(players, nextRound),
                        )
                      : _ScoreTable(
                          players: players,
                          rounds: rounds,
                          onEditScore: _openEditScoreSheet,
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading
          ? _ScoreActionPanel(
              label: t.add_score,
              bannerAd: _bannerAd,
              onAddScore: null,
            )
          : _loadError != null || players.isEmpty
          ? null
          : _ScoreActionPanel(
              label: t.add_score,
              bannerAd: _bannerAd,
              onAddScore: () => _openAddScoreSheet(players, nextRound),
            ),
    );
  }
}

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({
    required this.players,
    required this.rounds,
    required this.onEditScore,
  });

  final List<PlayerInGame> players;
  final Map<int, List<GameDetail>> rounds;
  final Future<void> Function(GameDetail detail, PlayerInGame player)
  onEditScore;

  @override
  Widget build(BuildContext context) {
    // Reserve space for the round column and table margins, then size player
    // columns so the first four always fit on a phone-sized viewport.
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final visiblePlayerCount = players.length < 4 ? players.length : 4;
    final double playerColumnWidth = ((viewportWidth - 64) / visiblePlayerCount)
        .clamp(56.0, 86.0)
        .toDouble();
    final columnSpacing = players.length <= 4 ? 6.0 : 12.0;
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const MaterialStatePropertyAll(
              backgroundHeaderColor,
            ),
            dataRowColor: const MaterialStatePropertyAll(backgroundColor),
            horizontalMargin: 8,
            columnSpacing: columnSpacing,
            headingRowHeight: 76,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 50,
            columns: [
              const DataColumn(
                label: SizedBox(
                  width: 18,
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundHintColor,
                      fontFamily: fontFamilySFProText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ...players.map(
                (player) => DataColumn(
                  label: SizedBox(
                    width: playerColumnWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: player.totalScore < 0
                                ? negativeScoreBackgroundColor
                                : backgroundButtonColorBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${player.totalScore}',
                                style: TextStyle(
                                  color: foregroundButtonColor,
                                  fontFamily: fontFamilySFProText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          player.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: foregroundColor,
                            fontFamily: fontFamilySFProText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            rows: rounds.entries.map((entry) {
              final round = entry.key;
              final scores = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '$round',
                      style: const TextStyle(
                        color: foregroundHintColor,
                        fontFamily: fontFamilySFProText,
                      ),
                    ),
                  ),
                  ...players.map((player) {
                    final detail = scores.firstWhereOrNull(
                      (item) => item.playerId == player.playerId,
                    );
                    final score = detail?.score;
                    return DataCell(
                      Center(
                        child: Transform.translate(
                          offset: detail?.editedAt != null
                              ? const Offset(7.5, 0)
                              : Offset.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                score?.toString() ?? '–',
                                style: TextStyle(
                                  color: score != null && score < 0
                                      ? negativeScoreColor
                                      : foregroundButtonColor,
                                  fontFamily: fontFamilySFProText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (detail?.editedAt != null) ...[
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: backgroundButtonColorBlue,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      onTap: detail == null
                          ? null
                          : () => onEditScore(detail, player),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _EditScoreHint extends StatelessWidget {
  const _EditScoreHint({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: backgroundHeaderColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_rounded,
                  color: backgroundButtonColorBlue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: foregroundColor,
                      fontFamily: fontFamilySFProText,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: foregroundHintColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreActionPanel extends StatelessWidget {
  const _ScoreActionPanel({
    required this.label,
    required this.bannerAd,
    required this.onAddScore,
  });

  final String label;
  final BannerAd? bannerAd;
  final VoidCallback? onAddScore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: onAddScore,
                style: FilledButton.styleFrom(
                  backgroundColor: backgroundButtonColorBlue,
                  foregroundColor: foregroundButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            if (bannerAd != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: AdSize.banner.height.toDouble(),
                child: Center(
                  child: SizedBox(
                    width: bannerAd!.size.width.toDouble(),
                    height: bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: bannerAd!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardLoading extends StatelessWidget {
  const _BoardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: backgroundButtonColorBlue),
    );
  }
}

class _BoardLoadError extends StatelessWidget {
  const _BoardLoadError({required this.onRetry, required this.label});

  final VoidCallback onRetry;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundButtonColorBlue,
          foregroundColor: foregroundButtonColor,
        ),
      ),
    );
  }
}

class _BoardEmpty extends StatelessWidget {
  const _BoardEmpty({this.onAddScore});

  final VoidCallback? onAddScore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: backgroundHeaderColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.scoreboard_outlined,
                color: backgroundButtonColorBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            if (onAddScore != null)
              FilledButton.icon(
                onPressed: onAddScore,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppLocalizations.of(context)!.add_score),
                style: FilledButton.styleFrom(
                  backgroundColor: backgroundButtonColorBlue,
                  foregroundColor: foregroundButtonColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddScoreSheet extends StatefulWidget {
  const _AddScoreSheet({required this.players, required this.onSave});

  final List<PlayerInGame> players;
  final Future<void> Function(List<PlayerScore> scores) onSave;

  @override
  State<_AddScoreSheet> createState() => _AddScoreSheetState();
}

class _AddScoreSheetState extends State<_AddScoreSheet> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.players.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.players.length, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes.first.requestFocus(),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final scores = List.generate(
      widget.players.length,
      (index) => PlayerScore(
        playerId: widget.players[index].playerId,
        score: int.tryParse(_controllers[index].text.trim()) ?? 0,
      ),
    );
    try {
      await widget.onSave(scores);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: backgroundHeaderColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: foregroundHintColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.add_score,
                    style: const TextStyle(
                      color: foregroundButtonColor,
                      fontFamily: fontFamilySFProText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    widget.players.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        autofocus: index == 0,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        textInputAction: index == widget.players.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: (_) => index == widget.players.length - 1
                            ? _save()
                            : _focusNodes[index + 1].requestFocus(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: foregroundButtonColor,
                          fontFamily: fontFamilySFProText,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.players[index].playerName,
                          labelStyle: const TextStyle(
                            color: foregroundHintColor,
                            fontFamily: fontFamilySFProText,
                          ),
                          filled: true,
                          fillColor: backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: backgroundButtonColorBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: backgroundButtonColorBlue,
                        foregroundColor: foregroundButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: foregroundButtonColor,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        t.save,
                        style: const TextStyle(
                          fontFamily: fontFamilySFProText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditScoreSheet extends StatefulWidget {
  const _EditScoreSheet({
    required this.playerName,
    required this.initialScore,
    required this.onSave,
  });

  final String playerName;
  final int initialScore;
  final Future<void> Function(int score) onSave;

  @override
  State<_EditScoreSheet> createState() => _EditScoreSheetState();
}

class _EditScoreSheetState extends State<_EditScoreSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialScore.toString());
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final score = int.tryParse(_controller.text.trim());
    if (score == null) {
      setState(() => _errorText = 'Enter a valid whole number');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(score);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: backgroundHeaderColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: foregroundHintColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.playerName,
                  style: const TextStyle(
                    color: foregroundButtonColor,
                    fontFamily: fontFamilySFProText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: foregroundButtonColor,
                    fontFamily: fontFamilySFProText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: t.score_board,
                    errorText: _errorText,
                    labelStyle: const TextStyle(
                      color: foregroundHintColor,
                      fontFamily: fontFamilySFProText,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: backgroundButtonColorBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foregroundButtonColor,
                          side: const BorderSide(color: foregroundHintColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(t.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: backgroundButtonColorBlue,
                          foregroundColor: foregroundButtonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: foregroundButtonColor,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(t.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
