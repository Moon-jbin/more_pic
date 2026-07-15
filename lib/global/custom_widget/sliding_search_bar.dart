import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/search_provider.dart';

class SlidingSearchBar extends HookConsumerWidget {
  final List<ProductModel> currentScreenItems; // 🌟 타입 일치 완치
  const SlidingSearchBar({super.key, required this.currentScreenItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);

    FocusNode _focusNode = useFocusNode();
    final isOpen = ref.watch(searchBarOpenProvider);
    final textController = useTextEditingController();

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    useEffect(() {
      if (isOpen) {
        animationController.forward();
        _focusNode.requestFocus();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isOpen]);

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: Container(
        width: double.infinity,
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 10),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Stack(
          children: [
            // ❌ [우측 상단 닫기 버튼]
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, size: 32),
                onPressed: () {
                  textController.clear();
                  // 닫을 때는 검색어 필터를 밀어버려서 정갈하게 복구시킵니다.
                  searchContentRead.setState(
                      const SearchContent(searchContent: '', page: 1));
                  ref.read(searchBarOpenProvider.notifier).close();
                },
              ),
            ),

            // 🔍 [중앙 SEARCH 레이아웃 구역]
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SEARCH',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      focusNode: _focusNode,
                      controller: textController,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해 주세요',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 16),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child:
                              Icon(Icons.search, size: 28, color: Colors.black),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.5),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      onSubmitted: (value) {
                        final query = value.trim();

                        // 1️⃣ [검색 필터 작동]: 현재 페이지에 안착된 실시간 리스트를 찌릅니다.
                        globalSearchRead.filterProducts(
                          query: query,
                          targetList: currentScreenItems,
                        );

                        // 2️⃣ [무한스크롤 연동 핵심]: 장부에 내 검색어를 이식합니다. page는 무조건 1페이지로 리셋!
                        searchContentRead.setState(
                          SearchContent(searchContent: query, page: 1),
                        );

                        // 3️⃣ 검색 주기를 마치고 서치바를 이쁘게 반전 슬라이딩 시킵니다.
                        ref.read(searchBarOpenProvider.notifier).close();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
