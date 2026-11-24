import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GameIntroDialog extends StatefulWidget {
  final bool isTimed;
  final String subMode; 
  final VoidCallback onStartGame;

  const GameIntroDialog({
    super.key,
    required this.isTimed,
    required this.subMode,
    required this.onStartGame,
  });

  @override
  State<GameIntroDialog> createState() => _GameIntroDialogState();
}

class _GameIntroDialogState extends State<GameIntroDialog> {
  bool _isCountingDown = false;
  int _count = 3;
  Timer? _timer;

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 1) {
        setState(() {
          _count--;
        });
      } else {
        _timer?.cancel();
        Navigator.pop(context); 
        widget.onStartGame(); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isCountingDown ? _buildCountdownUI() : _buildRulesUI(context),
      ),
    );
  }

  Widget _buildCountdownUI() {
    return Container(
      key: const ValueKey('countdown'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'OYUN BAŞLIYOR',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Text(
              '$_count',
              key: ValueKey(_count),
              style: const TextStyle(
                color: AppColors.rose,
                fontSize: 90,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesUI(BuildContext context) {
    return Container(
      key: const ValueKey('rules'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isTimed ? Icons.timer : Icons.all_inclusive,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          Text(
            _getDescription(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          if (widget.isTimed) _buildRewardTable(),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _startCountdown,
              child: const Text(
                'ANLADIM, BAŞLA!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    String modeName = widget.isTimed ? 'Zamana Karşı' : 'Sonsuz Macera';
    String subName = widget.subMode == 'word'
        ? 'Bir Kelime'
        : widget.subMode == 'math'
            ? 'Bir İşlem'
            : 'Bir Kelime Bir İşlem';
    return '$modeName\n($subName)';
  }

  String _getDescription() {
    if (!widget.isTimed) {
      return 'Süre kısıtı veya stres yok! İstediğin kadar düşün, en uzun kelimeleri türet veya en kısa matematik yolunu keşfet. Takıldığın yerde çözümü görebilirsin.';
    }

    if (widget.subMode == 'word') {
      return 'Süre bitene kadar harflerle en uzun Türkçe kelimeleri bul! Doğru kelimeler sürene ek saniyeler kazandırır ve serini devam ettirir.';
    } else if (widget.subMode == 'math') {
      return 'Verilen 6 sayıyı kullanarak hedef sayıya ulaş veya en yakın değere yaklaş! Tam isabet dev süre bonusu kazandırır.';
    } else {
      return 'Klasik Karma Yarışma! Kelime ve İşlem turları sırayla gelir. Doğru cevaplar süreni uzatır, süre bitene kadar akış kesintisiz devam eder!';
    }
  }

  Widget _buildRewardTable() {
    if (widget.subMode == 'word') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: const [
            _TableRow(left: '1 Harf', right: 'Süre Vermez'),
            SizedBox(height: 6),
            _TableRow(left: '2 - 6 Harf', right: '+Harf Sayısı Süre & Puan'),
            SizedBox(height: 6),
            _TableRow(
              left: '7 - 8 Harf',
              right: '+2x Süre & Puan + 5 Ekstra Bonus!',
              highlight: true,
            ),
          ],
        ),
      );
    } else if (widget.subMode == 'math') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: const [
            _TableRow(left: 'Tam Hedef (Δ=0)', right: '+5s Süre Bonusu'),
            SizedBox(height: 6),
            _TableRow(left: 'Yaklaşım (±1..±10)', right: 'Sadece Puan Kazandırır'),
            SizedBox(height: 6),
            _TableRow(
              left: 'Artan Her Sayı',
              right: '+2s ve +2 Puan Ekstra Ödül!',
              highlight: true,
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: const [
            _TableRow(left: 'Kelime Turu', right: 'Uzun kelimelere 2x Süre Ödülü'),
            SizedBox(height: 6),
            _TableRow(left: 'İşlem Turu', right: 'Tam isabet ve Artan Sayı Bonusu'),
          ],
        ),
      );
    }
  }
}

class _TableRow extends StatelessWidget {
  final String left;
  final String right;
  final bool highlight;

  const _TableRow({
    required this.left,
    required this.right,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: TextStyle(
            color: highlight ? AppColors.rose : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          right,
          style: TextStyle(
            color: highlight ? AppColors.rose : Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}