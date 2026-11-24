import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  UserProfile? _profile = UserService.instance.cachedUser;

  int _adCount = 0;
  int _nextAdResetTime = 0;
  bool _isAdLoading = false;
  bool _isPurchasing = false;

  final List<Map<String, dynamic>> _avatarCategories = [
    {
      'title': 'Hayvanlar Alemi',
      'items': [
        {'id': 'shark', 'price': 250, 'name': 'Köpekbalığı'},
        {'id': 'bee', 'price': 250, 'name': 'Arı'},
        {'id': 'turtle', 'price': 250, 'name': 'Kaplumbağa'},
        {'id': 'chick', 'price': 250, 'name': 'Civciv'},
        {'id': 'dog', 'price': 250, 'name': 'Köpek'},
        {'id': 'kitty', 'price': 250, 'name': 'Kedi'},
        {'id': 'kitty-1', 'price': 250, 'name': 'Zeki Kedi'},
      ]
    },
    {
      'title': 'Fantastik & Macera',
      'items': [
        {'id': 'knight', 'price': 250, 'name': 'Şövalye'},
        {'id': 'swordsman', 'price': 250, 'name': 'Savaşçı'},
        {'id': 'wizard', 'price': 250, 'name': 'Büyücü'},
        {'id': 'magician', 'price': 250, 'name': 'Sihirbaz'},
        {'id': 'hacker', 'price': 250, 'name': 'Hacker'},
      ]
    },
    {
      'title': 'Meslekler & İnsanlar',
      'items': [
        {'id': 'freelance', 'price': 250, 'name': 'Freelancer'},
        {'id': 'manager', 'price': 250, 'name': 'Yönetici'},
        {'id': 'tax-inspector', 'price': 250, 'name': 'Müfettiş'},
        {'id': 'graduate', 'price': 250, 'name': 'Mezun'},
        {'id': 'graduate-1', 'price': 250, 'name': 'Kep Atan'},
        {'id': 'muslim', 'price': 250, 'name': 'Tesettürlü'},
        {'id': 'girl1', 'price': 250, 'name': 'Neşeli Kız'},
        {'id': 'girl-2', 'price': 250, 'name': 'Gözlüklü Kız'},
        {'id': 'children', 'price': 250, 'name': 'Sevgililer'},
      ]
    },
  ];

  final List<Map<String, dynamic>> _premiumBorders = [
    {'id': 'border_arcane', 'price': 750, 'name': 'Gizemli'},
    {'id': 'border_bronze', 'price': 750, 'name': 'Bronz'},
    {'id': 'border_champion', 'price': 750, 'name': 'Şampiyon'},
    {'id': 'border_diamond', 'price': 750, 'name': 'Elmas'},
    {'id': 'border_epic', 'price': 750, 'name': 'Destansı'},
    {'id': 'border_fire', 'price': 750, 'name': 'Alevli'},
    {'id': 'border_forest', 'price': 750, 'name': 'Orman'},
    {'id': 'border_gold', 'price': 750, 'name': 'Altın'},
    {'id': 'border_halloween', 'price': 750, 'name': 'Korkunç'},
    {'id': 'border_holy', 'price': 750, 'name': 'Kutsal'},
    {'id': 'border_ice', 'price': 750, 'name': 'Buzul'},
    {'id': 'border_legendary', 'price': 750, 'name': 'Efsanevi'},
    {'id': 'border_love', 'price': 750, 'name': 'Aşk'},
    {'id': 'border_mythic', 'price': 750, 'name': 'Mistik'},
    {'id': 'border_nature', 'price': 750, 'name': 'Doğa'},
    {'id': 'border_ninja', 'price': 750, 'name': 'Ninja'},
    {'id': 'border_pirate', 'price': 750, 'name': 'Korsan'},
    {'id': 'border_royal', 'price': 750, 'name': 'Kraliyet'},
    {'id': 'border_shadow', 'price': 750, 'name': 'Gölge'},
    {'id': 'border_silver', 'price': 750, 'name': 'Gümüş'},
    {'id': 'border_space', 'price': 750, 'name': 'Uzay'},
    {'id': 'border_steampunk', 'price': 750, 'name': 'Steampunk'},
    {'id': 'border_steel', 'price': 750, 'name': 'Çelik'},
    {'id': 'border_sun', 'price': 750, 'name': 'Güneş'},
    {'id': 'border_tech', 'price': 750, 'name': 'Teknoloji'},
    {'id': 'border_unicorn', 'price': 750, 'name': 'Tekboynuz'},
    {'id': 'border_water', 'price': 750, 'name': 'Su'},
    {'id': 'border_winter', 'price': 750, 'name': 'Kış'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.instance.getCurrentUser().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException("Mağaza: UserService yanıt vermedi"),
      );

      final adStatus = await UserService.instance.getAdRewardStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () => {'count': 0, 'nextReset': 0},
      );

      if (mounted) {
        setState(() {
          _profile = profile;
          _adCount = adStatus['count'] as int;
          _nextAdResetTime = adStatus['nextReset'] as int;
        });
      }
    } catch (e) {
      debugPrint("Mağaza profil yükleme hatası: $e");
      if (mounted && _profile == null) {
        _showError('Mağaza yüklenirken bağlantı sorunu oluştu.');
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AudioService.instance.playError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AudioService.instance.playSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF00CEC9)),
    );
  }

  void _watchAd() {
    if (_isAdLoading || _adCount >= 2) return;

    AudioService.instance.playClick();
    setState(() => _isAdLoading = true);

    AdService.instance.showRewardedAd(
      onRewardEarned: () async {
        bool success = await UserService.instance.watchAdAndClaimReward();
        if (mounted) {
          setState(() => _isAdLoading = false);
          if (success) {
            _showSuccess('Tebrikler! 25 Cevher kazandın.');
            _loadProfile();
          } else {
            _showError('Ödül hakkı dolmuş veya doğrulanamadı.');
          }
        }
      },
      onDismissedWithoutReward: () {
        if (mounted) {
          setState(() => _isAdLoading = false);
          _showError('Ödül kazanmak için reklamı sonuna kadar izlemelisin.');
        }
      },
      onAdFailed: () {
        if (mounted) {
          setState(() => _isAdLoading = false);
          _showError('Reklam henüz hazır değil. İnternetini kontrol edip biraz bekle.');
        }
      },
    );
  }

  String _getRemainingTimeText() {
    int now = DateTime.now().millisecondsSinceEpoch;
    int diff = _nextAdResetTime - now;
    if (diff <= 0) return "Şimdi izleyebilirsin!";
    int hours = diff ~/ (1000 * 60 * 60);
    int minutes = (diff % (1000 * 60 * 60)) ~/ (1000 * 60);
    return "Yenilenme: ${hours}s ${minutes}dk";
  }

  void _showPurchaseConfirmDialog({
    required String itemName,
    required int price,
    required bool isAvatar,
    required Map<String, dynamic> item,
  }) {
    if (_isPurchasing) return;
    AudioService.instance.playClick();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF00CEC9)),
            SizedBox(width: 8),
            Text('Satın Almayı Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          '"$itemName" öğesini $price Cevher karşılığında satın almak istiyor musunuz?',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.pop(dialogContext);
            },
            child: const Text('İptal', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CEC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (isAvatar) {
                await _executeBuyOrEquipAvatar(item);
              } else {
                await _executeBuyOrEquipBorder(item);
              }
            },
            child: const Text('Satın Al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _buyOrEquipAvatar(Map<String, dynamic> item) async {
    if (_profile == null || _isPurchasing) return;
    String avatarId = item['id'];

    if (_profile!.purchasedAvatars.contains(avatarId)) {
      await UserService.instance.updateAvatar(avatarId);
      _showSuccess('Karakter başarıyla kuşanıldı!');
      _loadProfile();
    } else {
      _showPurchaseConfirmDialog(
        itemName: item['name'],
        price: item['price'],
        isAvatar: true,
        item: item,
      );
    }
  }

  Future<void> _executeBuyOrEquipAvatar(Map<String, dynamic> item) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      String avatarId = item['id'];
      // buyAvatar artık atomik olarak hem satın alır hem de kuşanır
      bool success = await UserService.instance.buyAvatar(avatarId);
      if (success) {
        _showSuccess('Karakter satın alındı ve kuşanıldı!');
      } else {
        _showError('Yetersiz Cevher veya bağlantı hatası!');
      }
      await _loadProfile();
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _buyOrEquipBorder(Map<String, dynamic> item) async {
    if (_profile == null || _isPurchasing) return;
    String borderId = item['id'];

    if (_profile!.purchasedBorders.contains(borderId)) {
      await UserService.instance.setBorder(borderId);
      _showSuccess('Çerçeve başarıyla kuşanıldı!');
      _loadProfile();
    } else {
      _showPurchaseConfirmDialog(
        itemName: item['name'],
        price: item['price'],
        isAvatar: false,
        item: item,
      );
    }
  }

  Future<void> _executeBuyOrEquipBorder(Map<String, dynamic> item) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      String borderId = item['id'];
      // buyBorder artık atomik olarak hem satın alır hem de kuşanır
      bool success = await UserService.instance.buyBorder(borderId);
      if (success) {
        _showSuccess('Çerçeve satın alındı ve kuşanıldı!');
      } else {
        _showError('Yetersiz Cevher veya bağlantı hatası!');
      }
      await _loadProfile();
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _unequipBorder() async {
    await UserService.instance.setBorder('none');
    _showSuccess('Çerçeve çıkarıldı.');
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mağaza', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1B36),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_rounded, color: Color(0xFF00CEC9), size: 14),
                    const SizedBox(width: 4),
                    Text('${_profile?.gems ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00CEC9),
            indicatorWeight: 3,
            labelColor: Color(0xFF00CEC9),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Özel Karakterler'),
              Tab(text: 'Çerçeveler'),
            ],
          ),
        ),
        body: _profile == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFC)))
            : Column(
                children: [
                  _buildAdBanner(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAvatarsTab(),
                        _buildBordersTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdBanner() {
    bool canWatch = _adCount < 2;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00CEC9).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ücretsiz Cevher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(canWatch ? 'Reklam izle, 25 cevher kazan!' : _getRemainingTimeText(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                const SizedBox(height: 4),
                Text('İzlenen: $_adCount/2', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canWatch ? Colors.amber : Colors.white24,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: (_isAdLoading || !canWatch) ? null : _watchAd,
            child: _isAdLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                : Text(canWatch ? 'İZLE' : 'BEKLE', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: _avatarCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = _avatarCategories[categoryIndex];
        final List<Map<String, dynamic>> items = category['items'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                category['title'],
                style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isOwned = _profile!.purchasedAvatars.contains(item['id']);
                final bool isEquipped = _profile!.avatar == item['id'];

                return _buildStoreCard(
                  iconWidget: Image.asset('assets/avatars/${item['id']}.png', height: 65),
                  title: item['name'],
                  price: item['price'],
                  isOwned: isOwned,
                  isEquipped: isEquipped,
                  onTap: () => _buyOrEquipAvatar(item),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBordersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_profile!.selectedBorder != 'none')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
              ),
              onPressed: _unequipBorder,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text('Çerçeveyi Çıkar'),
            ),
          ),
        ..._premiumBorders.map((item) {
          final bool isOwned = _profile!.purchasedBorders.contains(item['id']);
          final bool isEquipped = _profile!.selectedBorder == item['id'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStoreCard(
              iconWidget: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF131127),
                    backgroundImage: AssetImage('assets/avatars/${_profile!.avatar}.png'),
                  ),
                  Image.asset(
                    'assets/borders/${item['id']}.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              title: item['name'],
              price: item['price'],
              isOwned: isOwned,
              isEquipped: isEquipped,
              onTap: () => _buyOrEquipBorder(item),
              isHorizontal: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStoreCard({
    required Widget iconWidget,
    required String title,
    required int price,
    required bool isOwned,
    required bool isEquipped,
    required VoidCallback onTap,
    bool isHorizontal = false,
  }) {
    final content = [
      iconWidget,
      if (!isHorizontal) const SizedBox(height: 16) else const SizedBox(width: 16),
      Expanded(
        flex: isHorizontal ? 1 : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: isHorizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (isEquipped)
              const Text('Kuşanıldı', style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold))
            else if (isOwned)
              const Text('Sahipsin', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisAlignment: isHorizontal ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Text('$price', style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.diamond_rounded, color: Color(0xFF00CEC9), size: 16),
                ],
              ),
          ],
        ),
      ),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEquipped ? const Color(0xFF00CEC9).withValues(alpha: 0.1) : const Color(0xFF1D1B36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isEquipped ? const Color(0xFF00CEC9) : Colors.white.withValues(alpha: 0.05), width: isEquipped ? 2 : 1),
        ),
        child: isHorizontal ? Row(children: content) : Column(mainAxisAlignment: MainAxisAlignment.center, children: content),
      ),
    );
  }
}