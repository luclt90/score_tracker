import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/services/iap_service.dart';
import 'package:score_tracker/widgets/remove_ads_offer.dart';

import '../styles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (iap.isPurchased)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_rounded, color: Colors.green),
              title: Text(
                'Đã bật chế độ không quảng cáo',
                style: TextStyle(
                  color: foregroundButtonColor,
                  fontFamily: fontFamilySFProText,
                ),
              ),
            )
          else
            const RemoveAdsOfferButton(),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore_rounded, color: foregroundColor),
            title: const Text(
              'Khôi phục giao dịch mua',
              style: TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Dùng tài khoản Google Play đã mua trước đây.',
              style: TextStyle(
                color: foregroundHintColor,
                fontFamily: fontFamilySFProText,
              ),
            ),
            onTap: iap.isLoading ? null : iap.restorePurchases,
          ),
          if (iap.statusMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                iapMessageText(message),
                style: const TextStyle(
                  color: foregroundHintColor,
                  fontFamily: fontFamilySFProText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
