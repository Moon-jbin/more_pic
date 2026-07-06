// 💡 상단 고정(Sticky) 효과를 제어하기 위한 프레임 딜리게이트
import 'package:flutter/material.dart';

// class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final Widget child;
//   final double height;

//   SliverHeaderDelegate({required this.child, required this.height});

//   @override
//   double get minExtent => height;
//   @override
//   double get maxExtent => height;

//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         // 💡 본문 콘텐츠가 헤더 밑으로 파고들 때(overlapsContent)만 세련된 그림자 활성화
//         boxShadow: overlapsContent ? [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           )
//         ] : null,
//       ),
//       child: child,
//     );
//   }

//   @override
//   bool shouldRebuild(covariant SliverHeaderDelegate oldDelegate) {
//     return oldDelegate.height != height || oldDelegate.child != child;
//   }
// }

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool isScrolled; // 💡 명시적으로 스크롤 상태를 넘겨받습니다.

  SliverHeaderDelegate({
    required this.child, 
    required this.height, 
    required this.isScrolled, // 💡 필수 인자 추가
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        // 💡 [그림자 부스팅]: 스크롤이 내려갔을 때만 쇼핑몰 특유의 부드럽고 확실한 하단 그림자 노출
        boxShadow: isScrolled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // 은은한 블랙 6% 농도
            blurRadius: 10,                       // 부드럽게 퍼지는 반경
            offset: const Offset(0, 5),           // Y축 아래 방향으로 5픽셀 이동
          )
        ] : null, // 최상단에 있을 때는 선명함을 위해 그림자를 지웁니다.
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || 
           oldDelegate.child != child || 
           oldDelegate.isScrolled != isScrolled; // 💡 상태 변경 시 헤더 리빌드 유도
  }
}
