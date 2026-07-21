import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/global/global.dart'; // isMobile(), ProductModel 경로
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/recently_viewed_provider.dart';

class RecentlyViewedFloatingBar extends HookConsumerWidget {
  final bool hasBottomTab; // 🌟 하단/상단 탭이 활성화되어 있는지 여부

  const RecentlyViewedFloatingBar({
    super.key,
    this.hasBottomTab = false, // 기본값은 false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentProducts = ref.watch(recentlyViewedProvider);
    final isExpanded = useState(false);
    final bool mobileMode = isMobile(context); // 반응형 분기

    if (recentProducts.isEmpty) return const SizedBox.shrink();

    // 💡 탭 유무 및 모바일 여부에 따라 Dynamic Bottom Margin 계산
    final double dynamicBottom = mobileMode
        ? (hasBottomTab ? 80.0 : 20.0) // 모바일: 탭 있으면 위로 쑥 올려줌
        : (hasBottomTab ? 100.0 : 20.0); // PC/데스크톱

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      right: 16,
      bottom: dynamicBottom,
      child: mobileMode
          ? _buildMobileWidget(context, recentProducts)
          : _buildDesktopWidget(context, recentProducts, isExpanded),
    );
  }
}

// 📱 모바일 위젯 분리
Widget _buildMobileWidget(
    BuildContext context, List<ProductModel> recentProducts) {
  return FloatingActionButton.small(
    heroTag: 'recently_viewed_btn',
    backgroundColor: Colors.white,
    elevation: 4,
    onPressed: () => _showMobileBottomSheet(context, recentProducts),
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.history, color: Color(0xFF6B4EAD), size: 20),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${recentProducts.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// 💻 데스크톱 위젯 분리
Widget _buildDesktopWidget(BuildContext context,
    List<ProductModel> recentProducts, ValueNotifier<bool> isExpanded) {
  return Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(12),
    color: Colors.white,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16, color: Color(0xFF6B4EAD)),
                  const SizedBox(width: 4),
                  Text(
                    '최근 본 상품 (${recentProducts.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded.value
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded.value) ...[
            const Divider(height: 12, thickness: 1),
            SizedBox(
              width: 140,
              child: Column(
                children: recentProducts.map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
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
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: product.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey.shade200),
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
          ],
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                            borderRadius: BorderRadius.circular(6),
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
                          const SizedBox(height: 4),
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
      );
    },
  );
}
