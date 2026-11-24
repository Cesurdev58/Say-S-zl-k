import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._privateConstructor();
  static final SecureStorageService instance = SecureStorageService._privateConstructor();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // KRİTİK DEĞİŞİKLİK BURADA: Eğer cihazdaki KeyStore değişir veya veri bozulursa, kilitlenmek yerine veriyi silip devam eder.
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> writeData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // Yazma hatasında sadece log at, kilitlenme yaratma
    }
  }

  Future<String?> readData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Okuma hatası olursa kilitlenmek yerine null dön ki varsayılan değerler alınsın
      return null;
    }
  }

  Future<void> deleteData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      // Silme hatası
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Tümü silinirken hata
    }
  }
}