import 'dart:io';

class AdManager {
  static String get appId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4811795096615517~2538769940";
    } else if (Platform.isIOS) {
      return "Unsupported platform";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4811795096615517/9399707676";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_BANNER_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

//Banner ad show at add player screen
  static String get bannerAdUnitAddPlayerId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4811795096615517/1864739646";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_BANNER_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitSelectPlayerId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4811795096615517/7567943729";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_BANNER_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4811795096615517/8274328260";
    } else if (Platform.isIOS) {
      return "Unsupported platform";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitIdTest {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/6300978111";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_BANNER_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitIdTest {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/1033173712";
    } else if (Platform.isIOS) {
      return "Unsupported platform";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // static String get rewardedAdUnitId {
  //   if (Platform.isAndroid) {
  //     return "<YOUR_ANDROID_REWARDED_AD_UNIT_ID>";
  //   } else if (Platform.isIOS) {
  //     return "Unsupported platform";
  //   } else {
  //     throw new UnsupportedError("Unsupported platform");
  //   }
  // }
}
