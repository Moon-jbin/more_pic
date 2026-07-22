// FILE: lib/global/component/product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
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

    final isHovered = useState<bool>(false);

    // 🚀 로그인 상태 확인 및 소비자가(1.7배)/회원가 계산
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;
    final int originalPrice = (product.price * 1.7).toInt(); // 1.7배 소비자가
    final int memberPrice = product.price; // 실제 회원가(도매가)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              cursor: SystemMouseCursors.click,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedScale(
                      scale: isHovered.value ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 300),
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
                                placeholder: (context, url) =>
                                    CustomWidget.buildShimmerPlaceholder(),
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
                  if (adminSettingsWatch)
                    Positioned(
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
                              onPressed: () async {
                                await showProductEditDlgFn(
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

                              // FILE: lib/global/component/product_card.dart 내 삭제 버튼 onPressed 부분

                              onPressed: () async {
                                await showOkCancelDlg(
                                  width: 400,
                                  context,
                                  title: '상품 삭제 확인',
                                  msg: '정말 \'${product.name}\'을(를) 삭제하시겠습니까?',
                                  onCancel: () => Navigator.pop(context),
                                  onTap: () async {
                                    final String targetCat = currentCategory;
                                    Navigator.pop(context); // 1. 기존 삭제 확인 팝업 닫기

                                    // 🚀 2. '삭제 중...' 로딩 다이얼로그 즉시 출력
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        content: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              CircularProgressIndicator(
                                                  color: Colors.redAccent),
                                              SizedBox(height: 20),
                                              Text(
                                                '상품 데이터 및 이미지 삭제 중...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                '잠시만 기다려 주세요.',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );

                                    try {
                                      // 🚀 3. 실제 DB & Storage 병렬 삭제 수행
                                      await ref
                                          .read(paginatedProductProvider(
                                                  targetCat)
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
                                    } finally {
                                      // 🚀 4. 삭제 완료 후 로딩 팝업 닫기 및 완료 안내
                                      if (context.mounted) {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop(); // 로딩 팝업 닫기
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '🗑️ 상품과 관련 이미지가 깔끔하게 삭제되었습니다.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
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

        // 🚀 [가격 표시 로직 변경]: 로그인 시 기존가 취소선 + 회원가 강조 표시
        if (isLoggedIn)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                '₩ ${numberFormat(originalPrice)}',
                style: TextStyle(
                  fontSize: isMobileSize ? 10 : 11,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough, // 👈 기존 소비자가 취소선!
                ),
              ),
              Text(
                '₩ ${numberFormat(memberPrice)}',
                style: TextStyle(
                  fontSize: isMobileSize ? 11 : 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent, // 👈 회원가 빨간색/볼드 강조
                ),
              ),
            ],
          )
        else ...[
          Text(
            '₩ ${numberFormat(originalPrice)}',
            style: TextStyle(
              fontSize: isMobileSize ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '로그인 시 할인가 적용 !',
              style: TextStyle(
                fontSize: isMobileSize ? 9 : 10,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
