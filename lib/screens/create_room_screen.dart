import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:score_tracker/domain/models/room.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';
import 'package:score_tracker/services/iap_service.dart';
import 'package:score_tracker/services/room_access_service.dart';
import 'package:score_tracker/services/room_analytics_service.dart';
import 'package:score_tracker/services/room_sync_coordinator.dart';
import 'package:share_plus/share_plus.dart';

import '../styles.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({
    required this.players,
    required this.rounds,
    required this.scores,
    required this.gameId,
    super.key,
  });

  final List<RoomPlayer> players;
  final List<RoomRound> rounds;
  final Map<String, int> scores;
  final int gameId;

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _access = RoomAccessService();
  late final RoomRepository _repository;
  late final IAPService _iap;
  late final RoomSyncCoordinator _roomSync;
  Stream<Room>? _roomStream;
  String? _roomCode;
  String? _error;
  bool _isLoading = true;
  bool _isPaywallVisible = false;
  bool _isClosing = false;

  bool get _hasPaidAccess =>
      _iap.hasMultiViewerEntitlement || _iap.hasPremiumPlusEntitlement;

  @override
  void initState() {
    super.initState();
    _repository = context.read<RoomRepository>();
    _roomSync = context.read<RoomSyncCoordinator>();
    _iap = context.read<IAPService>()..addListener(_onIAPChanged);
    unawaited(_createRoom());
  }

  Future<void> _createRoom() async {
    if (_roomCode != null || !_isLoading) return;
    try {
      final activeRoom = await _roomSync.activeRoomFor(widget.gameId);
      if (activeRoom != null) {
        if (!mounted) return;
        setState(() {
          _roomCode = activeRoom;
          _roomStream = _repository.watchRoom(activeRoom);
          _isLoading = false;
        });
        return;
      }

      final hostId = await _repository.currentUserId();
      if (!_hasPaidAccess && await _access.hasUsedFreeRoom(hostId)) {
        await RoomAnalyticsService.logEvent('paywall_shown');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isPaywallVisible = true;
          });
        }
        return;
      }

      final code = await _repository.createRoom(
        hostId: hostId,
        players: widget.players,
        rounds: widget.rounds,
        scores: widget.scores,
      );
      await RoomAnalyticsService.logEvent('room_created');
      if (!_hasPaidAccess) {
        try {
          await _access.markFreeRoomUsed(hostId);
        } catch (_) {
          // A preference failure must not discard a successfully created room.
        }
      }
      await _roomSync.registerRoom(
        gameId: widget.gameId,
        roomCode: code,
        rounds: widget.rounds,
        scores: widget.scores,
      );
      if (!mounted) return;
      setState(() {
        _roomCode = code;
        _roomStream = _repository.watchRoom(code);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  void _onIAPChanged() {
    if (_isPaywallVisible && _hasPaidAccess && mounted) {
      setState(() => _isPaywallVisible = false);
      _isLoading = true;
      unawaited(_createRoom());
    }
  }

  Future<void> _closeRoom() async {
    final code = _roomCode;
    if (code == null || _isClosing) return;
    setState(() => _isClosing = true);
    try {
      await _repository.closeRoom(code);
      await RoomAnalyticsService.logEvent('room_closed');
      await _roomSync.unregisterRoom(widget.gameId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isClosing = false;
          _error = _errorMessage(error);
        });
      }
    }
  }

  Future<void> _kickViewer(String viewerId) async {
    final code = _roomCode;
    if (code == null) return;
    try {
      await _repository.kickViewer(roomCode: code, viewerId: viewerId);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    }
  }

  Future<void> _purchase(String productId) async {
    await _iap.purchaseProduct(productId);
  }

  String _errorMessage(Object error) => switch (error) {
    RoomRepositoryException(:final code) => switch (code) {
      'room_full' => 'Phòng đã đủ người xem.',
      'room_not_found' => 'Không tìm thấy phòng.',
      'room_ended' => 'Phòng đã kết thúc hoặc hết hạn.',
      'anonymous_auth_disabled' =>
        'Firebase Anonymous Authentication chưa được bật.',
      'database_not_configured' =>
        'Realtime Database chưa được tạo hoặc thiếu Database URL.',
      'database_permission_denied' => 'Realtime Database từ chối quyền. Hãy kiểm tra database.rules.json đã được publish.',
      'network_unavailable' => 'Không có kết nối đến Firebase. Hãy thử lại.',
      'firebase_not_initialized' =>
        'Firebase chưa được cấu hình cho ứng dụng này.',
      'room_code_allocation_failed' =>
        'Không tạo được mã phòng duy nhất. Hãy thử lại.',
      _ => 'Không thể kết nối phòng. Hãy thử lại.',
    },
    _ => 'Không thể tạo phòng. Hãy kiểm tra kết nối và thử lại.',
  };

  @override
  void dispose() {
    _iap.removeListener(_onIAPChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: roomExperienceTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chia sẻ điểm trực tiếp'),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isPaywallVisible
            ? _buildPaywall()
            : _roomStream == null
            ? _buildError()
            : _buildRoom(),
      ),
    );
  }

  Widget _buildRoom() => StreamBuilder<Room>(
    stream: _roomStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _RoomErrorBanner(message: _errorMessage(snapshot.error!)),
          ),
        );
      }
      final room = snapshot.data;
      if (room == null) return const Center(child: CircularProgressIndicator());
      if (!room.isJoinableAt(DateTime.now().toUtc())) {
        return const Center(
          child: Text(
            'Phòng đã kết thúc.',
            style: TextStyle(color: foregroundButtonColor, fontSize: 18),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: backgroundHeaderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'ĐANG PHÁT TRỰC TIẾP',
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'MÃ PHÒNG',
                  style: TextStyle(
                    color: roomSecondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SelectableText(
                          room.code,
                          style: const TextStyle(
                            color: foregroundButtonColor,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Sao chép mã phòng',
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: room.code)),
                      style: IconButton.styleFrom(
                        foregroundColor: foregroundButtonColor,
                        backgroundColor: backgroundButtonColorBlue.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                Text(
                  'Chia sẻ mã hoặc QR để bạn bè tham gia',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: foregroundColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'Phòng hoạt động đến ${_formatExpiry(room.expiresAt)}',
                  style: const TextStyle(
                    color: roomSecondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: QrImageView(
                data: room.code,
                version: QrVersions.auto,
                size: 188,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text:
                    'Xem điểm trực tiếp trong Score Keeper. Mã phòng: ${room.code}',
              ),
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Chia sẻ mã phòng'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Người đang xem',
                  style: TextStyle(
                    color: foregroundButtonColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: backgroundHeaderColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${room.viewers.length}/$maxRoomViewers',
                  style: const TextStyle(
                    color: foregroundButtonColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (room.viewers.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundHeaderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    color: foregroundHintColor,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang chờ bạn bè tham gia phòng.',
                      style: TextStyle(color: foregroundColor),
                    ),
                  ),
                ],
              ),
            )
          else
            ...room.viewers.values.map(
              (viewer) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  backgroundColor: backgroundButtonColorBlue.withValues(
                    alpha: 0.24,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: foregroundButtonColor,
                  ),
                ),
                title: Text(
                  viewer.name,
                  style: const TextStyle(
                    color: foregroundButtonColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _formatJoinedAt(viewer.joinedAt),
                  style: const TextStyle(color: roomSecondaryTextColor),
                ),
                trailing: IconButton(
                  tooltip: 'Mời người xem rời phòng',
                  onPressed: () => _kickViewer(viewer.id),
                  icon: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: negativeScoreColor,
                  ),
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _RoomErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isClosing ? null : _closeRoom,
            style: OutlinedButton.styleFrom(
              foregroundColor: negativeScoreColor,
              side: const BorderSide(color: negativeScoreBackgroundColor),
            ),
            icon: _isClosing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined),
            label: const Text('Đóng phòng'),
          ),
        ],
      );
    },
  );

  Widget _buildPaywall() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundHeaderColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.groups_rounded,
              color: backgroundButtonColorBlue,
              size: 30,
            ),
            SizedBox(height: 12),
            Text(
              'Mở khóa Multi-Viewer',
              style: TextStyle(
                color: foregroundButtonColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bạn bè có thể xem điểm trực tiếp trên điện thoại của họ.',
              style: TextStyle(color: foregroundColor, height: 1.4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _iap.isPurchasing
            ? null
            : () => _purchase(IAPService.multiViewerProductId),
        child: Text(
          'Mua một lần · ${_iap.localizedPriceFor(IAPService.multiViewerProductId) ?? '49.000đ'}',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _iap.isPurchasing
            ? null
            : () => _purchase(IAPService.premiumPlusProductId),
        child: Text(
          'Premium Plus · ${_iap.localizedPriceFor(IAPService.premiumPlusProductId) ?? '19.000đ/tháng'}',
        ),
      ),
      TextButton.icon(
        onPressed: _iap.isLoading ? null : _iap.restorePurchases,
        icon: const Icon(Icons.restore_rounded),
        label: const Text('Khôi phục giao dịch'),
        style: TextButton.styleFrom(foregroundColor: foregroundColor),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: roomSecondaryTextColor),
        child: const Text('Để sau'),
      ),
      if (_iap.statusMessage case final message?)
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: foregroundColor),
        ),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error ?? 'Không thể tải thông tin phòng.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: foregroundButtonColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              if (_roomCode case final roomCode?) {
                setState(() {
                  _error = null;
                  _roomStream = _repository.watchRoom(roomCode);
                });
              } else {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                unawaited(_createRoom());
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  String _formatJoinedAt(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Tham gia lúc $hour:$minute';
  }

  String _formatExpiry(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RoomErrorBanner extends StatelessWidget {
  const _RoomErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: negativeScoreBackgroundColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: negativeScoreColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: foregroundButtonColor, height: 1.35),
          ),
        ),
      ],
    ),
  );
}
