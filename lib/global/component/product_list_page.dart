// FILE: lib/global/component/product_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/product_filter_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/search_provider.dart';

class ProductListPage extends HookConsumerWidget {
  final String category;

  const ProductListPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐️ 1. 기존 리버팟 페이징 상태 사용 (외부 패키지 없이 안전함)
    final paginatedStateAsync = ref.watch(paginatedProductProvider(category));
    final items = paginatedStateAsync.value?.items ?? [];
    final hasMore = paginatedStateAsync.value?.hasMore ?? false;
    final isFetching =
        paginatedStateAsync.isLoading || paginatedStateAsync.isRefreshing;

    final searchContentWatch = ref.watch(searchContentProvider);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final globalSearchWatch = ref.watch(globalSearchProvider);

    final itemCountAsync = ref.watch(categoryItemCountProvider(category));
    final int totalCategoryCount = itemCountAsync.value ?? 0;

    final menuAsync = ref.watch(globalMenuProvider);
    final currentMenuData = menuAsync.value ?? [];

    final bool mobileMode = isMobile(context);

    final String responsiveCategoryTitle = useMemoized(() {
      if (searchContentWatch.searchContent.isNotEmpty) return "SEARCH RESULT";
      if (category == 'all') return 'NEW! ARRIVALS';

      final cleanTarget =
          category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      String? findKoreanTitle(List menuList, String parentTitle) {
        for (var item in menuList) {
          final String title = item['title'] ?? '';
          final String path = (item['path'] ?? '').toString().toLowerCase();
          final String currentCombinedTitle =
              parentTitle.isEmpty ? title : "$parentTitle > $title";

          final List<String> pathSegments = path.split('/');
          final String lastSegment =
              pathSegments.isNotEmpty ? pathSegments.last : '';
          final String cleanPath = path.replaceAll(RegExp(r'[^a-z0-9]'), '');
          final String cleanLastSegment =
              lastSegment.replaceAll(RegExp(r'[^a-z0-9]'), '');

          if (cleanPath == cleanTarget ||
              cleanLastSegment == cleanTarget ||
              cleanPath.endsWith(cleanTarget)) {
            return currentCombinedTitle;
          }

          final List? children = item['children'];
          if (children != null && children.isNotEmpty) {
            final String? found =
                findKoreanTitle(children, currentCombinedTitle);
            if (found != null) return found;
          }
        }
        return null;
      }

      return findKoreanTitle(currentMenuData, "") ?? category.toUpperCase();
    }, [category, currentMenuData, searchContentWatch.searchContent]);

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (mobileMode || screenWidth < 768) {
      crossAxisCount = 3;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    }

    double horizontalPadding = mobileMode ? 16 : 40;
    if (!mobileMode && screenWidth > 1360) {
      horizontalPadding = (screenWidth - 1280) / 2;
    }

    void resetToFilterProducts() {
      searchContentRead
          .setState(const SearchContent(searchContent: '', page: 1));
      ref.invalidate(paginatedProductProvider(category));
    }

    // 화면에 보여줄 데이터 리스트 결정 (검색 vs 일반)
    final bool isSearchMode = searchContentWatch.searchContent.isNotEmpty;
    final displayItems = isSearchMode ? globalSearchWatch : items;

    return CustomScaffold(
      category: category,
      showSearchIcon: true,
      sliverBuilder: (context, scrollController) {
        return [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        if (category != 'all' &&
                            responsiveCategoryTitle.contains('>')) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                responsiveCategoryTitle.split('>').first.trim(),
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('/',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade300)),
                              ),
                              Text('VIEW ALL',
                                  style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          category == 'all'
                              ? 'NEW ARRIVALS'
                              : responsiveCategoryTitle.split('>').last.trim(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Color(0xFF191919)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category == 'all'
                              ? 'MORE PICK SELECTION'
                              : '${category.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase()} COLLECTION',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                              color: const Color(0xFF4A6FA5).withOpacity(0.7)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                            width: 24,
                            height: 1.5,
                            color: const Color(0xFF191919).withOpacity(0.15)),
                        const SizedBox(height: 16),
                        Text(
                          searchContentWatch.searchContent.isEmpty
                              ? (category == 'all'
                                  ? '언제나 새로운 모어픽만 감성 신상들'
                                  : '모어픽이 엄선한 가장 본질에 집중한 라인업')
                              : "'${searchContentWatch.searchContent}' 검색 결과 (${globalSearchWatch.length}개)",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 20),
                        if (searchContentWatch.searchContent.isNotEmpty)
                          TextButton.icon(
                            onPressed: resetToFilterProducts,
                            icon: const Icon(Icons.refresh,
                                size: 14, color: Color(0xFF4A6FA5)),
                            label: const Text('전체보기 돌아가기',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A6FA5))),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              backgroundColor:
                                  const Color(0xFF4A6FA5).withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ProductFilterBar(
                    totalCount: searchContentWatch.searchContent.isNotEmpty
                        ? globalSearchWatch.length
                        : totalCategoryCount,
                  ),
                ],
              ),
            ),
          ),

          // ⭐️ [수정 후] 기존 아이템이 있으면 일단 그리드를 먼저 그리고,
// 다음 페이지를 로딩 중일 때만 맨 아래에 로딩 스피너를 덧붙입니다.

// 1. 기존 데이터가 있든 없든 그리드를 뿌려줌
          if (displayItems.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: crossAxisCount == 3 ? 12 : 35,
                  crossAxisSpacing: crossAxisCount == 3 ? 8 : 20,
                  childAspectRatio: crossAxisCount == 3 ? 0.55 : 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // 스크롤이 끝에 도달하기 전(끝에서 3번째) 미리 다음 페이지 감지
                    if (!isSearchMode &&
                        index >= displayItems.length - 3 &&
                        hasMore &&
                        !isFetching) {
                      Future.microtask(() {
                        ref
                            .read(paginatedProductProvider(category).notifier)
                            .fetchNextPage();
                      });
                    }
                    return ProductCard(
                      key: ValueKey(displayItems[index].id),
                      product: displayItems[index],
                      currentCategory: category,
                    );
                  },
                  childCount: displayItems.length,
                ),
              ),
            ),

// 2. 맨 처음 첫 페이지를 불러오는 중일 때만 중앙 대형 로딩바 표시
          if (displayItems.isEmpty && isFetching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
                ),
              ),
            ),

// 3. 기존 데이터가 있는 상태에서 '다음 페이지'를 불러올 때 하단에만 소형 로딩바 표시
          if (displayItems.isNotEmpty && isFetching)
            const SliverToBoxAdapter(
              child: Padding(
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
            ),

// 4. 아이템이 진짜 없을 때
          if (displayItems.isEmpty && !isFetching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('아직 등록된 상품이 없습니다.',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // 4. 다음 페이지 로딩 중일 때 하단 스피너
          if (isFetching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child:
                CustomWidget.customFooter(context, ref, isMobile: mobileMode),
          ),
        ];
      },
    );
  }
}
