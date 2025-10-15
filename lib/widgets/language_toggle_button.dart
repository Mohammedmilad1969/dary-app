import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageToggleButton extends StatelessWidget {
  final LanguageService languageService;

  const LanguageToggleButton({
    super.key,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageService,
      builder: (context, child) {
        return IconButton(
          onPressed: () {
            languageService.toggleLanguage();
          },
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                languageService.isEnglish ? Icons.language : Icons.translate,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                languageService.languageCode.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          tooltip: languageService.isEnglish ? 'Switch to Arabic' : 'التبديل إلى الإنجليزية',
        );
      },
    );
  }
}
