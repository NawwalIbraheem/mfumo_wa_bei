import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.icon = Icons.person_outline,
    this.size = 44,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor = const Color(0xFFE8F5E9),
    this.foregroundColor = const Color(0xFF0E7A3B),
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String? initials;
  final IconData icon;
  final double size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(effectiveWidth / 2);
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: url == null || url.isEmpty
            ? _AvatarFallback(
                initials: initials,
                icon: icon,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              )
            : Image.network(
                url,
                fit: fit,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                  initials: initials,
                  icon: Icons.broken_image_outlined,
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                ),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String? initials;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final label = initials?.trim().toUpperCase();
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: label == null || label.isEmpty
            ? Icon(icon, color: foregroundColor, size: 28)
            : Text(
                label.characters.take(2).toString(),
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
