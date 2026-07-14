import 'dart:async';
import 'package:flutter/material.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/search_provider.dart';

class ProductListPage extends HookConsumerWidget {
  final ScrollController scrollController;
  final String category;

  const ProductListPage({
    super.key,
    required this.scrollController,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginatedStateAsync = ref.watch(paginatedProductProvider(category));

    final searchListenerRead = ref.read(searchListenerProvider.notifier);
    final searchListenerWatch = ref.watch(searchListenerProvider);
    final globalSearchWatch = ref.watch(globalSearchProvider);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);

    final isLoading = useState(false);
    final bool mobileMode = isMobile(context);

    // 💡 [화면 너비 분기 가드 조율]
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4; // PC 모니터 기본 4열

    if (mobileMode || screenWidth < 768) {
      crossAxisCount = 3; // 📱 모바일 너비 구간 진입 시 강제 3열 사수
    } else if (screenWidth < 1200) {
      crossAxisCount = 3; // 태블릿 스펙 3열 유지
    }

    // 🌟 [반응형 중심 정렬 공백 수식 도킹]
    // 모바일일 땐 정석 양옆 마진(16)을 주고, PC Wide 모니터일 땐 1280px 박스 가드로 수동 연산!
    double horizontalPadding = mobileMode ? 16 : 40;
    if (!mobileMode && screenWidth > 1360) {
      horizontalPadding = (screenWidth - 1280) / 2;
    }

    void resetToFilterProducts() {
      searchContentRead
          .setState(const SearchContent(searchContent: '', page: 1));
      ref.invalidate(paginatedProductProvider(category));
    }

    useEffect(() {
      void scrollListener() {
        if (scrollController.hasClients) {
          if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
            final pState = ref.read(paginatedProductProvider(category));
            if (!pState.isLoading &&
                !pState.isRefreshing &&
                (pState.value?.hasMore ?? false)) {
              ref
                  .read(paginatedProductProvider(category).notifier)
                  .fetchNextPage();
            }
          }
        }
      }

      scrollController.addListener(scrollListener);
      return () => scrollController.removeListener(scrollListener);
    }, [scrollController, category]);

    useEffect(() {
      paginatedStateAsync.whenData((stateData) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (searchContentWatch.searchContent.isNotEmpty) {
            isLoading.value = true;
            await Future.delayed(const Duration(milliseconds: 100));
            isLoading.value = false;
            globalSearchRead.filterProducts(
              query: searchContentWatch.searchContent,
              targetList: stateData.items,
            );
          } else {
            globalSearchRead.allProductsFn(stateData.items);
          }
        });
      });
      return null;
    }, [
      paginatedStateAsync.runtimeType,
      category,
      searchContentWatch.searchContent
    ]);

    return paginatedStateAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 100),
          child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
        ),
      ),
      error: (err, stack) {
        print('err => $err');
        return Center(
            child: Text('❌ 구글 서버 연동 실패: $err',
                style: const TextStyle(color: Colors.red)));
      },
      data: (stateData) {
        final items = stateData.items;
        final isNextPageLoading =
            ref.watch(paginatedProductProvider(category)).isRefreshing;

        return SingleChildScrollView(
          // 🌟 [완치 포인트]: controller: scrollController를 완전히 삭제합니다!
          // 내부 스크롤은 부모(Primary) 체인을 타고 올라가며,
          // 상단의 useEffect 내부 scrollListener가 외부 센서를 정상 추적하므로 무한스크롤은 정상 가동됩니다.
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // 📦 [알맹이 컨테이너 구역]
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [상단 카테고리용 타이틀 구역]
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
                              onPressed: resetToFilterProducts,
                              icon: const Icon(Icons.refresh,
                                  size: 14, color: Color(0xFF4A6FA5)),
                              label: const Text(
                                '전체보기 돌아가기',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A6FA5)),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                backgroundColor:
                                    const Color(0xFF4A6FA5).withOpacity(0.12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    if (items.isEmpty && !isLoading.value)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 100),
                          child: Text('등록된 상품이 없습니다.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15)),
                        ),
                      ),

                    // 🏎️ [상품 그리드 섹션 - 1280px 여백 가이드라인 내에 정렬 가동]
                    if (items.isNotEmpty && !isLoading.value) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchContentWatch.searchContent.isEmpty
                            ? items.length
                            : globalSearchWatch.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: crossAxisCount == 3 ? 12 : 35,
                          crossAxisSpacing: crossAxisCount == 3 ? 8 : 20,
                          childAspectRatio: crossAxisCount == 3 ? 0.55 : 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final product =
                              searchContentWatch.searchContent.isEmpty
                                  ? items[index]
                                  : globalSearchWatch[index] as dynamic;

                          return ProductCard(
                            product: product,
                            currentCategory: category,
                            onDelete: () async {
                              ref.invalidate(
                                  paginatedProductProvider(category));
                            },
                          );
                        },
                      ),
                      if (isNextPageLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF4A6FA5)),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // 📌 하단 고정 푸터 (다시 와이드하게 화면 끝까지 100% 뻗어나감)
              CustomWidget.customFooter(context, ref, isMobile: mobileMode)
            ],
          ),
        );
      },
    );
  }
}
