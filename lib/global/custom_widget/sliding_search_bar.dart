import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';

class SlidingSearchBar extends HookConsumerWidget {
  final List<ProductItem> currentScreenItems;
  const SlidingSearchBar({super.key, required this.currentScreenItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchListenerRead = ref.read(searchListenerProvider.notifier);
    final searchContentRead = ref.read(searchContentProvider.notifier);

    FocusNode _focusNode = useFocusNode();
    // 💡 [Riverpod]: 검색창 오픈 상태 감시
    final isOpen = ref.watch(searchBarOpenProvider);

    // 💡 [Hooks]: 검색어 입력 컨트롤러
    final textController = useTextEditingController();

    // 💡 [Hooks]: 위에서 아래로 내려오는 애니메이션 컨트롤러 세팅
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 400), // 내려오는 속도
    );

    // 💡 isOpen 상태가 바뀔 때마다 애니메이션 트리거 구동
    useEffect(() {
      if (isOpen) {
        animationController.forward();
        _focusNode.requestFocus();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isOpen]);

    // 슬라이드 애니메이션 세부 곡선 설정 (Cubic으로 쫀득하게 내려오도록)
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // 화면 위 영역에 완전히 숨어있음
      end: Offset.zero, // 제자리로 복귀
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: Container(
        width: double.infinity,
        height: 320, // 💡 두 번째 사진 기준 흰색 검색창 영역 적정 높이
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
                  ref.read(searchBarOpenProvider.notifier).close();
                },
              ),
            ),

            // 🔍 [중앙 SEARCH 레이아웃 구역]
            Center(
              child: Container(
                constraints: const BoxConstraints(
                    maxWidth: 600), //웹 브라우저에서 너무 퍼지지 않게 폭 제한
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SEARCH',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.black, // 미니멀 블랙
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ✍️ 두 번째 사진과 일치하는 미니멀 밑줄형 검색창
                    TextField(
                      focusNode: _focusNode,
                      autofocus: true,
                      controller: textController,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center, // 글자를 가운데서부터 입력
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해 주세요',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 16),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child:
                              Icon(Icons.search, size: 28, color: Colors.black),
                        ),
                        // 포커스 여부와 상관없이 밑에 얇은 선 하나만 깔끔하게 유지
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
                        // 💡 엔터 쳤을 때 지난번 만든 검색 로직 연동 지점
                        ref.read(globalSearchProvider.notifier).filterProducts(
                              query: value,
                              targetList: currentScreenItems,
                            );
                        final query = textController.text.trim();
                        // 💡 주소창을 강제로 바꿉니다! page는 무조건 1페이지로 리셋됩니다.
                        searchContentRead.setState(
                            SearchContent(searchContent: query, page: 1));
                        searchListenerRead.workListener(1);
                        textController.clear();
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
