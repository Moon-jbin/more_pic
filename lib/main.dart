import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/global/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/utils/routing/router_name.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '모어픽 | 본질에 집중한 미니멀 쇼핑',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'NotoSansKR',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

// 💡 [2] 메인 웹 서비스 컴포넌트 (HookConsumerWidget으로 변경)
class MorePicWebService extends HookConsumerWidget {
  const MorePicWebService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    final bool mobileMode = isMobile(context);

    // 스크롤 리스너: Top 버튼 및 헤더 그림자 제어
    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          // 150px 이상 내려가면 Top 버튼 표시
          if (scrollController.offset > 150) {
            if (!showButton.value) showButton.value = true;
          } else {
            if (showButton.value) showButton.value = false;
          }

          // 1px이라도 내려가면 헤더 그림자 켜기
          if (scrollController.offset > 0) {
            if (!isScrolled.value) isScrolled.value = true;
          } else {
            if (isScrolled.value) isScrolled.value = false;
          }
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    // 반응형 헤더 실측 높이 설정 (디바이스별 최적화)
    final double headerHeight = mobileMode ? 70 : 120;

    return Scaffold(
        backgroundColor: Colors.white,
        drawer:
            mobileMode ? CustomWidget.customDrawer(context, menuData) : null,

        // 💡 단일 통합 스크롤 시스템 가동
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            // 📌 [구조 1]: 스크롤 시 위로 밀려나 사라지는 최상단 안내 배너
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(bottom: 30),
                width: double.infinity,
                color: const Color(0xFFD4CBE5),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  '🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),

            // 📌 [구조 2]: ⭐ 질문하신 Row 영역을 품은 상단 고정(Floating) 헤더 섹션
            SliverPersistentHeader(
              pinned: true, // 👈 상단 고정 활성화!
              delegate: SliverHeaderDelegate(
                height: headerHeight,
                isScrolled: isScrolled.value,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: mobileMode ? 16 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 [유저 요청 영역]: 모바일 메뉴 버튼 + 로고 + 검색 바 레이아웃
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (mobileMode)
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu,
                                    color: Colors.black, size: 28),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          CustomWidget.customLogo(context,
                              fontSize: 38, letterSpacing: 1.5),
                          if (mobileMode)
                            IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.black, size: 26),
                                onPressed: () {}),
                        ],
                      ),
                      // 데스크톱 모드일 때만 하단에 카테고리와 우측 검색창 추가 배치
                      if (!mobileMode) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: menuData.map((menu) {
                                return DesktopHoverMenu(
                                  title: menu['title'],
                                  items: menu['children'] ?? [],
                                );
                              }).toList(),
                            ),
                            IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.black, size: 26),
                                onPressed: () {}),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            // 📌 [구조 3]: 본문 콘텐츠 및 푸터 영역 통합 (Null 에러가 절대 나지 않는 바닥 고정)
            // 💡 SliverFillRemaining을 완전히 제거하고, SliverToBoxAdapter + LayoutBuilder 조합으로 구현합니다.
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 상단 가이드 배너와 고정 헤더의 대략적인 높이를 제외한 화면의 실제 최소 남은 높이를 구합니다.
                  // 배너 + 헤더 높이가 모바일은 약 110px, 데스크톱은 약 160px이므로 이를 빼줍니다.
                  final double minContentHeight =
                      MediaQuery.of(context).size.height -
                          (mobileMode ? 110 : 190);

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minContentHeight > 0
                          ? minContentHeight
                          : 0, // 👈 화면 최소 높이 강제 확보
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // 👈 본문과 푸터를 양 끝으로 밀착
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. 메인 본문 콘텐츠 배치 구역
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: mobileMode ? 16 : 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: mobileMode ? 40 : 80),

                              const Text('TEST'), // 👈 실제 메인 화면 위젯 구역

                              SizedBox(height: mobileMode ? 60 : 100),
                            ],
                          ),
                        ),

                        // 2. 하단 푸터 (Footer) 영역
                        CustomWidget.customFooter(context,
                            isMobile: mobileMode),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // 💡 카테고리 스크린들과 오차 없이 100% 동기화된 프리미엄 흑백 반전 Top 버튼
        floatingActionButton: CustomWidget.customFloatingBtn(
            showButton: showButton, scrollController: scrollController));
  }
}

// -------------------------------------------------------------
// 2. 데스크톱용 다단계 마우스 호버 메뉴 컴포넌트 (전역 최적화 및 완결본)
// -------------------------------------------------------------

class DesktopHoverMenu extends StatefulWidget {
  final String title;
  final List<dynamic> items;

  const DesktopHoverMenu({super.key, required this.title, required this.items});

