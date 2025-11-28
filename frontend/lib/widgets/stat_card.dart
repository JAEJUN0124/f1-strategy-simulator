import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                // (수정) 12 -> 14로 크기 키움
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color ?? Colors.black87,
                height: 1.2,
              ),
              maxLines: 1,
              minFontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}
