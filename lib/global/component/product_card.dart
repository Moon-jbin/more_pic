// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// // 🌟 [수정]: 기존 ProductItem 임포트를 지우고, 페이지네이션 엔진이 쓰는 product_db_provider를 바라봅니다.
// import 'package:more_pic/provider/product_db_provider.dart';
// import 'package:more_pic/provider/admin_settings_provider.dart';

// class ProductCard extends HookConsumerWidget {
//   // 🎯 [핵심 교체]: ProductItem 대신 신버전 데이터 모델인 ProductModel을 수용하도록 변경
//   final ProductModel product;
//   final VoidCallback? onDelete;

//   const ProductCard({
//     super.key,
//     required this.product,
//     this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final adminSettingsWatch = ref.watch(adminSettingsProvider);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         AspectRatio(
//           aspectRatio: 1 / 1,
//           child: Stack(
//             children: [
//               // 🖼️ [상품 이미지 표시 구역]
//               Container(
//                 width: double.infinity,
//                 height: double.infinity,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF2F2F2),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(2),
//                   child: InkWell(
//                     onTap: () {
//                       context.push(
//                           '/product/${product.categoryName}/${product.id}');
//                     },
//                     child: (product.images.isNotEmpty)
//                         ? CachedNetworkImage(
//                             imageUrl: product.images.first,
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => Container(
//                               color: const Color(0xFFF2F2F2),
//                               child: const Center(
//                                 child: SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                       strokeWidth: 2, color: Color(0xFF6B4EAD)),
//                                 ),
//                               ),
//                             ),
//                             errorWidget: (context, url, error) => const Center(
//                               child: Icon(Icons.broken_image_outlined,
//                                   color: Colors.grey, size: 28),
//                             ),
//                             filterQuality: FilterQuality.high,
//                           )
//                         : const Center(
//                             child: Icon(Icons.image_outlined,
//                                 color: Colors.black26, size: 32),
//                           ),
//                   ),
//                 ),
//               ),

//               // 🗑️ [우측 상단 삭제 버튼 구역]
//               if (adminSettingsWatch)
//                 Positioned(
//                   top: 4,
//                   right: 4,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.8),
//                       shape: BoxShape.circle,
//                     ),
//                     child: IconButton(
//                       constraints: const BoxConstraints(),
//                       padding: const EdgeInsets.all(6),
//                       icon: const Icon(Icons.delete_outline,
//                           color: Colors.red, size: 20),
//                       onPressed: () async {
//                         // 2. 기본 내장 트리거: 신버전 페이지네이션 창고인 paginatedProductProvider를 날려버리도록 연동 수정
//                         await ref
//                             .read(productDBProvider(product.categoryName)
//                                 .notifier)
//                             .deleteProduct(product.id
//                                 .toString()); // 💡 만약 notifier에 delete가 없다면 상위 부모(onDelete)로 위임 처리 권장

//                         // 1. 부모 위젯에서 넘겨준 커스텀 삭제 트리거가 있다면 실행
//                         if (onDelete != null) {
//                           onDelete!();
//                           return;
//                         }
//                       },
//                     ),
//                   ),
//                 )
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         // 상품명
//         Text(
//           product.name,
//           style: const TextStyle(
//               fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 3),

//         // 🌟 [안전 가드]: 혹시 신버전 ProductModel에 아직 size나 color 필드를 추가 안 하셨을 수도 있으므로
//         // 컴파일 에러 방지를 위해 삼항 연산자로 안전하게 방어막을 쳐 드립니다.
//         // 사이즈 정보
//         Text(
//           (product as dynamic).size == null || (product as dynamic).size.isEmpty
//               ? '기본 사이즈'
//               : (product as dynamic).size,
//           style: const TextStyle(
//               fontSize: 12,
//               color: Color(0xFF4A6FA5),
//               fontWeight: FontWeight.w400),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 3),
//         // 색상 정보
//         Text(
//           (product as dynamic).color == null ||
//                   (product as dynamic).color.isEmpty
//               ? '-'
//               : (product as dynamic).color,
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 6),
//         // 가격 표시
//         Text(
//           '${product.price}원',
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade700,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart'; // 💡 신버전 페이지네이션 창고 임포트

class ProductCard extends HookConsumerWidget {
  final ProductModel product; // 🌟 신버전 모델 적용 완료
  final String currentCategory; // 🌟 [추가]: 부모 매대 코너 이름을 받습니다. (기본값 'all' 처리 가능)
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.currentCategory = 'all', // 💡 기본값은 'all'로 세팅
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminSettingsWatch = ref.watch(adminSettingsProvider);

    // 💡 스마트폰 등 좁은 화면(600px 미만)인지 실시간 체크하는 가드 센서
    final bool isMobileSize = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1️⃣ [상품 이미지 표시 구역] - Expanded로 묶어 하단 텍스트 공간이 부족할 때 터지는 연쇄 작용을 완천 차단!
        Expanded(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: InkWell(
                      onTap: () {
                        context.push(
                            '/product/${product.categoryNames.first}/${product.id}');
                        print(
                            "/product/${product.categoryNames.first}/${product.id}");
                      },
                      child: (product.images.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: product.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF2F2F2),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6B4EAD)),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: Colors.grey, size: 28),
                              ),
                              filterQuality: FilterQuality.high,
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined,
                                  color: Colors.black26, size: 32),
                            ),
                    ),
                  ),
                ),

                // 🗑️ [우측 상단 삭제 버튼 구역]
                // 🗑️ [ProductCard.dart 내부 - 우측 상단 삭제 버튼 구역]
                if (adminSettingsWatch)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        // ProductCard.dart 내부 휴지통 아이콘 onPressed 구역 교체용

                        onPressed: () async {
                          // 1️⃣ 리버팟 프로바이더의 삭제 단일 엔진 가동!
                          // product.categoryNames에 담긴 첫 번째 방 주소를 타겟팅해 새로고침을 유발시킵니다.
                          final String targetCat =
                              product.categoryNames.isNotEmpty
                                  ? product.categoryNames.first
                                  : 'all';

                          await ref
                              .read(
                                  paginatedProductProvider(targetCat).notifier)
                              .deleteProduct(product.id);

                          // 2️⃣ 메인 화면 전체보기 피드도 같이 연쇄 청소
                          ref.invalidate(paginatedProductProvider('all'));

                          // 3️⃣ 부모 위젯 리스트 뷰 피드백 콜백 가동
                          if (onDelete != null) {
                            onDelete!();
                          }
                        },
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8), // 3열 압박에 맞춰 여백을 12에서 8로 소폭 다이어트

        // 2️⃣ [상품명 구역] - 모바일에서는 폰트를 컴팩트하게 줄이고, maxLines와 ellipsis로 텍스트 가드 버퍼링!
        Text(
          product.name,
          style: TextStyle(
              fontSize: isMobileSize ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 🌟 [유저님 오더 반영]: 모바일 사이즈 아닐 때(즉, PC/태블릿 와이드 스크린)만 상세 부가정보 노출!
        if (!isMobileSize) ...[
          const SizedBox(height: 3),
          // 사이즈 정보
          Text(
            product.size.isEmpty ? '기본 사이즈' : product.size,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A6FA5),
                fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // 색상 정보
          Text(
            product.color.isEmpty ? '-' : product.color,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 4),

        // 3️⃣ [가격 표시 구역] - 가려짐 현상 없이 언제나 최하단에 칼같이 밀착 고정
        Text(
          '${numberFormat(product.price)}원',
          style: TextStyle(
            fontSize: isMobileSize ? 11 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
