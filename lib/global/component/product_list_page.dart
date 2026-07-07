// 2. 상품 목록 페이지 (HookConsumerWidget + useState 기반)
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

    // 💡 [Hooks 핵심]: 기존의 State 변수 대신 useState 훅으로 현재 페이지 관리
    final currentPage = useState(searchContentWatch.page);
    int itemsPerPage = 8; // 한 페이지당 보여줄 상품 개수

    // 전체 샘플 데이터 (총 24개)

    // 전체 페이지 수 계산
    // int totalPages = (itemData.length / itemsPerPage).ceil();
    ValueNotifier<int> totalPages =
        useState((itemData.length / itemsPerPage).ceil());

    // 💡 currentPage.value를 사용하여 현재 페이지 데이터 슬라이싱
    // final int startIndex = (currentPage.value - 1) * itemsPerPage;
    ValueNotifier<int> startIndex =
        useState((currentPage.value - 1) * itemsPerPage);
    // int endIndex = startIndex + itemsPerPage;
    // if (endIndex > itemData.length) {
    //   endIndex = itemData.length;
    // }
    ValueNotifier<int> endIndex = useState(startIndex.value + itemsPerPage);

    // final List<ProductItem> currentProducts =
    //     itemData.sublist(startIndex, endIndex);
    ValueNotifier<List<ProductItem>> currentProducts =
        useState(itemData.sublist(startIndex.value, endIndex.value));

    ValueNotifier<bool> showPagenation = useState(true);
    ValueNotifier<bool> isLoading = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (endIndex.value > itemData.length) {
          endIndex.value = itemData.length;
        }
        // currentProducts.value =
        //     itemData.sublist(startIndex.value, endIndex.value);

        // globalSearchRead.allProductsFn(currentProducts.value);
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
      // 1. 바뀐 페이지 번호에 맞춰 인덱스 값을 새로 계산합니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startIndex.value = (searchContentWatch.page - 1) * itemsPerPage;

        int calcEndIndex = startIndex.value + itemsPerPage;
        if (calcEndIndex > itemData.length) {
          calcEndIndex = itemData.length;
        }
        endIndex.value = calcEndIndex;

        // 2. 최종 출력할 상품 리스트 상자(value)를 새 데이터 분할본으로 교체합니다.
        currentProducts.value =
            itemData.sublist(startIndex.value, endIndex.value);
        globalSearchRead.allProductsFn(currentProducts.value);
      });

      return null;
    }, [currentPage.value]);

    ///```
    /// 리스너
    ///```
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (searchListenerWatch == 1) {
          showPagenation.value = false;
        }

        // 리스너 중복 구동 차단
        searchListenerRead.stopListener();
      });
      return null;
    }, [searchListenerWatch]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double gridWidth = constraints.maxWidth;
        const double maxExtent = 400;
        const double spacing = 20;

        // 💡 [핵심 수정]: MaxCrossAxisExtent가 내부적으로 열(Column) 개수를 결정하는 공식과 동기화합니다.
        int crossAxisCount =
            ((gridWidth + spacing) / (maxExtent + spacing)).ceil();
        if (crossAxisCount < 1) crossAxisCount = 1;

        // 정확하게 동기화된 열 개수를 바탕으로 아이템의 순수 가로폭 계산
        final double totalSpacing = spacing * (crossAxisCount - 1);
        final double itemWidth = (gridWidth - totalSpacing) / crossAxisCount;

        // 이미지 아래 텍스트 영역의 여유 공간을 145px로 안전하게 확보
        const double textContainerHeight = 145;
        final double childAspectRatio =
            itemWidth / (itemWidth + textContainerHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                          '언제나 새로운 신상품',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 40),
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
                        // 이전 페이지 버튼
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          color: currentPage.value > 1
                              ? Colors.black87
                              : Colors.grey.shade300,
                          onPressed: currentPage.value > 1
                              ? () {
                                  currentPage.value--; // 💡 값 감소
                                  searchContentRead.setState(SearchContent(
                                      searchContent:
                                          searchContentWatch.searchContent,
                                      page: currentPage.value));
                                }
                              : null,
                        ),
                        const SizedBox(width: 10),

                        // 페이지 번호 리스트
                        Row(
                          children: List.generate(totalPages.value, (index) {
                            final int pageNum = index + 1;
                            final bool isSelected =
                                currentPage.value == pageNum;

                            return InkWell(
                              onTap: () {
                                currentPage.value =
                                    pageNum; // 💡 상태 변경 및 UI 자동 리빌드
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
                                      ? const Color(0xFFD4CBE5).withOpacity(0.3)
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
                        // 다음 페이지 버튼
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          color: currentPage.value < totalPages.value
                              ? Colors.black87
                              : Colors.grey.shade300,
                          onPressed: currentPage.value < totalPages.value
                              ? () {
                                  currentPage.value++; // 💡 값 증가
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
            const SizedBox(height: 40),

            // [3] 하단 푸터 (Footer) 영역
            CustomWidget.customFooter(context, ref, isMobile: isMobile(context))
          ],
        );
      },
    );
  }
}
