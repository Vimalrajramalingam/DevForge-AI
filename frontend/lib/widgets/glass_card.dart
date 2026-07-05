import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderRadius;
  final double blur;
  final List<Color>? gradientColors;

  const GlassCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderRadius = 12.0,
    this.blur = 15.0,
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(key) {
    final isDark = Theme.of(key).brightness == Brightness.dark;
    
    // Curated dark/light translucent surfaces
    final defaultBgColors = isDark
        ? [
            const Color(0xff15171f).withOpacity(0.4),
            const Color(0xff15171f).withOpacity(0.1),
          ]
        : [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.3),
          ];

    final finalBorderColor = borderColor ?? 
        (isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder.withOpacity(0.5));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: finalBorderColor,
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? defaultBgColors,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
