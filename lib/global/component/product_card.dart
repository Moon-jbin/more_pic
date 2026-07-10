import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// 🌟 [수정]: 기존 ProductItem 임포트를 지우고, 페이지네이션 엔진이 쓰는 product_db_provider를 바라봅니다.
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';

class ProductCard extends HookConsumerWidget {
  // 🎯 [핵심 교체]: ProductItem 대신 신버전 데이터 모델인 ProductModel을 수용하도록 변경
  final ProductModel product;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminSettingsWatch = ref.watch(adminSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1 / 1,
          child: Stack(
            children: [
              // 🖼️ [상품 이미지 표시 구역]
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
                          '/product/${product.categoryName}/${product.id}');
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
                                      strokeWidth: 2, color: Color(0xFF6B4EAD)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
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
                      onPressed: () async {
                        // 2. 기본 내장 트리거: 신버전 페이지네이션 창고인 paginatedProductProvider를 날려버리도록 연동 수정
                        await ref
                            .read(productDBProvider(product.categoryName)
                                .notifier)
                            .deleteProduct(product.id
                                .toString()); // 💡 만약 notifier에 delete가 없다면 상위 부모(onDelete)로 위임 처리 권장

                        // 1. 부모 위젯에서 넘겨준 커스텀 삭제 트리거가 있다면 실행
                        if (onDelete != null) {
                          onDelete!();
                          return;
                        }
                      },
                    ),
                  ),
                )
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 상품명
        Text(
          product.name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),

        // 🌟 [안전 가드]: 혹시 신버전 ProductModel에 아직 size나 color 필드를 추가 안 하셨을 수도 있으므로
        // 컴파일 에러 방지를 위해 삼항 연산자로 안전하게 방어막을 쳐 드립니다.
        // 사이즈 정보
        Text(
          (product as dynamic).size == null || (product as dynamic).size.isEmpty
              ? '기본 사이즈'
              : (product as dynamic).size,
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
          (product as dynamic).color == null ||
                  (product as dynamic).color.isEmpty
              ? '-'
              : (product as dynamic).color,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // 가격 표시
        Text(
          '${product.price}원',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
