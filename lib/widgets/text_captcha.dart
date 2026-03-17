import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/theme_service.dart';

class TextCaptcha extends StatefulWidget {
  final Function(bool isValid) onValidChanged;

  const TextCaptcha({super.key, required this.onValidChanged});

  @override
  State<TextCaptcha> createState() => _TextCaptchaState();
}

class _TextCaptchaState extends State<TextCaptcha> {
  final _captchaController = TextEditingController();
  String _currentCaptcha = '';
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars like I, 1, O, 0
    final random = Random();
    String newCaptcha = '';
    for (int i = 0; i < 6; i++) {
        newCaptcha += chars[random.nextInt(chars.length)];
    }
    setState(() {
      _currentCaptcha = newCaptcha;
      _captchaController.clear();
      _isValid = false;
    });
    // Use addPostFrameCallback to avoid calling parent callback during build/init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onValidChanged(false);
    });
  }

  void _validateCaptcha(String value) {
    if (value.toUpperCase() == _currentCaptcha) {
      if (!_isValid) {
        setState(() => _isValid = true);
        widget.onValidChanged(true);
      }
    } else {
      if (_isValid) {
        setState(() => _isValid = false);
        widget.onValidChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Check',
              style: ThemeService.getDynamicStyle(
                context,
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: _generateCaptcha,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
              tooltip: 'Refresh Captcha',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: CaptchaPainter(_currentCaptcha),
            child: const Center(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _captchaController,
          onChanged: _validateCaptcha,
          style: ThemeService.getDynamicStyle(context, color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 2),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Type characters above',
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.white38, fontSize: 16, letterSpacing: 0),
            prefixIcon: Icon(
                _isValid ? Icons.check_circle_rounded : Icons.shield_outlined, 
                color: _isValid ? Colors.greenAccent : Colors.white60,
                size: 22
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _isValid ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _isValid ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _isValid ? Colors.greenAccent : Colors.white38, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class CaptchaPainter extends CustomPainter {
  final String text;

  CaptchaPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();

    // Draw background noise lines
    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        linePaint,
      );
    }

    // Draw text with random rotation and offset
    for (int i = 0; i < text.length; i++) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text[i],
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.7 + random.nextDouble() * 0.3),
              fontSize: 28 + random.nextDouble() * 8,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final x = (size.width / text.length) * i + 10 + random.nextDouble() * 5;
        final y = size.height / 2 - textPainter.height / 2 + (random.nextDouble() - 0.5) * 10;

        canvas.save();
        canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
        canvas.rotate((random.nextDouble() - 0.5) * 0.5); // Random rotation between -0.25 and 0.25 radians
        canvas.translate(-(x + textPainter.width / 2), -(y + textPainter.height / 2));
        textPainter.paint(canvas, Offset(x, y));
        canvas.restore();
    }
    
    // Draw foreground noise dots
    final dotPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    for (int i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        1 + random.nextDouble() * 2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
