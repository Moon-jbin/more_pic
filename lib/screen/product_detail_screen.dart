import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:more_pic/provider/product_db_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productDBProvider(category));
    final productList = productListAsync.value ?? <ProductItem>[];

    final product = productList.firstWhere(
      (item) => item.id.toString() == productId,
      orElse: () => ProductItem(
        id: "-1",
        name: '상품을 로딩 중이거나 존재하지 않습니다.',
        size: '',
        price: 0,
        images: [], // 통합 images 배열
        categoryName: category,
      ),
    );

    if (productListAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
        ),
      );
    }

    return CustomScaffold(
      itemData: productList,
      category: category,
      showSearchIcon: false,
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
                      // 1️⃣ [대표 이미지 메인 프레임 구역] - images[0]을 띄웁니다.
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
                              placeholder: (c, u) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              errorWidget: (c, u, e) => const Center(
                                  child: Icon(Icons.broken_image, size: 40)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2️⃣ [스펙 테이블 컴포넌트]
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
                                    : product.size),
                            _buildInfoRow('소비자가', '${product.price}원',
                                isLineThrough: true,
                                color: Colors.grey.shade400),
                            _buildInfoRow('판매가', '${product.price}원',
                                fontSize: 15,
                                isBold: true,
                                fontWeight: FontWeight.w900,
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 중간 구분선
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('DETAIL INFO',
                                style: TextStyle(
                                    letterSpacing: 2,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 3️⃣ [상세 사진 리스트] - 대표 이미지 1장을 제외한 2번째 조각부터 렌더링 ⚡
                      if (product.images.length >
                          1) // ⭕ (정정됨) 1장보다 많을 때 리스트 가동!
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              product.images.length - 1, // ⚡ 대표 1장을 뺀 갯수만큼 빌드
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CachedNetworkImage(
                                  imageUrl: product.images[
                                      index + 1], // ⚡ index + 1로 다음 상세 조각 추적!
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  placeholder: (c, u) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
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
                            child: Text('등록된 상세 설명 이미지가 없습니다.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
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
              child: Text(
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
}
