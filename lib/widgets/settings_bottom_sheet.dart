import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart'; 
import '../screens/auth_screen.dart';
import 'text_controller_scope.dart';
import '../theme/app_colors.dart';

void showSettingsBottomSheet(BuildContext context, VoidCallback onProfileUpdated) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SettingsSheet(onProfileUpdated: onProfileUpdated),
  );
}

class _SettingsSheet extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  const _SettingsSheet({required this.onProfileUpdated});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;
  bool isStatsHidden = false; // YENİ: Gizlilik Switch'i için state
  
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  String _currentName = '';
  String _currentUid = ''; 
  bool _hasUsedFreeNameChange = false;
  
  bool _isAnonymous = true; 
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await UserService.instance.getCurrentUser();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        await user.reload(); 
      } catch (e) {
        debugPrint("User reload error: $e");
      }
    }
    
    final updatedUser = FirebaseAuth.instance.currentUser;
    
    bool isAnon = updatedUser?.isAnonymous ?? true;
    bool hasEmailProvider = updatedUser?.providerData.any((p) => p.providerId == 'password') ?? false;

    if (hasEmailProvider) {
      isAnon = false; 
    }

    if (!mounted) return;

    setState(() {
      isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
      isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      isStatsHidden = profile.isStatsHidden; // Profilden gizlilik ayarını oku
      _currentName = profile.username;
      _currentUid = profile.uid; 
      _nameController.text = _currentName;
      _hasUsedFreeNameChange = profile.hasUsedFreeNameChange;
      
      _isAnonymous = isAnon; 
      _isEmailVerified = updatedUser?.emailVerified ?? false;
    });
  }

  Future<void> _toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    if (!mounted) return;
    setState(() => isSoundEnabled = value);
    AudioService.instance.updateSettings(isSoundEnabled, isVibrationEnabled); 
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    if (!mounted) return;
    setState(() => isVibrationEnabled = value);
    AudioService.instance.updateSettings(isSoundEnabled, isVibrationEnabled);
  }

  Future<void> _attemptSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _currentName) {
      if (!mounted) return;
      setState(() => _isEditingName = false);
      return;
    }

    if (_hasUsedFreeNameChange) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('İsim Değiştir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('İsmini değiştirmek 1000 Cevher karşılığında yapılacaktır. Onaylıyor musun?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet, Değiştir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        if (!mounted) return;
        setState(() => _isEditingName = false);
        return; 
      }
    }
    _executeSaveName(newName);
  }

  Future<void> _executeSaveName(String newName) async {
    bool success = await UserService.instance.updateUsername(newName);
    
    if (!mounted) return;
    
    if (success) {
      setState(() { _currentName = newName; _isEditingName = false; _hasUsedFreeNameChange = true; });
      widget.onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İsmin başarıyla güncellendi!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yetersiz bakiye! İsim değiştirmek için 1000 Cevher gerekli.'), backgroundColor: Colors.redAccent));
      setState(() => _isEditingName = false);
    }
  }

  void _copyUid() {
    if (_currentUid.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentUid));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oyuncu Kimliği kopyalandı!'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
  }

  void _showDeleteAccountDialog() {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TextControllerScope(
        builder: (context, passwordController) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bu işlem geri alınamaz! Tüm puanların, altınların, arkadaş listen ve satın aldığın içerikler kalıcı olarak silinecektir. Onaylıyor musun?', style: TextStyle(color: Colors.white70)),
              
              if (!_isAnonymous) ...[
                const SizedBox(height: 16),
                const Text('Güvenlik için lütfen şifrenizi girin:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Şifreniz',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
            isLoading 
              ? const Padding(
                  padding: EdgeInsets.only(right: 16, bottom: 8),
                  child: CircularProgressIndicator(color: Colors.redAccent),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (!_isAnonymous && passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen şifrenizi girin.'), backgroundColor: Colors.orange));
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    
                    try {
                      await UserService.instance.deleteAccount(password: passwordController.text.trim());
                      
                      if (mounted && context.mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesabın silindi. Uygulama yeniden başlatılıyor...'), backgroundColor: Colors.green));
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (mounted && context.mounted) {
                        String errorMsg = 'Bir hata oluştu.';
                        if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
                          errorMsg = 'Hatalı şifre girdiniz.';
                        } 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
                      }
                    }
                  },
                  child: const Text('Evet, Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
          ],
        ),
      ),
      ),
    );
  }

  void _showPrivacyPolicyText() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.privacy_tip_rounded, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Text('Gizlilik Politikası', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Text(
                    'SayıSözlük oyununa hoş geldiniz!\n\n'
                    'Bu uygulama, Türkiye Cumhuriyeti Kişisel Verilerin Korunması Kanunu (KVKK) '
                    've uluslararası standartlara uygun olarak tasarlanmıştır.\n\n'
                    '1. Toplanan Veriler:\n'
                    'Oyun deneyiminizi sunabilmek için oyun içi skorlarınız, başarımlarınız, seçtiğiniz kullanıcı adınız ve (eğer bağlarsanız) e-posta adresiniz kaydedilir.\n\n'
                    '2. Veri Güvenliği ve 3. Partiler:\n'
                    'Verileriniz Google Firebase sunucularında şifrelenerek güvenle saklanır. Uygulama içi hataları tespit etmek için Firebase Crashlytics ve size uygun içerikler sunmak için Google AdMob reklam servisleri kullanılmaktadır.\n\n'
                    '3. Hesabı Silme:\n'
                    'Verilerinizin kontrolü tamamen sizdedir. İstediğiniz zaman "Ayarlar" menüsündeki "Hesabımı Sil" butonu ile tüm bilgilerinizi sunucularımızdan kalıcı ve geri döndürülemez şekilde silebilirsiniz.\n\n'
                    'SayıSözlük, cihazınızın kamerasına, rehberine, galerisine veya konumuna ASLA erişim talep etmez.\n\n'
                    'Oyunu oynamaya devam ederek bu şartları kabul etmiş sayılırsınız.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Ayarlar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_rounded, color: AppColors.lavender)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isEditingName
                              ? TextField(controller: _nameController, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8), hintText: 'Yeni Adınız', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none), autofocus: true, onSubmitted: (_) => _attemptSaveName())
                              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_currentName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(_hasUsedFreeNameChange ? 'Bedel: 1000 Cevher' : '1 Ücretsiz Hak', style: TextStyle(color: _hasUsedFreeNameChange ? AppColors.rose : AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600))]),
                        ),
                        if (_isEditingName) IconButton(onPressed: _attemptSaveName, icon: const Icon(Icons.check_circle_rounded, color: AppColors.accent))
                        else IconButton(onPressed: () => setState(() => _isEditingName = true), icon: const Icon(Icons.edit_rounded, color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () async {
                      AudioService.instance.playClick();
                      
                      if (!_isAnonymous) {
                        if (!_isEmailVerified) {
                          try {
                            await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                            if (mounted && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doğrulama e-postası gönderildi. Lütfen e-postanızı kontrol edin.'), backgroundColor: Colors.green));
                          } catch (e) {
                            if (mounted && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta gönderilirken bir hata oluştu.'), backgroundColor: Colors.orange));
                          }
                        } else {
                           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesabınız başarıyla güvence altına alınmış durumda!'), backgroundColor: Colors.green));
                        }
                        return; 
                      }

                      Navigator.pop(context); 
                      Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (_) => AuthScreen(
                          onProfileUpdated: () {
                            widget.onProfileUpdated();
                            _loadSettings();
                          }
                        )),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isAnonymous 
                            ? Colors.redAccent.withValues(alpha: 0.1) 
                            : (_isEmailVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAnonymous 
                              ? Colors.redAccent.withValues(alpha: 0.3) 
                              : (_isEmailVerified ? Colors.green.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3))
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isAnonymous 
                                  ? Colors.redAccent.withValues(alpha: 0.2) 
                                  : (_isEmailVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isAnonymous ? Icons.warning_amber_rounded : (_isEmailVerified ? Icons.verified_user_rounded : Icons.mark_email_unread_rounded), 
                              color: _isAnonymous ? Colors.redAccent : (_isEmailVerified ? Colors.green : Colors.orangeAccent)
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAnonymous ? 'Hesabı Kaydet / Giriş Yap' : (_isEmailVerified ? 'Hesabınız Güvende' : 'E-posta Onaylanmadı'),
                                  style: TextStyle(
                                    color: _isAnonymous ? Colors.redAccent : (_isEmailVerified ? Colors.green : Colors.orangeAccent), 
                                    fontSize: 15, fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isAnonymous ? 'Silinme riskine karşı e-posta bağla' : (_isEmailVerified ? 'İlerlemeleriniz yedekleniyor' : 'Doğrulamak için buraya tıklayın'),
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Column(
                      children: [
                        _buildSettingRow(icon: Icons.volume_up_rounded, color: AppColors.accent, title: 'Ses Efektleri', value: isSoundEnabled, onChanged: _toggleSound),
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 24),
                        _buildSettingRow(icon: Icons.vibration_rounded, color: AppColors.rose, title: 'Titreşim (Haptic)', value: isVibrationEnabled, onChanged: _toggleVibration),
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 24),
                        // YENİ: İstatistikleri Gizleme Butonu
                        _buildSettingRow(
                          icon: Icons.lock_rounded, 
                          color: Colors.orangeAccent, 
                          title: 'İstatistiklerimi Gizle', 
                          value: isStatsHidden, 
                          onChanged: (val) async {
                            setState(() => isStatsHidden = val);
                            await UserService.instance.toggleStatsVisibility(val);
                            widget.onProfileUpdated();
                          }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _copyUid, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                      child: Row(
                        children: [
                          const Icon(Icons.fingerprint_rounded, color: Colors.white54, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Oyuncu Kimliği (ID)', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(_currentUid, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Courier'), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                          const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Column(
                      children: [
                        _buildActionRow(
                          icon: Icons.privacy_tip_rounded, 
                          color: Colors.blueAccent, 
                          title: 'Gizlilik Politikası', 
                          onTap: _showPrivacyPolicyText
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 24),
                        _buildActionRow(
                          icon: Icons.delete_forever_rounded, 
                          color: Colors.redAccent, 
                          title: 'Hesabımı Sil', 
                          isDestructive: true, 
                          onTap: _showDeleteAccountDialog
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({required IconData icon, required Color color, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: color, activeTrackColor: color.withValues(alpha: 0.3), inactiveThumbColor: Colors.white54, inactiveTrackColor: Colors.white.withValues(alpha: 0.1)),
      ],
    );
  }

  Widget _buildActionRow({required IconData icon, required Color color, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
        ],
      ),
    );
  }
}