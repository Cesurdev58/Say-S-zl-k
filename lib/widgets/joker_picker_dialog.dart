import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_colors.dart';

/// JOKER taşı için harf seçtiren ortak diyalog (solo ve çok oyunculu).
///
/// Seçilen harfle kapanır (`Navigator.pop(char)`); dışarı dokunarak
/// kapatılırsa `null` döner.
class JokerPickerDialog extends StatefulWidget {
  const JokerPickerDialog({super.key});

  static const List<String> alphabet = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
  ];

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const JokerPickerDialog(),
    );
  }

  @override
  State<JokerPickerDialog> createState() => _JokerPickerDialogState();
}

class _JokerPickerDialogState extends State<JokerPickerDialog> {
  // Çift dokunuşta route'un iki kez pop edilmesini önler.
  bool _picked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Joker Harf Seçin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: JokerPickerDialog.alphabet.map((char) {
                    return InkWell(
                      onTap: () {
                        if (_picked) return;
                        _picked = true;
                        AudioService.instance.playClick();
                        Navigator.of(context).pop(char);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppColors.joker, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(char, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
