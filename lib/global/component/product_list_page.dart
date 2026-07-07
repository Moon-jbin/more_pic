import 'package:flutter/material.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/search_provider.dart';

class ProductListPage extends HookConsumerWidget {
  final List<ProductItem> itemData;
  final ScrollController scrollController;

  const ProductListPage(
      {super.key, required this.itemData, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchListenerRead = ref.read(searchListenerProvider.notifier);
    final searchListenerWatch = ref.watch(searchListenerProvider);
    final globalSearchWatch = ref.watch(globalSearchProvider);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);

    final currentPage = useState(searchContentWatch.page);
    int itemsPerPage = 8;

    ValueNotifier<int> totalPages =
        useState((itemData.length / itemsPerPage).ceil());

    ValueNotifier<int> startIndex =
        useState((currentPage.value - 1) * itemsPerPage);
    ValueNotifier<int> endIndex = useState(startIndex.value + itemsPerPage);

    ValueNotifier<List<ProductItem>> currentProducts =
        useState(itemData.sublist(startIndex.value, endIndex.value));

    ValueNotifier<bool> showPagenation = useState(true);
    ValueNotifier<bool> isLoading = useState(false);

    // 💡 [초기화 함수]: 검색 상태를 완전 제거하고 초기 1페이지 데이터로 대청소합니다.
    void resetToAllProducts() {
      searchContentRead.setState(const SearchContent(searchContent: '', page: 1));
      currentPage.value = 1;
      startIndex.value = 0;
      endIndex.value =
          itemsPerPage > itemData.length ? itemData.length : itemsPerPage;

      currentProducts.value =
          itemData.sublist(startIndex.value, endIndex.value);
      totalPages.value = (itemData.length / itemsPerPage).ceil();

      showPagenation.value = true;
      globalSearchRead.allProductsFn(currentProducts.value);
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (endIndex.value > itemData.length) {
          endIndex.value = itemData.length;
        }

        if (searchContentWatch.searchContent.isNotEmpty) {
          showPagenation.value = false;
          isLoading.value = true;
          await Future.delayed(const Duration(milliseconds: 100));
          isLoading.value = false;
          globalSearchRead.filterProducts(
              query: searchContentWatch.searchContent, targetList: itemData);
        } else {
          currentProducts.value =
              itemData.sublist(startIndex.value, endIndex.value);
          globalSearchRead.allProductsFn(currentProducts.value);
        }
      });
      return;
    }, []);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startIndex.value = (searchContentWatch.page - 1) * itemsPerPage;

        int calcEndIndex = startIndex.value + itemsPerPage;
        if (calcEndIndex > itemData.length) {
          calcEndIndex = itemData.length;
        }
        endIndex.value = calcEndIndex;

        currentProducts.value =
            itemData.sublist(startIndex.value, endIndex.value);
        globalSearchRead.allProductsFn(currentProducts.value);
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
        final double gridWidth = constraints.maxWidth;
        const double maxExtent = 400;
        const double spacing = 20;

        int crossAxisCount =
            ((gridWidth + spacing) / (maxExtent + spacing)).ceil();
        if (crossAxisCount < 1) crossAxisCount = 1;

        final double totalSpacing = spacing * (crossAxisCount - 1);
        final double itemWidth = (gridWidth - totalSpacing) / crossAxisCount;

        const double textContainerHeight = 145;
        final double childAspectRatio =
            itemWidth / (itemWidth + textContainerHeight);

        // ⭕ [크래시 방어 및 푸터 고정 핵심]
        // constraints.maxHeight가 무한대(infinity)라면 브라우저 화면의 실제 순수 높이(MediaQuery)를 가져옵니다.
        final double safeMinHeight = constraints.maxHeight.isInfinite
            ? MediaQuery.of(context).size.height
            : constraints.maxHeight;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                safeMinHeight, // 💡 이제 무한대가 들어와도 안전하게 화면 높이만큼만 최소 크기를 잡습니다.
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [상단 내용물 컨테이너]
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [상단 타이틀 섹션]
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
                              onPressed: resetToAllProducts,
                              icon: const Icon(Icons.refresh,
                                  size: 14, color: Color(0xFF6B4EAD)),
                              label: const Text(
                                '전체보기 돌아가기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B4EAD),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                backgroundColor:
                                    const Color(0xFFD4CBE5).withOpacity(0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // [상품 그리드 섹션]
                    if (!isLoading.value)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: globalSearchWatch.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 35,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: globalSearchWatch[index]);
                        },
                      ),

                    const SizedBox(height: 60),

                    // [하단 페이지네이션 내비게이터 바]
                    if (totalPages.value > 1 && showPagenation.value)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            color: currentPage.value > 1
                                ? Colors.black87
                                : Colors.grey.shade300,
                            onPressed: currentPage.value > 1
                                ? () {
                                    currentPage.value--;
                                    searchContentRead.setState(SearchContent(
                                        searchContent:
                                            searchContentWatch.searchContent,
                                        page: currentPage.value));
                                  }
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: List.generate(totalPages.value, (index) {
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
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFD4CBE5)
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$pageNum',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF6B4EAD)
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            color: currentPage.value < totalPages.value
                                ? Colors.black87
                                : Colors.grey.shade300,
                            onPressed: currentPage.value < totalPages.value
                                ? () {
                                    currentPage.value++;
                                    searchContentRead.setState(SearchContent(
                                        searchContent:
                                            searchContentWatch.searchContent,
                                        page: currentPage.value));
                                  }
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // [하단 푸터 영역]
              CustomWidget.customFooter(context, ref,
                  isMobile: isMobile(context))
            ],
          ),
        );
      },
    );
  }
}
