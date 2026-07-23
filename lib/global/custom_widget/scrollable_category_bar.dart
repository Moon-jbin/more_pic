// FILE: lib/global/custom_widget/scrollable_category_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/global/component/hover_menu.dart';

class ScrollableCategoryBar extends HookWidget {
  final List<Map<String, dynamic>> menuData;

  const ScrollableCategoryBar({super.key, required this.menuData});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final showLeft = useState(false);
    final showRight = useState(false);

    void updateArrows() {
      if (!scrollController.hasClients) return;
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      
      showLeft.value = currentScroll > 0;
      showRight.value = maxScroll > 0 && currentScroll < maxScroll;
    }

    useEffect(() {
      scrollController.addListener(updateArrows);
      return () => scrollController.removeListener(updateArrows);
    }, [scrollController]);

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => updateArrows());

        return SizedBox(
          height: 40,
          width: double.infinity,
          child: Stack(
            children: [
              // 1. 실제 스크롤 가능한 메뉴 본체
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: menuData
                        .map((menu) => DesktopHoverMenu(
                            title: menu['title'],
                            items: menu['children'] ?? []))
                        .toList(),
                  ),
                ),
              ),

              // 2. 왼쪽 그라데이션 + 화살표
              if (showLeft.value)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.4, 1.0],
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        scrollController.animateTo(
                          (scrollController.offset - 150).clamp(0.0, scrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.arrow_back_ios_rounded, size: 14, color: Colors.black54),
                      ),
                    ),
                  ),
                ),

              // 3. 오른쪽 그라데이션 + 화살표
              if (showRight.value)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.0), Colors.white],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.6],
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        scrollController.animateTo(
                          (scrollController.offset + 150).clamp(0.0, scrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}