import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/game_background.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const AuthScreen({super.key, required this.onProfileUpdated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isVerificationPending = false;

  bool _isPasswordVisible = false;

  bool _hasMinLength = false;
  bool _hasUpperLower = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  // YENİ: Kullanıcının e-postasını onaylayıp onaylamadığını arka planda otomatik kontrol eden zamanlayıcı
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous && !user.emailVerified) {
      await user.reload().catchError((e) {});
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null && !updatedUser.emailVerified && mounted) {
        setState(() {
          _isVerificationPending = true;
        });
        _startAutoVerificationCheck();
      }
    }
  }

  // YENİ: Her 3 saniyede bir e-posta doğrulandı mı diye bakar, doğrulandıysa otomatik oyuna sokar
  void _startAutoVerificationCheck() {
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_isVerificationPending) {
        timer.cancel();
        return;
      }
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.emailVerified) {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('E-posta doğrulandı! Oyuna yönlendiriliyorsunuz...'),
                backgroundColor: Colors.green,
              ),
            );
            widget.onProfileUpdated();
          }
        }
      } catch (e) {
        // Yoklama hatası yok sayılır; bir sonraki turda tekrar denenir.
      }
    });
  }

  void _checkPasswordStrength(String pass) {
    setState(() {
      _hasMinLength = pass.length >= 6;
      _hasUpperLower = RegExp(r'(?=.*[A-ZÇĞİÖŞÜ])(?=.*[a-zçğıöşü])').hasMatch(pass);
      _hasNumber = RegExp(r'(?=.*[0-9])').hasMatch(pass);
      _hasSymbol = RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ\s]').hasMatch(pass);
    });
  }

  bool get _isPasswordValid => _hasMinLength && _hasUpperLower && _hasNumber && _hasSymbol;

  String _getFormattedEmail() {
    return _emailController.text.trim().toLowerCase().replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            AudioService.instance.playClick();
            Navigator.pop(context);
          },
        ),
        title: const Text('Hesap Güvenliği', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _isVerificationPending ? _buildVerificationUI() : _buildAuthUI(),
        ),
      ),
    ));
  }

  Widget _buildVerificationUI() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_unread_rounded, color: Colors.orangeAccent, size: 80),
        const SizedBox(height: 24),
        const Text('E-posta Onayı Bekleniyor', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
          'Hesabınız bağlandı ancak güvenliğiniz için e-postanızı doğrulamanız gerekiyor. Lütfen gelen kutunuzu (ve Spam klasörünü) kontrol edip onay linkine tıklayın.\n\nLinke tıkladığınızda bu ekran otomatik olarak geçecektir.',
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator(color: Colors.orangeAccent)
            : SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await FirebaseAuth.instance.currentUser?.reload();
                    } catch (e) {
                      // reload başarısız olsa da mevcut kullanıcı bilgisiyle devam edilir.
                    }
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null && user.emailVerified) {
                      _verificationCheckTimer?.cancel();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('E-posta başarıyla doğrulandı! Hesabınız tamamen güvende.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        widget.onProfileUpdated();
                      }
                    } else {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Henüz onaylanmamış. Lütfen maildeki linke tıkladığınızdan emin olun.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Onayladım, Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.currentUser?.sendEmailVerification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi!'), backgroundColor: Colors.green),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen tekrar göndermeden önce biraz bekleyin.'), backgroundColor: Colors.orange),
                );
              }
            }
          },
          child: const Text('Mail Gelmedi Mi? Tekrar Gönder', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
        ),
        const Divider(color: Colors.white12, height: 40),
        TextButton(
          onPressed: () async {
            _verificationCheckTimer?.cancel();
            setState(() => _isLoading = true);
            await UserService.instance.forceSignOutAndMakeAnon();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Giriş iptal edildi, yeni hesaba geçildi.'), backgroundColor: Colors.orange),
              );
            }
          },
          child: const Text('İptal Et / Başka Hesaba Geç', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildAuthUI() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioService.instance.playClick();
                    setState(() => _isLoginMode = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLoginMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'GİRİŞ YAP',
                        style: TextStyle(color: _isLoginMode ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioService.instance.playClick();
                    setState(() {
                      _isLoginMode = false;
                      _checkPasswordStrength(_passwordController.text);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isLoginMode ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'YENİ KAYIT',
                        style: TextStyle(color: !_isLoginMode ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Icon(
          _isLoginMode ? Icons.login_rounded : Icons.security_rounded,
          color: _isLoginMode ? AppColors.primary : AppColors.accent,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          _isLoginMode ? 'Mevcut Hesaba Giriş' : 'Hesabını Güvenceye Al',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? 'Daha önceden kaydettiğin e-posta ile kaldığın yerden devam et.'
              : 'Verilerinin kaybolmaması için yeni bir şifre ve e-posta belirle.',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'E-posta Adresi',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.email_rounded, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          obscureText: !_isPasswordVisible,
          onChanged: (val) {
            if (!_isLoginMode) _checkPasswordStrength(val);
          },
          decoration: InputDecoration(
            hintText: 'Şifre',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white54),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
        if (_isLoginMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final email = _getFormattedEmail();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifrenizi sıfırlamak için yukarıya e-posta adresinizi yazın.'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (!email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-posta adresinde "@" işareti eksik! (Örn: isim@gmail.com)'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sıfırlama bağlantısı e-postanıza gönderildi! Lütfen kontrol edin.'), backgroundColor: Colors.green),
                    );
                  }
                }).catchError((e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('E-posta adresi sistemde bulunamadı veya geçersiz.'), backgroundColor: Colors.redAccent),
                    );
                  }
                });
              },
              child: const Text('Şifremi Unuttum?', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
          ),
        if (!_isLoginMode) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildPasswordBar(_hasMinLength, '6+ Karakter')),
              const SizedBox(width: 8),
              Expanded(child: _buildPasswordBar(_hasUpperLower, 'Büyük/Küçük')),
              const SizedBox(width: 8),
              Expanded(child: _buildPasswordBar(_hasNumber, 'Rakam')),
              const SizedBox(width: 8),
              Expanded(child: _buildPasswordBar(_hasSymbol, 'Sembol')),
            ],
          ),
        ],
        const SizedBox(height: 40),
        _isLoading
            ? CircularProgressIndicator(color: _isLoginMode ? AppColors.primary : AppColors.accent)
            : SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoginMode
                        ? AppColors.primary
                        : ((!_isLoginMode && !_isPasswordValid) ? Colors.grey : AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitAuth,
                  child: Text(
                    _isLoginMode ? 'Giriş Yap ve Verileri Yükle' : 'Kaydet ve Güvenceye Al',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPasswordBar(bool isMet, String label) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 6,
          decoration: BoxDecoration(
            color: isMet ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isMet ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 4)] : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isMet ? Colors.greenAccent : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    );
  }

  Future<void> _submitAuth() async {
    final email = _getFormattedEmail();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir e-posta adresi girin (Örn: isim@gmail.com).'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen şifrenizi girin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_isLoginMode && !_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz en az 6 karakter olmalı; büyük/küçük harf, rakam ve sembol içermelidir.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await UserService.instance.linkOrLoginAccount(email, password, true);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();
          } catch (e) {
            debugPrint("Doğrulama maili gönderme uyarısı: $e");
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isVerificationPending = true;
            });
            _startAutoVerificationCheck();
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş başarılı! Profiliniz yükleniyor...'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        }
      } else {
        await UserService.instance.linkOrLoginAccount(email, password, false);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();
          } catch (e) {
            debugPrint("Doğrulama maili gönderme uyarısı: $e");
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isVerificationPending = true;
            });
            _startAutoVerificationCheck();
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hesap başarıyla oluşturuldu ve bağlandı!'), backgroundColor: Colors.green),
          );
          widget.onProfileUpdated();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      String errorMsg = 'İşlem başarısız (${e.code}).';

      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        errorMsg = 'Bu e-posta zaten kayıtlı. Lütfen "GİRİŞ YAP" sekmesinden giriş yapın.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Geçersiz e-posta formatı.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      } else if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMsg = 'Şifre veya e-posta hatalı! Bilgilerinizi kontrol edin.';
      } else if (e.code == 'missing-email') {
        errorMsg = 'E-posta alanı boş bırakılamaz.';
      } else if (e.code == 'too-many-requests') {
        errorMsg = 'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString().replaceAll("Exception:", "").trim()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}