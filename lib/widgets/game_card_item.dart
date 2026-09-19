import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/game_board.dart';

import '../styles.dart';

class GameCardItem extends StatefulWidget {
  const GameCardItem({required this.game, required this.index, super.key});
  final Game game;
  final int index;
  @override
  State<GameCardItem> createState() => _GameCardItemState();
}

class _GameCardItemState extends State<GameCardItem> {
  late Future<List<Player>> _playersFuture;
  @override
  void initState() {
    super.initState();
    _playersFuture = context.read<PlayerStateModel>().getPlayersWithGameId(
      widget.game.id ?? 0,
    );
  }

  @override
  void didUpdateWidget(covariant GameCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _playersFuture = context.read<PlayerStateModel>().getPlayersWithGameId(
        widget.game.id ?? 0,
      );
    }
  }

  void _openGame(List<Player> players) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GameBoard(
        game: widget.game,
        playerIds: players.map((player) => player.id!).toList(),
      ),
    ),
  );
  Future<void> _createRematch(List<Player> players) async {
    final model = context.read<GameStateModel>();
    final id = await model.addGame(
      Game(
        numberOfPlayers: players.length,
        createAt: DateFormat('yyyy-MM-dd H:m').format(DateTime.now()),
      ),
      players.map((player) => player.id!).toList(),
    );
    final game = await model.getGameWithId(id);
    if (!mounted || game == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameBoard(
          game: game,
          playerIds: players.map((player) => player.id!).toList(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    // Keep the ID that belongs to the visible card. The list can rebuild while
    // the confirmation dialog is open.
    final gameId = widget.game.id;
    final delete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundHeaderColor,
        title: Text(
          AppLocalizations.of(context)!.delete,
          style: const TextStyle(
            color: foregroundButtonColor,
            fontFamily: fontFamilySFProText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.delete_confirm,
          style: const TextStyle(
            color: foregroundColor,
            fontFamily: fontFamilySFProText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (delete == true && gameId != null) {
      await context.read<GameStateModel>().deleteGame(gameId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Player>>(
    future: _playersFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const _GameCardPlaceholder();
      final players = snapshot.data!;
      return Material(
        color: backgroundHeaderColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openGame(players),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: backgroundButtonColorBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: foregroundButtonColor,
                          fontFamily: fontFamilySFProText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        players.map((player) => player.name).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: foregroundButtonColor,
                          fontFamily: fontFamilySFProText,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.delete,
                      onPressed: _confirmDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: foregroundHintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: foregroundHintColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formattedDate(),
                        style: const TextStyle(
                          color: foregroundHintColor,
                          fontFamily: fontFamilySFProText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createRematch(players),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.new_play),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: foregroundColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  String _formattedDate() {
    try {
      return DateFormat('MMM d, yyyy • HH:mm')
          .format(DateFormat('yyyy-MM-dd H:m').parse(widget.game.createAt));
    } catch (_) {
      return widget.game.createAt;
    }
  }
}

class _GameCardPlaceholder extends StatelessWidget {
  const _GameCardPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    decoration: BoxDecoration(
      color: backgroundHeaderColor,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: backgroundButtonColorBlue,
        ),
      ),
    ),
  );
}
