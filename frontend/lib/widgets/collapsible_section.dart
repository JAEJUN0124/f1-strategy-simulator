import 'package:flutter/material.dart';

/// 접고 펼 수 있는 섹션 헤더와 컨텐츠를 포함하는 위젯
class CollapsibleSection extends StatefulWidget {
  /// 섹션의 제목 (예: "시즌 캘린더")
  final String title;
  /// 섹션의 아이콘 (예: Icons.calendar_today_outlined)
  final IconData icon;
  /// 펼쳤을 때 보여줄 자식 위젯
  final Widget child;
  /// 초기 펼침 상태 (기본값: true)
  final bool initialIsExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initialIsExpanded = true, // 기본적으로 펼쳐진 상태로 시작
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  // 현재 섹션이 펼쳐져 있는지 여부를 관리하는 상태
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialIsExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Card의 경계에 맞춰 자식 위젯을 자름
      child: Column(
        children: [
          // 1. 헤더 (클릭 가능한 영역)
          ListTile(
            // 이미지(image_4f48a6.png)와 유사하게 아이콘과 제목 표시
            leading: Icon(widget.icon, color: Theme.of(context).primaryColor),
            title: Text(
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            // 펼침/닫힘 상태에 따라 화살표 아이콘 변경
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: _toggleExpanded, // 탭하면 상태 변경
          ),
          
          // 2. 컨텐츠 (펼쳐졌을 때만 보임)
          // AnimatedCrossFade를 사용하여 부드러운 애니메이션 효과 적용
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            // 펼쳐졌을 때의 위젯 (자식 위젯)
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: widget.child,
            ),
            // 닫혔을 때의 위젯 (빈 컨테이너)
            secondChild: Container(),
          ),
        ],
      ),
    );
  }
}