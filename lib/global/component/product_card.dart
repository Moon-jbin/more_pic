import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // 👉 useState를 위해 추가
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';

class ProductCard extends HookConsumerWidget {
  final ProductModel product;
  final String currentCategory;

  const ProductCard({
    super.key,
    required this.product,
    this.currentCategory = 'all',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminSettingsWatch = ref.watch(adminSettingsProvider);
    final bool isMobileSize = MediaQuery.of(context).size.width < 600;

    // 👉 [추가] 마우스 호버 상태 관리
    final isHovered = useState<bool>(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            // 👉 [추가] 마우스 이벤트 감지
            child: MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              cursor: SystemMouseCursors.click, // 손가락 모양 커서
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    clipBehavior:
                        Clip.hardEdge, // 👉 확대될 때 이미지가 둥근 모서리를 벗어나지 않도록 방어
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    // 👉 [추가] AnimatedScale 적용
                    child: AnimatedScale(
                      scale: isHovered.value ? 1.05 : 1.0, // 마우스 올리면 1.05배 줌
                      duration: const Duration(milliseconds: 300), // 부드러운 속도
                      curve: Curves.easeOutCubic,
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(
                            'productDetail',
                            params: {
                              'category': product.categoryNames.first,
                              'id': product.id.toString(),
                            },
                          );
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
                  // 관리자 모드 아이콘들 (기존 코드와 동일)
                  if (adminSettingsWatch)
                    Positioned(
                      // ... (기존 관리자 수정/삭제 버튼 코드 그대로 유지) ...
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF4A6FA5), size: 18),
                              onPressed: () {
                                showProductEditDlgFn(
                                  context,
                                  product: product,
                                  currentCategory: currentCategory,
                                );
                              },
                            ),
                          ),
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
                                        .read(
                                            paginatedProductProvider(targetCat)
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
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 하단 텍스트 정보들 (기존 코드와 동일)
        Text(
          product.name,
          style: TextStyle(
              fontSize: isMobileSize ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isMobileSize) ...[
          const SizedBox(height: 3),
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
          Text(
            product.color.isEmpty ? '-' : product.color,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
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
