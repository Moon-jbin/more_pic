import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/global/global.dart'; // isMobile(), ProductModel 경로
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/recently_viewed_provider.dart';

class RecentlyViewedFloatingBar extends HookConsumerWidget {
  const RecentlyViewedFloatingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentProducts = ref.watch(recentlyViewedProvider);
    final isExpanded = useState(false);
    final bool mobileMode = isMobile(context);

    if (recentProducts.isEmpty) return const SizedBox.shrink();

    // 💡 AnimatedPositioned를 제거하고 Pure Widget 형태로 반환하여 Column/Stack 어디든 삽입 가능
    return mobileMode
        ? _buildMobileWidget(context, recentProducts)
        : _buildDesktopWidget(context, recentProducts, isExpanded);
  }
}

// 📱 모바일 위젯 (40px FAB 규격 적용)
Widget _buildMobileWidget(
    BuildContext context, List<ProductModel> recentProducts) {
  final lastProduct = recentProducts.first; // 가장 최근 상품

  return SizedBox(
    height: 40,
    width: 40,
    child: FloatingActionButton.small(
      heroTag: 'recently_viewed_btn',
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => _showMobileBottomSheet(context, recentProducts),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 🖼️ 최근 상품 썸네일 (없으면 기본 history 아이콘)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 28,
              height: 28,
              child: lastProduct.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: lastProduct.images.first,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.history,
                      color: Color(0xFF6B4EAD), size: 20),
            ),
          ),
          // 🔴 개수 표시 뱃지
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${recentProducts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// 💻 데스크톱 위젯 (고정 너비 + 부드러운 아코디언 애니메이션)
Widget _buildDesktopWidget(BuildContext context,
    List<ProductModel> recentProducts, ValueNotifier<bool> isExpanded) {
  return Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(14),
    color: Colors.white,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 170, // 🌟 펼쳐지거나 닫혀있을 때 항상 일정한 width 유지
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 40px 높이의 캡슐형 헤더
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // 🌟 양끝 정렬로 형태 균형 유지
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history,
                          size: 18, color: Color(0xFF6B4EAD)),
                      const SizedBox(width: 6),
                      Text(
                        '최근 본 상품 (${recentProducts.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded.value
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // 🌟 펼침 애니메이션 (높이가 부드럽게 조절됨)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: isExpanded.value
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, thickness: 1),
                      Container(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: recentProducts.map((product) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                // 모바일 & PC 데스크톱 위젯 각각의 onTap 내부 수정
                                onTap: () {
                                  // 모바일 버전의 경우 Navigator.pop(context); 유지
                                  context.pushNamed(
                                    'productDetail',
                                    params: {
                                      'category':
                                          product.categoryNames.isNotEmpty
                                              ? product.categoryNames.first
                                              : 'all',
                                      'id': product.id,
                                    },
                                    extra: product, // 🔥 추가
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 4),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: product.images.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      product.images.first,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey.shade200),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  );
}

// 📱 모바일 전용 BottomSheet
void _showMobileBottomSheet(BuildContext context, List<ProductModel> products) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 본 상품 (${products.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed(
                          'productDetail',
                          params: {
                            'category': product.categoryNames.isNotEmpty
                                ? product.categoryNames.first
                                : 'all',
                            'id': product.id,
                          },
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: product.images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: product.images.first,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(color: Colors.grey.shade200),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
