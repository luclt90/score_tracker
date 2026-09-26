import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/services/iap_service.dart';

import '../styles.dart';

class RemoveAdsOfferButton extends StatelessWidget {
  const RemoveAdsOfferButton({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    if (iap.isPurchased) return const SizedBox.shrink();

    final price = iap.localizedPrice ?? '29.000đ';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: iap.isLoading || iap.isPurchasing
                ? null
                : iap.purchaseRemoveAds,
            style: FilledButton.styleFrom(
              backgroundColor: backgroundButtonColorBlue,
              foregroundColor: foregroundButtonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: iap.isPurchasing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundButtonColor,
                    ),
                  )
                : const Icon(Icons.block_rounded),
            label: Text(
              'Xóa quảng cáo · $price',
              style: const TextStyle(
                fontFamily: fontFamilySFProText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (iap.statusMessage case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              iapMessageText(message),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: foregroundHintColor,
                fontFamily: fontFamilySFProText,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showRemoveAdsOfferDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: backgroundHeaderColor,
      title: const Text(
        'Xóa quảng cáo',
        style: TextStyle(
          color: foregroundButtonColor,
          fontFamily: fontFamilySFProText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mua một lần để tắt quảng cáo vĩnh viễn trên tài khoản Google Play này.',
            style: TextStyle(
              color: foregroundColor,
              fontFamily: fontFamilySFProText,
            ),
          ),
          SizedBox(height: 16),
          RemoveAdsOfferButton(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

String iapMessageText(String message) => switch (message) {
  'store_unavailable' =>
    'Google Play hiện không khả dụng. Hãy kiểm tra kết nối.',
  'product_not_found' => 'Không tìm thấy sản phẩm. Vui lòng thử lại sau.',
  'product_query_error' ||
  'network_error' => 'Lỗi kết nối. Hãy kiểm tra mạng và thử lại.',
  'purchase_not_started' ||
  'purchase_error' ||
  'purchase_stream_error' => 'Giao dịch chưa hoàn tất. Vui lòng thử lại.',
  'purchase_canceled' => 'Bạn đã hủy giao dịch.',
  'purchase_success' => 'Đã mua thành công. Quảng cáo đã được tắt.',
  'restore_success' => 'Đã khôi phục quyền lợi xóa quảng cáo.',
  'restore_requested' =>
    'Đã gửi yêu cầu khôi phục. Quyền lợi sẽ được cập nhật từ Google Play.',
  'restore_no_purchases' => 'Không tìm thấy giao dịch mua trên tài khoản này.',
  'restore_error' => 'Không thể khôi phục lúc này. Hãy thử lại sau.',
  _ => message,
};
