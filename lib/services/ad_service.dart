import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _initialized = false;
  bool _isLoadingRewarded = false;
  bool _isLoadingInterstitial = false;
  bool _isShowingRewarded = false;
  bool _isShowingInterstitial = false;

  int _rewardedRetryAttempt = 0;
  int _interstitialRetryAttempt = 0;
  Timer? _rewardedRetryTimer;
  Timer? _interstitialRetryTimer;

  bool get isRewardedLoaded => _rewardedAd != null && !_isShowingRewarded;
  bool get isInterstitialLoaded => _interstitialAd != null && !_isShowingInterstitial;

  // Debug modunda banlanmayı önlemek için resmi test ID'leri, release derlemesinde canlı ID kullanılır
  String get _rewardedUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-2560759171234960/2420324329'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  String get _interstitialUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-2560759171234960/4571115994'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    if (_isLoadingRewarded || _rewardedAd != null || _isShowingRewarded) return;
    _isLoadingRewarded = true;
    _rewardedRetryTimer?.cancel();

    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          _rewardedRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad load failed: $error');
          _rewardedAd = null;
          _isLoadingRewarded = false;
          _scheduleRewardedRetry();
        },
      ),
    );
  }

  void _scheduleRewardedRetry() {
    _rewardedRetryAttempt++;
    final int delaySec = (_rewardedRetryAttempt <= 4) ? (1 << _rewardedRetryAttempt) : 30;
    _rewardedRetryTimer?.cancel();
    _rewardedRetryTimer = Timer(Duration(seconds: delaySec), _loadRewardedAd);
  }

  void showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdFailed,
    VoidCallback? onDismissedWithoutReward,
  }) {
    if (_isShowingRewarded || _rewardedAd == null) {
      _loadRewardedAd();
      onAdFailed();
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    _isShowingRewarded = true;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingRewarded = false;
        _loadRewardedAd();
        if (!earned) {
          onDismissedWithoutReward?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        shownAd.dispose();
        _isShowingRewarded = false;
        _loadRewardedAd();
        onAdFailed();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView shownAd, RewardItem reward) {
        if (earned) return;
        earned = true;
        onRewardEarned();
      },
    );
  }

  void _loadInterstitialAd() {
    if (_isLoadingInterstitial || _interstitialAd != null || _isShowingInterstitial) return;
    _isLoadingInterstitial = true;
    _interstitialRetryTimer?.cancel();

    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          _interstitialRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad load failed: $error');
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  void _scheduleInterstitialRetry() {
    _interstitialRetryAttempt++;
    final int delaySec = (_interstitialRetryAttempt <= 4) ? (1 << _interstitialRetryAttempt) : 30;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = Timer(Duration(seconds: delaySec), _loadInterstitialAd);
  }

  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (_isShowingInterstitial || _interstitialAd == null) {
      _loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _isShowingInterstitial = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingInterstitial = false;
        _loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        shownAd.dispose();
        _isShowingInterstitial = false;
        _loadInterstitialAd();
        onDismissed?.call();
      },
    );

    ad.show();
  }
}