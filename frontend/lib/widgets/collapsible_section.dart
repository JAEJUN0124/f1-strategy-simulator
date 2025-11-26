import 'package:flutter/material.dart';

/// 접고 펼 수 있는 섹션 헤더와 컨텐츠를 포함하는 위젯
class CollapsibleSection extends StatefulWidget {
  /// 섹션의 제목 (예: "시즌 캘린더")
  final String title;

  /// 섹션의 아이콘 (예: Icons.calendar_today_outlined)
  final IconData icon;

  /// 펼쳤을 때 보여줄 자식 위젯
  final Widget child;

  /// 접혔을 때 보여줄 미리보기 위젯 (상위 3개)
  final Widget? previewChild;

  /// 초기 펼침 상태 (기본값: false)
  final bool initialIsExpanded;

  // 헤더 우측(화살표 왼쪽)에 넣을 커스텀 위젯 (예: 연도 선택 드롭다운)
  final Widget? action;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.previewChild,
    this.initialIsExpanded = false,
    this.action,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. 헤더 영역 (Row로 터치 영역 분리)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // [수정] 왼쪽 영역 (아이콘 + 제목): 여기만 InkWell 적용
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 16.0),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // [수정] 중앙 영역 (드롭다운): InkWell 없음 (버그 해결)
                if (widget.action != null) ...[
                  const SizedBox(width: 24), // 텍스트와 드롭다운 사이 간격
                  widget.action!,
                ],

                // [수정] 오른쪽 영역 (나머지 빈 공간 + 화살표): 여기도 InkWell 적용
                Expanded(
                  child: InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.centerRight, // 우측 정렬
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                      ), // 터치 영역 확보
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 컨텐츠 (펼쳐졌을 때만 보임)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,

            // 펼쳐졌을 때의 위젯
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: widget.child,
            ),

            // 접혔을 때: 미리보기 내용
            secondChild: widget.previewChild != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                    child: widget.previewChild,
                  )
                : Container(),
          ),
        ],
      ),
    );
  }
}
