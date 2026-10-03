import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/domain/models/room.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';
import 'package:score_tracker/services/room_analytics_service.dart';

import '../styles.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  late final RoomRepository _repository;
  Stream<Room>? _roomStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _joinedRoomCode;
  String? _error;
  bool? _isOnline;
  bool _isJoining = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<RoomRepository>();
    _codeController.addListener(_onFormChanged);
    _nameController.addListener(_onFormChanged);
    unawaited(_checkConnectivity());
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivity,
    );
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkConnectivity() async {
    try {
      _updateConnectivity(await Connectivity().checkConnectivity());
    } catch (_) {
      if (mounted) setState(() => _isOnline = null);
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    if (mounted) {
      setState(() => _isOnline = !results.contains(ConnectivityResult.none));
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    if (code.length != 6 || name.isEmpty || _isJoining) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final viewerId = await _repository.currentUserId();
      await _repository.addViewer(
        roomCode: code,
        viewerId: viewerId,
        name: name,
      );
      await RoomAnalyticsService.logEvent('room_joined');
      await RoomAnalyticsService.logEvent('viewer_connected');
      if (!mounted) return;
      setState(() {
        _joinedRoomCode = code;
        _roomStream = _repository.watchRoom(code);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      _codeController.text = value.trim().toUpperCase();
      setState(() => _isScanning = false);
      return;
    }
  }

  Future<void> _leaveRoom() async {
    final code = _joinedRoomCode;
    if (code != null) {
      try {
        await _repository.removeViewer(
          roomCode: code,
          viewerId: await _repository.currentUserId(),
        );
        await RoomAnalyticsService.logEvent('viewer_disconnected');
      } catch (_) {
        // RTDB onDisconnect removes presence when an explicit leave cannot reach it.
      }
    }
    if (!mounted) return;
    setState(() {
      _joinedRoomCode = null;
      _roomStream = null;
      _error = null;
    });
  }

  String _errorMessage(Object error) => switch (error) {
    RoomRepositoryException(:final code) => switch (code) {
      'room_full' => 'Phòng đã đủ 10 người xem.',
      'room_not_found' => 'Không tìm thấy phòng.',
      'room_ended' => 'Phòng đã kết thúc hoặc hết hạn.',
      'anonymous_auth_disabled' =>
        'Firebase Anonymous Authentication chưa được bật.',
      'network_unavailable' => 'Không có kết nối đến Firebase. Hãy thử lại.',
      'firebase_not_initialized' =>
        'Firebase chưa được cấu hình cho ứng dụng này.',
      _ => 'Không thể tham gia phòng. Hãy thử lại.',
    },
    _ => 'Không thể kết nối. Hãy kiểm tra mã phòng và mạng.',
  };

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _codeController
      ..removeListener(_onFormChanged)
      ..dispose();
    _nameController
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: roomExperienceTheme(context),
    child: Scaffold(
      appBar: AppBar(
        title: Text(_roomStream == null ? 'Tham gia phòng' : 'Điểm trực tiếp'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _roomStream == null ? _buildJoinForm() : _buildScoreboard(),
    ),
  );

  Widget _buildJoinForm() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      if (_isOnline == false)
        const _RoomStatusBanner(
          text: 'Không có kết nối mạng.',
          icon: Icons.wifi_off_rounded,
        ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundHeaderColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            _FeatureIcon(icon: Icons.scoreboard_rounded),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xem điểm cùng mọi người',
                    style: TextStyle(
                      color: foregroundButtonColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nhập mã phòng hoặc quét mã QR để tham gia.',
                    style: TextStyle(color: foregroundColor, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const _FieldLabel('MÃ PHÒNG'),
      const SizedBox(height: 8),
      if (_isScanning) ...[
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(onDetect: _onBarcodeDetected),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đưa mã QR vào khung hình để quét.',
          textAlign: TextAlign.center,
          style: TextStyle(color: foregroundColor),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _codeController,
        style: const TextStyle(
          color: foregroundButtonColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          hintText: 'ABC234',
          hintStyle: const TextStyle(
            color: roomSecondaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(Icons.tag_rounded),
          suffixIcon: IconButton(
            tooltip: _isScanning ? 'Đóng máy quét' : 'Quét mã QR',
            onPressed: () => setState(() => _isScanning = !_isScanning),
            icon: Icon(
              _isScanning ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${_codeController.text.length}/6 ký tự',
          style: const TextStyle(color: roomSecondaryTextColor, fontSize: 12),
        ),
      ),
      const SizedBox(height: 20),
      const _FieldLabel('TÊN HIỂN THỊ'),
      const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        style: const TextStyle(color: foregroundButtonColor, fontSize: 16),
        textCapitalization: TextCapitalization.words,
        maxLength: 32,
        decoration: const InputDecoration(
          hintText: 'Tên bạn bè sẽ nhìn thấy',
          prefixIcon: Icon(Icons.person_outline_rounded),
          counterText: '',
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        _ErrorBanner(message: _error!),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed:
            _isJoining ||
                _codeController.text.length != 6 ||
                _nameController.text.trim().isEmpty
            ? null
            : _joinRoom,
        icon: _isJoining
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundButtonColor,
                ),
              )
            : const Icon(Icons.login_rounded),
        label: const Text('Vào phòng'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => setState(() => _isScanning = !_isScanning),
        icon: Icon(
          _isScanning ? Icons.keyboard_rounded : Icons.qr_code_scanner_rounded,
        ),
        label: Text(_isScanning ? 'Nhập mã phòng' : 'Quét mã QR'),
      ),
    ],
  );

  Widget _buildScoreboard() => StreamBuilder<Room>(
    stream: _roomStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _ErrorBanner(message: _errorMessage(snapshot.error!)),
          ),
        );
      }
      final room = snapshot.data;
      if (room == null) return const Center(child: CircularProgressIndicator());

      final isEnded = !room.isJoinableAt(DateTime.now().toUtc());
      return Column(
        children: [
          if (_isOnline == false)
            const _RoomStatusBanner(
              text: 'Ngoại tuyến · đang hiển thị dữ liệu đã lưu.',
              icon: Icons.wifi_off_rounded,
            ),
          if (isEnded)
            const _RoomStatusBanner(
              text: 'Phòng này đã kết thúc.',
              icon: Icons.event_busy_rounded,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: backgroundHeaderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BẢNG ĐIỂM TRỰC TIẾP',
                        style: TextStyle(
                          color: roomSecondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Phòng ${room.code}',
                        style: const TextStyle(
                          color: foregroundButtonColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel('TỔNG ĐIỂM'),
                const SizedBox(height: 8),
                ...room.players.map((player) {
                  final score = room.scores[player.id] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundHeaderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: foregroundButtonColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$score',
                          style: TextStyle(
                            color: score < 0
                                ? negativeScoreColor
                                : foregroundButtonColor,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                const _FieldLabel('CHI TIẾT CÁC VÒNG'),
                if (room.rounds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Chưa có vòng điểm nào.',
                      style: TextStyle(color: foregroundColor),
                    ),
                  ),
                for (final round in room.rounds.reversed) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    decoration: BoxDecoration(
                      color: backgroundHeaderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vòng ${round.index}',
                          style: const TextStyle(
                            color: foregroundButtonColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final player in room.players)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    player.name,
                                    style: const TextStyle(
                                      color: foregroundColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${round.scores[player.id] ?? '–'}',
                                  style: const TextStyle(
                                    color: foregroundButtonColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (round.editedPlayerIds.contains(player.id))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: backgroundButtonColorBlue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _leaveRoom,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Rời phòng'),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: backgroundButtonColorBlue.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: foregroundButtonColor),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: roomSecondaryTextColor,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _RoomStatusBanner extends StatelessWidget {
  const _RoomStatusBanner({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: negativeScoreBackgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: negativeScoreColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: foregroundButtonColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
