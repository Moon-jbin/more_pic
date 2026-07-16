import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart'; // 💡 신버전 페이지네이션 창고 임포트

class ProductCard extends HookConsumerWidget {
  final ProductModel product; // 🌟 신버전 모델 적용 완료
  final String currentCategory; // 🌟 [추가]: 부모 매대 코너 이름을 받습니다. (기본값 'all' 처리 가능)
  // final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.currentCategory = 'all', // 💡 기본값은 'all'로 세팅
    // this.onDelete,
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
                        // 🌟 [완치 핵심]: 하드코딩 주소 밀어넣기 대신, GoRouter 정석 규칙인 pushNamed를 작동시킵니다.
                        // 이렇게 params 가방에 명시적으로 담아 보내면 변수가 절대 유실되지 않고 안전하게 수송됩니다!
                        context.pushNamed(
                          'productDetail',
                          params: {
                            'category': product.categoryNames.first,
                            'id': product.id.toString(),
                          },
                        );

                        // print(
                        //     "🚀 [안전 수송 완치] /product/${product.categoryNames.first}/${product.id}");
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

                // 🌟 [완치 및 업그레이드]: 관리자 모드일 때만 동작하는 '수정 & 삭제' 조작 패널
                if (adminSettingsWatch)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🛠️ 1. [신규 도킹]: 상품 정보 수정 버튼 (연필 모양)
                        Container(
                          margin:
                              const EdgeInsets.only(right: 6), // 삭제 버튼과의 간격 조율
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.9), // 가시성 확보용 투명 백그라운드
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF4A6FA5), size: 18),
                            onPressed: () {
                              // 🚀 2단계에서 새로 만든 무결성 텍스트 수정 다이얼로그 강제 소환!
                              showProductEditDlgFn(
                                context,
                                product: product,
                                currentCategory: currentCategory,
                              );
                            },
                          ),
                        ),

                        // 🗑️ 2. 기존 삭제 버튼 (순정 로직 무결성 보존)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            onPressed: () async {
                              await showOkCancelDlg(
                                width: 400,
                                context,
                                title: '상품 삭제 확인',
                                msg: '정말 \'${product.name}\'를 삭제하시겠습니까?',
                                onCancel: () => Navigator.pop(context),
                                onTap: () async {
                                  final String targetCat = currentCategory;
                                  await ref
                                      .read(paginatedProductProvider(targetCat)
                                          .notifier)
                                      .deleteProduct(
                                        productId: product.id,
                                        targetCategory: targetCat,
                                        productCategories:
                                            product.categoryNames,
                                      );

                                  ref.invalidate(
                                      paginatedProductProvider('all'));
                                  for (var cat in product.categoryNames) {
                                    ref.invalidate(
                                        paginatedProductProvider(cat));
                                  }

                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                      ],
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
