import 'package:flutter/material.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/search_provider.dart';

class ProductListPage extends HookConsumerWidget {
  final List<ProductItem> itemData;
  final ScrollController scrollController;
  final String category;

  const ProductListPage({
    super.key,
    required this.itemData,
    required this.scrollController,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 구글 파이어베이스 실시간 스트림 구독
    final firebaseProductsState = ref.watch(productDBProvider(category));

    final searchListenerRead = ref.read(searchListenerProvider.notifier);
    final searchListenerWatch = ref.watch(searchListenerProvider);
    final globalSearchWatch = ref.watch(globalSearchProvider);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);

    // 💡 페이지네이션용 고정 개수 설정 (최소 1개 가드로 Infinity 원천 차단)
    const int itemsPerPage = 8;
    final currentPage = useState(searchContentWatch.page);

    // 💡 파이어베이스 데이터가 로드되기 전 초기 훅 변수들의 안전 규격 설정
    final totalPages = useState(1);
    final startIndex = useState(0);
    final endIndex = useState(0);
    final currentProducts = useState<List<ProductItem>>([]);

    final showPagenation = useState(true);
    final isLoading = useState(false);

    // 💡 [초기화 함수]: 검색 상태를 완전 제거하고 초기 1페이지 데이터로 대청소합니다.
    void resetToFilterProducts(List<ProductItem> liveProducts) {
      searchContentRead
          .setState(const SearchContent(searchContent: '', page: 1));
      currentPage.value = 1;
      startIndex.value = 0;
      endIndex.value = itemsPerPage > liveProducts.length
          ? liveProducts.length
          : itemsPerPage;

      currentProducts.value = liveProducts.isEmpty
          ? []
          : liveProducts.sublist(startIndex.value, endIndex.value);
      totalPages.value = liveProducts.isEmpty
          ? 1
          : (liveProducts.length / itemsPerPage).ceil();

      showPagenation.value = true;
      globalSearchRead.allProductsFn(currentProducts.value);
    }

    // 🔄 첫 부팅 또는 카테고리 변경 시 실행할 상태 동기화 효과
    useEffect(() {
      firebaseProductsState.whenData((liveProducts) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          totalPages.value = liveProducts.isEmpty
              ? 1
              : (liveProducts.length / itemsPerPage).ceil();
          startIndex.value = (currentPage.value - 1) * itemsPerPage;
          int calcEnd = startIndex.value + itemsPerPage;
          if (calcEnd > liveProducts.length) calcEnd = liveProducts.length;
          endIndex.value = calcEnd;

          if (searchContentWatch.searchContent.isNotEmpty) {
            showPagenation.value = false;
            isLoading.value = true;
            await Future.delayed(const Duration(milliseconds: 100));
            isLoading.value = false;
            globalSearchRead.filterProducts(
              query: searchContentWatch.searchContent,
              targetList: liveProducts,
            );
          } else {
            currentProducts.value = liveProducts.isEmpty
                ? []
                : liveProducts.sublist(startIndex.value, endIndex.value);
            globalSearchRead.allProductsFn(currentProducts.value);
          }
        });
      });
      return null;
    }, [firebaseProductsState.runtimeType, category]);

    // 🔄 페이지 번호(`currentPage`)가 변경될 때 슬라이싱 범위 재계산 효과
    useEffect(() {
      firebaseProductsState.whenData((liveProducts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startIndex.value = (currentPage.value - 1) * itemsPerPage;
          int calcEndIndex = startIndex.value + itemsPerPage;
          if (calcEndIndex > liveProducts.length) {
            calcEndIndex = liveProducts.length;
          }
          endIndex.value = calcEndIndex;

          currentProducts.value = liveProducts.isEmpty
              ? []
              : liveProducts.sublist(startIndex.value, endIndex.value);
          globalSearchRead.allProductsFn(currentProducts.value);
        });
      });
      return null;
    }, [currentPage.value]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (searchListenerWatch == 1) {
          showPagenation.value = false;
        }
        searchListenerRead.stopListener();
      });
      return null;
    }, [searchListenerWatch]);

    return LayoutBuilder(
      builder: (context, constraints) {
        double gridWidth =
            constraints.maxWidth == 0 ? 1200 : constraints.maxWidth;
        double itemWidth = gridWidth / 4;
        const double textContainerHeight = 145;
        final double itemHeight = itemWidth + textContainerHeight;

        final double childAspectRatio =
            (itemHeight == 0) ? 0.7 : (itemWidth / itemHeight);

        return firebaseProductsState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 100),
              child: CircularProgressIndicator(color: Color(0xFF6B4EAD)),
            ),
          ),
          error: (err, stack) => Center(child: Text('구글 서버 연동 실패: $err')),
          data: (liveProducts) {
            // 구글 실시간 데이터 기반 실시간 페이지 재계산
            int liveTotalPages = liveProducts.isEmpty
                ? 1
                : (liveProducts.length / itemsPerPage).ceil();

            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight.isInfinite
                    ? MediaQuery.of(context).size.height
                    : constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [상단 타이틀 및 검색 결과 표시 구역]
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'NEW! ARRIVALS',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.black),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchContentWatch.searchContent.isEmpty
                                    ? '언제나 새로운 신상품'
                                    : "'${searchContentWatch.searchContent}' 검색 결과 (${globalSearchWatch.length})",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 20),
                              if (searchContentWatch.searchContent.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () =>
                                      resetToFilterProducts(liveProducts),
                                  icon: const Icon(Icons.refresh,
                                      size: 14, color: Color(0xFF6B4EAD)),
                                  label: const Text(
                                    '전체보기 돌아가기',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B4EAD)),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    backgroundColor: const Color(0xFFD4CBE5)
                                        .withOpacity(0.15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // 💡 [텅 빈 화면 방어 가드]: 상품이 없을 때의 예외 UI 처리
                        if (liveProducts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 100),
                              child: Text('등록된 상품이 없습니다.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15)),
                            ),
                          ),

                        // [상품 그리드 섹션]
                        if (liveProducts.isNotEmpty && !isLoading.value)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: globalSearchWatch.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 35,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              final product = globalSearchWatch[index];
                              return ProductCard(
                                product: product,
                                // onDelete: () {
                                //   // 🗑️ 휴지통 버튼 누르면 구글 실시간 DB에서 도큐먼트 파괴 트리거
                                //   ref.read(productDBProvider(category).notifier).deleteProduct(product.id);
                                // },
                              );
                            },
                          ),

                        const SizedBox(height: 60),

                        // [하단 페이지네이션 내비게이터 바]
                        if (liveTotalPages > 1 &&
                            searchContentWatch.searchContent.isEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 20),
                                color: currentPage.value > 1
                                    ? Colors.black87
                                    : Colors.grey.shade300,
                                onPressed: currentPage.value > 1
                                    ? () => currentPage.value--
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Row(
                                children:
                                    List.generate(liveTotalPages, (index) {
                                  final int pageNum = index + 1;
                                  final bool isSelected =
                                      currentPage.value == pageNum;
                                  return InkWell(
                                    onTap: () {
                                      currentPage.value = pageNum;
                                      searchContentRead.setState(SearchContent(
                                          searchContent:
                                              searchContentWatch.searchContent,
                                          page: currentPage.value));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFD4CBE5)
                                                .withOpacity(0.3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('$pageNum',
                                          style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF6B4EAD)
                                                  : Colors.black54,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 20),
                                color: currentPage.value < liveTotalPages
                                    ? Colors.black87
                                    : Colors.grey.shade300,
                                onPressed: currentPage.value < liveTotalPages
                                    ? () => currentPage.value++
                                    : null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  CustomWidget.customFooter(context, ref,
                      isMobile: isMobile(context))
                ],
              ),
            );
          },
        );
      },
    );
  }
}