  @override
  State<DesktopHoverMenu> createState() => _DesktopHoverMenuState();
}

class _DesktopHoverMenuState extends State<DesktopHoverMenu> {
  final MenuController _controller = MenuController();

  // 💡 [최적화 1] 전역에서 현재 활성화된 메뉴와 상태를 추적하는 스태틱 변수
  static MenuController? _globalActiveController;
  static _DesktopHoverMenuState? _globalActiveState;

  // 💡 [최적화 2] 하위 계층 어디라도 마우스가 올라가 있으면 숫자를 올리는 스택 카운터
  int _hoverCount = 0;

  void _incrementHover() {
    _hoverCount++;
    _showMenu();
  }

  void _decrementHover() {
    _hoverCount--;
    // 100ms의 안정적인 디바운스 타임을 주어 계층 간 이동 시 자연스러운 브릿지 연결
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      // 마우스가 메인 카테고리와 하위 모든 서브 메뉴 박스에서 완전히 탈출했을 때만 폐쇄
      if (_hoverCount <= 0) {
        _controller.close();
        if (_globalActiveController == _controller) {
          _globalActiveController = null;
          _globalActiveState = null;
        }
      }
    });
  }

  void _showMenu() {
    // 마우스가 다른 대메뉴 카테고리로 이동한 순간, 기존에 열려있던 메뉴를 즉시 강제 종료
    if (_globalActiveController != null &&
        _globalActiveController != _controller) {
      try {
        // 💡 [크래시 방어] 이미 화면에서 파괴된 유령 컨트롤러일 경우를 대비해 예외 안전 가드 처리
        _globalActiveController!.close();
      } catch (_) {}

      if (_globalActiveState != null) {
        _globalActiveState!._hoverCount = 0; // 이전 메뉴 카운트 강제 초기화
      }
    }

    _globalActiveController = _controller;
    _globalActiveState = this;
    _controller.open();
  }

  // N단 카테고리 트리를 재귀적으로 생성하며 모든 자식 위젯에 호버 이벤트를 전파하는 빌더
  // Widget _buildMenuChild(Map<String, dynamic> item) {
  //   final List? children = item['children'];
  //   final bool hasChildren = children != null && children.isNotEmpty;

  //   Widget menuWidget;

  //   if (!hasChildren) {
  //     // 하위 리스트가 없는 경우 일반 버튼
  //     menuWidget = MenuItemButton(
  //       onPressed: () {
  //         // print('${item['path']}');
  //         NavigationService().routerGo(context, item['path'] ?? '/');
  //       },
  //       style: TextButton.styleFrom(
  //           alignment: Alignment.centerLeft,
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2)),
  //       child: Text(
  //         item['title'],
  //         style: const TextStyle(
  //             fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black87),
  //       ),
  //     );
  //   } else {
  //     // 하위 리스트가 더 있는 경우 서브 확장 버튼
  //     menuWidget = SubmenuButton(
  //       menuStyle: const MenuStyle(
  //         backgroundColor: WidgetStatePropertyAll(Colors.white),
  //         surfaceTintColor: WidgetStatePropertyAll(Colors.white),
  //         elevation: WidgetStatePropertyAll(3),
  //         padding: WidgetStatePropertyAll(EdgeInsets.zero),
  //       ),
  //       style: TextButton.styleFrom(
  //           alignment: Alignment.centerLeft,
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           iconColor: Colors.grey.shade400,
  //           overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2)),
  //       // 자식 노드가 펼쳐지는 오버레이 영역에도 상위 호버 스택 이벤트를 연동시킵니다.
  //       menuChildren: [
  //         MouseRegion(
  //           onEnter: (_) => _incrementHover(),
  //           onExit: (_) => _decrementHover(),
  //           child: IntrinsicWidth(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: children
  //                   .map<Widget>((child) => _buildMenuChild(child))
  //                   .toList(),
  //             ),
  //           ),
  //         )
  //       ],
  //       child: Text(
  //         item['title'],
  //         style: const TextStyle(
  //             fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
  //       ),
  //     );
  //   }

  //   // 각 아이템 버튼들의 감지 영역을 스택에 누적시킵니다.
  //   return MouseRegion(
  //     onEnter: (_) => _incrementHover(),
  //     onExit: (_) => _decrementHover(),
  //     child: menuWidget,
  //   );
  // }
  Widget _buildMenuChild(Map<String, dynamic> item) {
    final List? children = item['children'];
    final bool hasChildren = children != null && children.isNotEmpty;

    // 💡 현재 환경이 모바일/태블릿 터치 환경인지 체크 (Android, iOS 등)
    final bool isTouchDevice = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    if (!hasChildren) {
      // 하위 리스트가 없는 경우 일반 버튼 (기존 동일)
      return MouseRegion(
        onEnter: (_) => _incrementHover(),
        onExit: (_) => _decrementHover(),
        child: MenuItemButton(
          onPressed: () {
            NavigationService().routerGo(context, item['path'] ?? '/');
          },
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2),
          ),
          child: Text(item['title'],
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      );
    }

    // 💡 자식이 있고 + 태블릿/모바일 터치 기기일 때: PopupMenuButton으로 안전하게 터치 대응
    if (isTouchDevice) {
      return PopupMenuButton<String>(
        tooltip: item['title'],
        offset: const Offset(120, 0), // 서브메뉴가 옆으로 뜨도록 위치 조절
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onSelected: (path) {
          NavigationService().routerGo(context, path);
        },
        itemBuilder: (BuildContext context) {
          return children.map<PopupMenuEntry<String>>((child) {
            return PopupMenuItem<String>(
              value: child['path'] ?? '/',
              child: Text(child['title'], style: const TextStyle(fontSize: 13)),
            );
          }).toList();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item['title'],
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      );
    }

    // 💡 자식이 있고 + PC 마우스 환경일 때: 기존의 SubmenuButton 뼈대 그대로 유지
    return MouseRegion(
      onEnter: (_) => _incrementHover(),
      onExit: (_) => _decrementHover(),
      child: SubmenuButton(
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStatePropertyAll(3),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          iconColor: Colors.grey.shade400,
          overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2),
        ),
        menuChildren: [
          MouseRegion(
            onEnter: (_) => _incrementHover(),
            onExit: (_) => _decrementHover(),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .map<Widget>((child) => _buildMenuChild(child))
                    .toList(),
              ),
            ),
          )
        ],
        child: Text(item['title'],
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 하위 카테고리가 아예 없는 단독 메뉴 탭 처리
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {
            if (widget.title == '내복') {
              NavigationService().routerGo(context, InnerRoute);
            } else if (widget.title == 'SALE') {
              NavigationService().routerGo(context, SaleRoute);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ),
        ),
      );
    }

    // 최상단 메인 헤더 카테고리 텍스트 영역 감지
    return MouseRegion(
      onEnter: (_) => _incrementHover(),
      onExit: (_) => _decrementHover(),
      child: MenuAnchor(
        controller: _controller,
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStatePropertyAll(3),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        // 1단 드롭다운 박스 전체 컨테이너 감지 영역
        menuChildren: [
          MouseRegion(
            onEnter: (_) => _incrementHover(),
            onExit: (_) => _decrementHover(),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.items
                    .map<Widget>((item) => _buildMenuChild(item))
                    .toList(),
              ),
            ),
          )
        ],
        builder: (context, controller, child) {
          return Padding(
            padding: const EdgeInsets.only(right: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: controller.isOpen
                        ? const Color(0xFFD4CBE5)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SubHoverMenu extends StatefulWidget {
  final Map<String, dynamic> item;
  const SubHoverMenu({super.key, required this.item});

  @override
  State<SubHoverMenu> createState() => _SubHoverMenuState();
}

class _SubHoverMenuState extends State<SubHoverMenu> {
  final LayerLink _subLayerLink = LayerLink();
  final OverlayPortalController _subController = OverlayPortalController();
  bool _isTargetHovered = false;
  bool _isOverlayHovered = false;

  void _showMenu() {
    _subController.show();
  }

  void _hideMenu() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isTargetHovered && !_isOverlayHovered) {
        _subController.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List? children = widget.item['children'];
    final bool hasChildren = children != null && children.isNotEmpty;

    return MouseRegion(
      onEnter: (_) {
        _isTargetHovered = true;
        if (hasChildren) _showMenu();
      },
      onExit: (_) {
        _isTargetHovered = false;
        if (hasChildren) _hideMenu();
      },
      child: CompositedTransformTarget(
        link: _subLayerLink,
        child: OverlayPortal(
          controller: _subController,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
                link: _subLayerLink,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(1, -1),
                child: MouseRegion(
                  onEnter: (_) {
                    _isOverlayHovered = true;
                    _showMenu();
                  },
                  onExit: (_) {
                    _isOverlayHovered = false;
                    _hideMenu();
                  },
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(4, 4))
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 150),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children!
                              .map<Widget>((child) => SubHoverMenu(item: child))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: (_isTargetHovered || _isOverlayHovered)
                ? const Color(0xFFF8F9FA)
                : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (_isTargetHovered || _isOverlayHovered)
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: (_isTargetHovered || _isOverlayHovered)
                        ? Colors.black
                        : Colors.grey.shade700,
                  ),
                ),
                if (hasChildren)
                  Icon(Icons.chevron_right,
                      size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
