import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart'; // 💡 실시간 파이어베이스 DB 노티파이어 임포트

class ProductCard extends HookConsumerWidget {
  final ProductItem product;
  final VoidCallback? onDelete; // 💡 외부에서 삭제 콜백을 따로 주입하고 싶을 때를 위한 옵션

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
                    // 💡 구글 스토리지에 저장된 실제 이미지 주소가 있다면 뿌려줍니다.
                    child: (product.images.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            // 처음 열릴 때나 로딩 중일 때 깜빡임 없는 플레이스홀더 처리
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
                        // 1. 부모 위젯에서 넘겨준 커스텀 삭제 트리거가 있다면 먼저 실행
                        if (onDelete != null) {
                          onDelete!();
                          return;
                        }

                        // 2. 기본 내장 트리거: 이 카드가 속한 카테고리의 파이어베이스 상자를 직접 찾아가서 도큐먼트를 파괴합니다.
                        await ref
                            .read(productDBProvider(product.categoryName)
                                .notifier)
                            .deleteProduct(product.id.toString());
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
