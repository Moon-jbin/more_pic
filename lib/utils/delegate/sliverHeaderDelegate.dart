// 파일 경로: lib/utils/delegate/sliverHeaderDelegate.dart

import 'package:flutter/material.dart';

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool isScrolled; // 스크롤 여부 감지 가드

  SliverHeaderDelegate({
    required this.child,
    required this.height,
    required this.isScrolled,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        // 🌟 [UI 소독]: 밋밋한 헤더 하단에 은은하고 입체적인 그림자(BoxShadow) 주입!
        // 평소에도 은은하게 경계를 잡아주고, 스크롤이 살짝 내려가면 더 명확한 입체감을 뿜어냅니다.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                // isScrolled ? 0.06 : 0.03
                //  // 스크롤 시 그림자 농도 조절 (3% -> 6%)
                0.06),
            blurRadius: isScrolled ? 12 : 6, // 그림자 퍼짐 래디우스 조절
            offset: Offset(0, isScrolled ? 4 : 2), // Y축 아래 방향으로 그림자 발사
          )
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.isScrolled != isScrolled;
  }
}
