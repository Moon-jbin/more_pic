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

    final globalSearchWatch = ref.watch(globalSearchProvider);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);
    // 🌟 [새 기능 도킹]: Firestore 메뉴 장부에서 현재 카테고리에 맞는 '한글 타이틀'을 동적으로 스캔해 옴
    final menuAsync = ref.watch(globalMenuProvider);
    final currentMenuData = menuAsync.value ?? [];

    final isLoading = useState(false);
    final bool mobileMode = isMobile(context);

    // String getCategoryTitle() {
    //   // 1. 검색어가 있으면 무조건 검색 결과 타이틀 반환
    //   if (searchContentWatch.searchContent.isNotEmpty) {
    //     return "SEARCH RESULT";
    //   }
    //   // 2. 메인 홈('all')인 경우 순정 타이틀 리턴
    //   if (category == 'all') {
    //     return 'NEW! ARRIVALS';
    //   }

    //   // 비교를 위해 카테고리명을 소문자로 만들고 모든 특수문자/슬래시 박멸
    //   final cleanTarget =
    //       category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    //   // 3. 재귀 탐색기 가동
    //   String? findKoreanTitle(List menuList, String parentTitle) {
    //     for (var item in menuList) {
    //       final String title = item['title'] ?? '';
    //       final String path = (item['path'] ?? '').toString().toLowerCase();

    //       final String currentCombinedTitle =
    //           parentTitle.isEmpty ? title : "$parentTitle > $title";

    //       // 경로(path)에서 특수문자를 다 지우고 맨 마지막 단어만 추출
    //       final List<String> pathSegments = path.split('/');
    //       final String lastSegment =
    //           pathSegments.isNotEmpty ? pathSegments.last : '';

    //       final String cleanPath = path.replaceAll(RegExp(r'[^a-z0-9]'), '');
    //       final String cleanLastSegment =
    //           lastSegment.replaceAll(RegExp(r'[^a-z0-9]'), '');

    //       // 디버깅용 로그 (터미널에서 확인 가능)
    //       // print(
    //       //     "🔍 비교중: [CleanTarget: $cleanTarget] vs [CleanPath: $cleanPath] / [CleanLast: $cleanLastSegment]");

    //       // 무조건 매칭 조건 (모두 소문자 + 특수문자 제거 후 비교)
    //       if (cleanPath == cleanTarget ||
    //           cleanLastSegment == cleanTarget ||
    //           cleanPath.endsWith(cleanTarget)) {
    //         return currentCombinedTitle;
    //       }

    //       // 하위 메뉴(children)가 있으면 재귀 탐색
    //       final List? children = item['children'];
    //       if (children != null && children.isNotEmpty) {
    //         final String? found =
    //             findKoreanTitle(children, currentCombinedTitle);
    //         if (found != null) return found;
    //       }
    //     }
    //     return null;
    //   }

    //   final String? matchedTitle = findKoreanTitle(currentMenuData, "");
    //   if (matchedTitle != null) {
    //     return matchedTitle;
    //   }

    //   // 4. 끝내 매칭에 실패했다면, 현재 도대체 어떤 카테고리 ID가 들어왔는지 눈으로 볼 수 있게 임시 출력!
    //   // (이걸 보면 menu_data와 왜 매칭이 안 됐는지 단번에 알 수 있습니다)
    //   return "미매칭 카테고리: $category";
    // }
    // 🌟 [최종 성능 가드]: useMemoized와 디펜던시 [category, currentMenuData] 세팅
    // 이제 카테고리가 아예 바뀌거나, 서버에서 메뉴판 배열이 수정될 때만 '딱 1번' 계산하고 완전히 캐싱됩니다!
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
                    // Center(
                    //   child: Column(
                    //     children: [
                    //       const SizedBox(height: 20),
                    //       Text(
                    //         getCategoryTitle(),
                    //         style: const TextStyle(
                    //             fontSize: 22,
                    //             fontWeight: FontWeight.bold,
                    //             letterSpacing: 1.2,
                    //             color: Colors.black),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(
                    //         searchContentWatch.searchContent.isEmpty
                    //             ? (category == 'all'
                    //                 ? '언제나 새로운 모어픽만의 신상품'
                    //                 : '모어픽 엄선 실시간 진열 코너')
                    //             : "'${searchContentWatch.searchContent}' 검색 결과 (${globalSearchWatch.length}개)",
                    //         style: TextStyle(
                    //             fontSize: 13,
                    //             color: Colors.grey.shade500,
                    //             letterSpacing: 0.8),
                    //       ),
                    //       const SizedBox(height: 20),
                    //       if (searchContentWatch.searchContent.isNotEmpty)
                    //         TextButton.icon(
                    //           onPressed: resetToFilterProducts,
                    //           icon: const Icon(Icons.refresh,
                    //               size: 14, color: Color(0xFF4A6FA5)),
                    //           label: const Text(
                    //             '전체보기 돌아가기',
                    //             style: TextStyle(
                    //                 fontSize: 13,
                    //                 fontWeight: FontWeight.w600,
                    //                 color: Color(0xFF4A6FA5)),
                    //           ),
                    //           style: TextButton.styleFrom(
                    //             padding: const EdgeInsets.symmetric(
                    //                 horizontal: 16, vertical: 10),
                    //             backgroundColor:
                    //                 const Color(0xFF4A6FA5).withOpacity(0.12),
                    //             shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(30)),
                    //           ),
                    //         ),
                    //       const SizedBox(height: 20),
                    //     ],
                    //   ),
                    // ),
                    // ----------------------------------------------------------------------
                    // 🌟 [감성 디자인 리모델링]: 윈도우 탐색기 같던 타이틀을 편집숍 감성으로 빌드업!
                    // ----------------------------------------------------------------------
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          // 1. 상단 브레드크럼 (Breadcrumb) - 현재 카테고리가 'all'이 아닐 때만 노출
                          if (category != 'all' &&
                              responsiveCategoryTitle.contains('>')) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  responsiveCategoryTitle
                                      .split('>')
                                      .first
                                      .trim(), // 대분류 (예: ACC)
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '/', // 💡 딱딱한 '>' 대신 감성적인 슬래시 구분자
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade300),
                                  ),
                                ),
                                Text(
                                  'VIEW ALL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // 2. 메인 카테고리 타이틀 (주인공을 확실하게 부각)
                          Text(
                            category == 'all'
                                ? 'NEW ARRIVALS'
                                : responsiveCategoryTitle
                                    .split('>')
                                    .last
                                    .trim(), // 소분류만 쏙 추출 (예: 양말(KIDS))
                            style: const TextStyle(
                              fontSize: 24, // 폰트 크기 업
                              fontWeight: FontWeight.w800, // 더 묵직하고 정갈한 두께
                              letterSpacing: -0.5, // 세련된 자간 조율
                              color: Color(0xFF191919), // 깊이감 있는 리얼 블랙
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 3. 감성을 채워주는 영문 서브 타이틀 (Underline 효과 스킨)
                          Text(
                            category == 'all'
                                ? 'MORE PICK SELECTION'
                                : '${category.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase()} COLLECTION', // CamelCase를 영문 대문자로 변환 (예: accSocksKids -> ACC SOCKS KIDS COLLECTION)
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5, // 자간을 넓게 벌려 편집숍 특유의 미니멀 무드 연출
                              color: const Color(0xFF4A6FA5)
                                  .withOpacity(0.7), // 은은한 브랜드 포인트 컬러
                            ),
                          ),

                          const SizedBox(height: 12),
                          // 미니멀한 언더라인 바 추가
                          Container(
                            width: 24,
                            height: 1.5,
                            color: const Color(0xFF191919).withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),

                          // 4. 하단 슬로건 설명 문구
                          Text(
                            searchContentWatch.searchContent.isEmpty
                                ? (category == 'all'
                                    ? '언제나 새로운 모어픽만의 감성 신상품'
                                    : '모어픽이 엄선한 가장 본질에 집중한 라인업')
                                : "'${searchContentWatch.searchContent}' 검색 결과 (${globalSearchWatch.length}개)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              letterSpacing: -0.2,
                            ),
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
                            // onDelete: () async {
                            //   ref.invalidate(
                            //       paginatedProductProvider(category));
                            // },
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
