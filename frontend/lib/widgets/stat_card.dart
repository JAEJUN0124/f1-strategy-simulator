import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// '실제 vs 최적' 비교 등을 위한 공용 스탯 카드
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              maxLines: 1, // 1줄로 제한
              minFontSize: 10, // 최소 글꼴 크기
            ),
          ],
        ),
      ),
    );
  }
}