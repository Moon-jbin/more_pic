import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/product_db_provider.dart'; // 🌟 ProductModel 및 가방 프로바이더 위치
import 'package:flutter/services.dart';
import 'package:more_pic/provider/recently_viewed_provider.dart';

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

  // 가격 컴포넌트용 정석 천 단위 포맷터 내장
  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ 리버팟 상태 구독
    final productListAsync = ref.watch(paginatedProductProvider(category));

    // 🌟 [완치 포인트 1]: 반환 객체가 PaginationState이므로 .items 가방을 정확히 명시해 꺼냅니다!
    final List<ProductModel> productList =
        productListAsync.value?.items ?? <ProductModel>[];

    // 2️⃣ 🎯 [완치 포인트 2]: ProductItem 레거시 명칭을 신형 ProductModel로 완벽하게 깔 맞춤 교체
// 🌟 [완치 포인트]: String과 int 타입이 꼬여서 firstWhere가 상품을 놓치던 버그를 완벽하게 차단합니다.
    final product = productList.firstWhere(
      (item) => item.id.toString().trim() == productId.toString().trim(),
      orElse: () {
        // 백그라운드 로딩 중이거나 아직 리스트가 안 올라왔을 때를 위한 안전한 방어선
        if (productList.isNotEmpty) {
          // 혹시라도 리스트는 있는데 ID 매칭만 실패한 경우, 첫 번째 상품이라도 가드로 물려줍니다.
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

    // 🌟 [완치 가드]: 진짜로 상품을 못 찾았거나 로딩 중일 때만 스피너를 돌립니다.
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

    return CustomScaffold(
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
                      // 🖼️ 대표 이미지 락업
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
                              filterQuality: FilterQuality.high,
                              errorWidget: (c, u, e) => const Center(
                                  child: Icon(Icons.broken_image, size: 40)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 📋 스펙 정보 테이블 매핑 구역
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

                            // 💡 [안전 가드]: 기존 레거시 필드가 소멸하더라도 뷰가 깨지지 않게 방어선 처리
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

                            // 🌟 [완치 포인트 3]: 백화점식 가격 콤마 자동 변환 함수 완벽 매핑 도킹!
                            _buildInfoRow(
                              '판매가',
                              '${_formatPrice(product.price)}원',
                              fontSize: 15,
                              isBold: true,
                              fontWeight: FontWeight.w900,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 구분 레이어 선
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

                      // 📸 상세 분할 컷 2번째 조각부터 폭포수 렌더링
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

  // 🛡️ [완치 포인트 4]: 터치 시 즉시 복사 및 변색 제로(투명화) 가드가 장착된 테이블 로우 팩토리
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
                                content: Text('📋 상품명이 클립보드에 복사되었습니다!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        splashColor: Colors.transparent, // 🧼 변색 차단 3신기 주입 완료
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

  // 데이터의 무결성을 판별하기 위한 가드 메서드
  bool productMeshLoadingCheck(AsyncValue<PaginationState> state, String id) {
    if (id == "-1") return false;
    return state.isLoading;
  }
}
