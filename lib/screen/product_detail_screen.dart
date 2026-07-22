// FILE: lib/screen/product_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/product_detail_bottom_bar.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:flutter/services.dart';
import 'package:more_pic/provider/recently_viewed_provider.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';

class ProductDetailScreen extends HookConsumerWidget {
  final String category;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.category,
    required this.productId,
  });

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(paginatedProductProvider(category));

    final List<ProductModel> productList =
        productListAsync.value?.items ?? <ProductModel>[];

    final product = productList.firstWhere(
      (item) => item.id.toString().trim() == productId.toString().trim(),
      orElse: () {
        if (productList.isNotEmpty) {
          return productList.first;
        }
        return ProductModel(
          id: "-1",
          name: '상품 정보를 불러오는 중입니다...',
          size: '-',
          price: 0,
          images: [],
          categoryNames: [category],
          color: "-",
        );
      },
    );

    if (productListAsync.isLoading && product.id == "-1") {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
        ),
      );
    }

    useEffect(() {
      Future.microtask(() {
        ref.read(recentlyViewedProvider.notifier).addProduct(product);
      });
      return null;
    }, [product]);

    List<String> parsedColors = product.color.isNotEmpty && product.color != "-"
        ? product.color
            .split(RegExp(r'[,/|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : ['단일 색상'];

    List<String> parsedSizes = product.size.isNotEmpty && product.size != "-"
        ? product.size
            .split(RegExp(r'[,/|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : ['Free'];

    // 🚀 가격 연산
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;
    final int originalPrice = (product.price * 1.7).toInt(); // 1.7배 소비자 정가
    final int memberPrice = product.price; // 회원 도매가

    return CustomScaffold(
      category: category,
      showSearchIcon: false,
      bottomNavigationBar: ProductDetailBottomBar(
        productId: product.id,
        productName: product.name,
        basePrice: product.price, // 원본 회원가 전달
        colors: parsedColors,
        sizes: parsedSizes,
      ),
      bodyBuilder: (context, scrollController) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 650),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1 / 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: product.images.isNotEmpty
                                  ? product.images[0]
                                  : '',
                              fit: BoxFit.cover,
                              placeholder: (c, u) =>
                                  CustomWidget.buildShimmerPlaceholder(),
                              filterQuality: FilterQuality.high,
                              errorWidget: (c, u, e) => const Center(
                                  child: Icon(Icons.broken_image, size: 40)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade300, width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('상품명', product.name,
                                fontSize: 17,
                                isBold: true,
                                verticalPadding: 18),
                            _buildInfoRow(
                                '사이즈',
                                product.size.isEmpty
                                    ? '기본 프리사이즈'
                                    : product.size,
                                fontSize: 17,
                                isBold: true,
                                verticalPadding: 18),
                            _buildInfoRow('색상',
                                product.color.isEmpty ? '단일 색상' : product.color,
                                fontSize: 17,
                                isBold: true,
                                verticalPadding: 18),

                            // 🚀 [로그인/비로그인 분기 표 출력]
                            if (isLoggedIn) ...[
                              _buildInfoRow(
                                '판매가',
                                '₩ ${_formatPrice(originalPrice)}',
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                isLineThrough: true, // 👈 싹 긋는 취소선 적용!
                              ),
                              _buildInfoRow(
                                '회원할인가',
                                '₩ ${_formatPrice(memberPrice)}',
                                fontSize: 17,
                                isBold: true,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w900,
                                isLast: true,
                              ),
                            ] else ...[
                              _buildInfoRow(
                                '판매가',
                                '₩ ${_formatPrice(originalPrice)}',
                                fontSize: 16,
                                isBold: true,
                                fontWeight: FontWeight.w900,
                              ),
                              _buildInfoRow(
                                '회원 혜택',
                                '로그인 시 훨씬 저렴한 도매가로 구매 가능합니다 🎉',
                                fontSize: 13,
                                color: Colors.redAccent,
                                isBold: true,
                                isLast: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'DETAIL INFO',
                              style: TextStyle(
                                letterSpacing: 2,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (product.images.length > 1)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: product.images.length - 1,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CachedNetworkImage(
                                  imageUrl: product.images[index + 1],
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  filterQuality: FilterQuality.high,
                                  placeholder: (c, u) =>
                                      CustomWidget.buildShimmerPlaceholder(
                                          height: 500),
                                  errorWidget: (c, u, e) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              '등록된 상세 설명 이미지가 없습니다.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              CustomWidget.customFooter(
                context,
                ref,
                isMobile: _isMobile(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    double fontSize = 12,
    bool isBold = false,
    FontWeight? fontWeight,
    bool isLineThrough = false,
    Color? color,
    double verticalPadding = 14,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
            color: const Color(0xFFFBFBFB),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
              width: 0.8,
              height: verticalPadding * 2 + 16,
              color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: verticalPadding),
              child: label == '상품명'
                  ? Builder(builder: (context) {
                      return InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: value));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✔️ 상품명이 클립보드에 복사되었습니다.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: fontWeight ??
                                        (isBold
                                            ? FontWeight.bold
                                            : FontWeight.w400),
                                    color: color ?? Colors.black,
                                    decoration: isLineThrough
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    })
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight ??
                            (isBold ? FontWeight.bold : FontWeight.w400),
                        color: color ?? Colors.black,
                        decoration: isLineThrough
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool productMeshLoadingCheck(AsyncValue<PaginationState> state, String id) {
    if (id == "-1") return false;
    return state.isLoading;
  }
}
