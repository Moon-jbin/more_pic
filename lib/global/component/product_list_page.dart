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

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4; // 기본 PC 웹화면 4열 고정

    if (mobileMode || screenWidth < 768) {
      crossAxisCount = 3; // 🌟 3열 강제 고정 사수선
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
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

    // 🌟 [1열 버그 완치 포인트]: 뇌정지 오던 LayoutBuilder와 ConstrainedBox를 통째로 걷어내고,
    // 부모 CustomScaffold와 스크롤뷰가 완벽하게 단일 결합하도록 순수 리턴문으로 레이아웃을 교체했습니다!
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
          controller: scrollController, // 🌟 상위 Scaffod 뼈대와 센서 밀착 바인딩
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Container(
                // 모바일 최적화 좌우 패딩 패킹
                padding: EdgeInsets.symmetric(
                    horizontal: crossAxisCount == 3 ? 12 : 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // 🏎️ [상품 그리드 섹션 - 밧줄이 풀려 드디어 3열 변신 성공!]
                    if (items.isNotEmpty && !isLoading.value) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // 내부 스크롤 꼬임 금지
                        itemCount: searchContentWatch.searchContent.isEmpty
                            ? items.length
                            : globalSearchWatch.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // 📱 3열 고정 스캔 작동!
                          mainAxisSpacing: crossAxisCount == 3 ? 12 : 35,
                          crossAxisSpacing: crossAxisCount == 3 ? 8 : 20,
                          childAspectRatio: crossAxisCount == 3
                              ? 0.55
                              : 0.68, // 🌟 3열 가로 압박 방어선 0.55 비율 완벽 가동
                        ),
                        itemBuilder: (context, index) {
                          final product =
                              searchContentWatch.searchContent.isEmpty
                                  ? items[index]
                                  : globalSearchWatch[index] as dynamic;

                          return ProductCard(
                            product: product,
                            onDelete: () async {
                              // 🎉 해당 개별 카테고리 가방을 즉시 리셋 시켜 새로 고쳐 읽습니다.
                              ref.invalidate(
                                  paginatedProductProvider(category));

                              // 피드백 스낵바 전송
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('🎉 상품 진열이 정상적으로 철수되었습니다.')),
                                );
                              }
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
              CustomWidget.customFooter(context, ref, isMobile: mobileMode)
            ],
          ),
        );
      },
    );
  }
}
