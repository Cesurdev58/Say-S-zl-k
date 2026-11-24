import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/word_service.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String _loadingText = "Sistem hazırlanıyor...";
  bool _isLoadingComplete = false;

  @override
  void initState() {
    super.initState();
    _startLoadingProcess();
  }

  Future<void> _startLoadingProcess() async {
    // 1. Aşama: Başlangıç
    await Future.delayed(const Duration(milliseconds: 500));
    _updateProgress(0.3, "Sözlük veritabanı yükleniyor...");
    await WordService.instance.loadOfflineDictionary();

    // 2. Aşama: Oturum Kontrolü
    await Future.delayed(const Duration(milliseconds: 600));
    _updateProgress(0.7, "Oturum durumu kontrol ediliyor...");

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ZATEN GİRİŞ YAPILMIŞ (Anonim veya Kayıtlı)
      _updateProgress(0.9, "Profil senkronize ediliyor...");
      try {
        await UserService.instance.getCurrentUser();
      } catch (e) {
        debugPrint("Kullanıcı yüklenirken hata: $e");
      }

      _updateProgress(1.0, "Hazır!");
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      // İLK DEFA GİREN VEYA ÇIKIŞ YAPMIŞ KULLANICI
      _updateProgress(1.0, "Giriş yapmanız bekleniyor.");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoadingComplete = true;
        });
      }
    }
  }

  void _updateProgress(double targetProgress, String text) {
    if (mounted) {
      setState(() {
        _progress = targetProgress;
        _loadingText = text;
      });
    }
  }

  // "Misafir Olarak Oyna" butonuna tıklandığında Anonim Hesap oluşturulur
  Future<void> _startAsGuest() async {
    AudioService.instance.playClick();

    setState(() {
      _isLoadingComplete = false;
      _progress = 0.8;
      _loadingText = "Misafir profili oluşturuluyor...";
    });

    try {
      await UserService.instance.getCurrentUser();

      _updateProgress(1.0, "Profil oluşturuldu, oyuna geçiliyor!");
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      debugPrint("Misafir girişi hatası: $e");
      if (mounted) {
        setState(() {
          _isLoadingComplete = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı hatası, tekrar deneyin.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Giriş/Kayıt butonuna tıklandığında çalışan AuthScreen yönlendirmesi
  void _goToAuthScreen() {
    AudioService.instance.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onProfileUpdated: () {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _isLoadingComplete ? _buildActionButtons() : _buildProgressBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      key: const ValueKey("buttons"),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            onPressed: _goToAuthScreen,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Kayıt Ol / Giriş Yap', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00CEC9), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF131127).withValues(alpha: 0.8),
            ),
            onPressed: _startAsGuest,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_esports_rounded, color: Color(0xFF00CEC9)),
                SizedBox(width: 12),
                Text('Misafir Olarak Oyna', style: TextStyle(color: Color(0xFF00CEC9), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      key: const ValueKey("progress_bar"),
      children: [
        Text(
          _loadingText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF131127).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black87, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * _progress,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CEC9), Color(0xFF7C5CFC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Center(
                    child: Text(
                      '%${(_progress * 100).toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}