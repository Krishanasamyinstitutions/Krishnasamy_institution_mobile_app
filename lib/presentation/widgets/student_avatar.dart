import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable student avatar widget that displays the student photo
/// or falls back to first letter of student name with unique colors
class StudentAvatar extends StatelessWidget {
  final String studentName;
  final String? photoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const StudentAvatar({
    super.key,
    required this.studentName,
    this.photoUrl,
    this.size = 50,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 20,
    this.fontWeight = FontWeight.bold,
  });

  /// Color palette for letters A-Z (26 unique color combinations)
  static const List<Map<String, Color>> _letterColors = [
    {'bg': Color(0xFFFFE0E0), 'text': Color(0xFFD32F2F)}, // A - Red
    {'bg': Color(0xFFE3F2FD), 'text': Color(0xFF1976D2)}, // B - Blue
    {'bg': Color(0xFFE8F5E9), 'text': Color(0xFF388E3C)}, // C - Green
    {'bg': Color(0xFFFFF3E0), 'text': Color(0xFFF57C00)}, // D - Orange
    {'bg': Color(0xFFEDE7F6), 'text': Color(0xFF7B1FA2)}, // E - Purple
    {'bg': Color(0xFFE0F7FA), 'text': Color(0xFF00796B)}, // F - Teal
    {'bg': Color(0xFFFCE4EC), 'text': Color(0xFFC2185B)}, // G - Pink
    {'bg': Color(0xFFE8EAF6), 'text': Color(0xFF303F9F)}, // H - Indigo
    {'bg': Color(0xFFFFF8E1), 'text': Color(0xFFFFA000)}, // I - Amber
    {'bg': Color(0xFFE1F5FE), 'text': Color(0xFF0288D1)}, // J - Light Blue
    {'bg': Color(0xFFF3E5F5), 'text': Color(0xFF8E24AA)}, // K - Purple
    {'bg': Color(0xFFE0F2F1), 'text': Color(0xFF00695C)}, // L - Teal
    {'bg': Color(0xFFFFEBEE), 'text': Color(0xFFE53935)}, // M - Red
    {'bg': Color(0xFFE8F5E9), 'text': Color(0xFF43A047)}, // N - Green
    {'bg': Color(0xFFFFF3E0), 'text': Color(0xFFEF6C00)}, // O - Orange
    {'bg': Color(0xFFE3F2FD), 'text': Color(0xFF1E88E5)}, // P - Blue
    {'bg': Color(0xFFF3E5F5), 'text': Color(0xFF9C27B0)}, // Q - Purple
    {'bg': Color(0xFFFFECB3), 'text': Color(0xFFFF8F00)}, // R - Amber
    {'bg': Color(0xFFDCEDC8), 'text': Color(0xFF689F38)}, // S - Light Green
    {'bg': Color(0xFFB3E5FC), 'text': Color(0xFF0277BD)}, // T - Light Blue
    {'bg': Color(0xFFD1C4E9), 'text': Color(0xFF5E35B1)}, // U - Deep Purple
    {'bg': Color(0xFFFFCCBC), 'text': Color(0xFFE64A19)}, // V - Deep Orange
    {'bg': Color(0xFFB2DFDB), 'text': Color(0xFF00796B)}, // W - Teal
    {'bg': Color(0xFFF8BBD0), 'text': Color(0xFFD81B60)}, // X - Pink
    {'bg': Color(0xFFFFE082), 'text': Color(0xFFFFA000)}, // Y - Amber
    {'bg': Color(0xFFBBDEFB), 'text': Color(0xFF1976D2)}, // Z - Blue
  ];

  /// Get colors based on first letter of name
  Map<String, Color> _getColorsForLetter() {
    if (studentName.isEmpty) {
      return {'bg': const Color(0xFFE5E7EB), 'text': const Color(0xFF6B7280)};
    }

    final firstChar = studentName[0].toUpperCase();
    if (firstChar.codeUnitAt(0) >= 65 && firstChar.codeUnitAt(0) <= 90) {
      // A-Z (ASCII 65-90)
      final index = firstChar.codeUnitAt(0) - 65;
      return _letterColors[index];
    }

    // Default for non-letter characters
    return {'bg': const Color(0xFFE5E7EB), 'text': const Color(0xFF6B7280)};
  }

  /// Creates a small avatar (40x40)
  factory StudentAvatar.small({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 40,
      fontSize: 16,
    );
  }

  /// Creates a medium avatar (50x50) - default size
  factory StudentAvatar.medium({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 50,
      fontSize: 20,
    );
  }

  /// Creates a large avatar (80x80) - for profile pages
  factory StudentAvatar.large({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 80,
      fontSize: 32,
    );
  }

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  String get _firstLetter {
    if (studentName.isEmpty) return 'S';
    return studentName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForLetter();
    final bgColor = backgroundColor ?? colors['bg']!;
    final txtColor = textColor ?? colors['text']!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _hasPhoto ? null : bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: size >= 80
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasPhoto
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (context, url) => Container(
                color: bgColor,
                child: Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildLetterFallback(bgColor, txtColor),
            )
          : _buildLetterFallback(bgColor, txtColor),
    );
  }

  Widget _buildLetterFallback(Color bgColor, Color txtColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          _firstLetter,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: txtColor,
          ),
        ),
      ),
    );
  }
}
