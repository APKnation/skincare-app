import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E9270), Color(0xFF1B5E40)],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E40).withValues(alpha: 0.25),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Text(
        'SY',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
