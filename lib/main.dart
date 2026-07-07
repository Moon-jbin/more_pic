import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/search_provider.dart';
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
            mobileMode ? CustomWidget.customDrawer(context,ref,  menuData) : null,

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
                          CustomWidget.customLogo(context,ref,
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
                        CustomWidget.customFooter(context,ref,
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

// 💡 [전역 최적화 스태틱 상태]: 훅 변환 후에도 대메뉴 간 빠른 전환 시 기존 메뉴를 즉시 닫기 위해 유지합니다.
// 💡 [전역 크래시 가드 변경]: 이제 무덤으로 갈 수 있는 hoverCount 상자 대신,
// 현재 열려있는 컨트롤러와, 그 메뉴를 스스로 닫아줄 수 있는 닫기 함수(Function)만 안전하게 박제합니다.
MenuController? _globalActiveController;
VoidCallback? _globalActiveCloseTrigger;

class DesktopHoverMenu extends HookConsumerWidget {
  final String title;
  final List<dynamic> items;

  const DesktopHoverMenu({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchContentRead = ref.read(searchContentProvider.notifier);

    final controller = useMemoized(() => MenuController());
    final hoverCount = useState(0);
    final debounceTimer = useRef<Timer?>(null);

    // 💡 화면에서 컴포넌트가 사라질 때 타이머뿐만 아니라 전역 찌꺼기 레퍼런스도 깔끔하게 털어냅니다.
    useEffect(() {
      return () {
        debounceTimer.value?.cancel();
        if (_globalActiveController == controller) {
          _globalActiveController = null;
          _globalActiveCloseTrigger = null;
        }
      };
    }, []);

    // 💡 호버 카운트 감소 및 메뉴 폐쇄 로직
    void decrementHover() {
      hoverCount.value--;

      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 100), () {
        // 💡 안전장치: 화면이 이동하여 이미 소멸(dispose)했다면 동작을 스킵합니다.
        if (hoverCount.value <= 0) {
          controller.close();
          if (_globalActiveController == controller) {
            _globalActiveController = null;
            _globalActiveCloseTrigger = null;
          }
        }
      });
    }

    // 💡 호버 카운트 증가 및 메뉴 오픈 로직
    void incrementHover() {
      debounceTimer.value?.cancel();
      hoverCount.value++;

      // 다른 대메뉴 카테고리로 마우스가 순간 이동한 경우
      if (_globalActiveController != null &&
          _globalActiveController != controller) {
        try {
          _globalActiveController!.close();
        } catch (_) {}

        // 🔥 [버그 박멸 핵심]: 이전 메뉴에게 "너 이제 마우스 잃었으니 얼른 문 닫아라"라고
        // 안전하게 클로저 함수 신호만 보내고 끝냅니다. disposed된 변수를 직접 만지지 않습니다.
        if (_globalActiveCloseTrigger != null) {
          try {
            _globalActiveCloseTrigger!();
          } catch (_) {}
        }
      }

      _globalActiveController = controller;
      // 💡 현재 메뉴의 강제 종료 액션을 포장해서 전역 변수에 등록
      _globalActiveCloseTrigger = () {
        hoverCount.value = 0;
        decrementHover();
      };

      controller.open();
    }

    // 💡 서브 메뉴 아이템 빌더 로직
    Widget buildMenuChild(WidgetRef ref, Map<String, dynamic> item) {
      final List? children = item['children'];
      final bool hasChildren = children != null && children.isNotEmpty;

      final bool isTouchDevice = kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);

      if (!hasChildren) {
        return MouseRegion(
          onEnter: (_) => incrementHover(),
          onExit: (_) => decrementHover(),
          child: MenuItemButton(
            onPressed: () {
              NavigationService().routerGo(context, item['path'] ?? '/');
              searchContentRead.initState();
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

      if (isTouchDevice) {
        return PopupMenuButton<String>(
          tooltip: item['title'],
          offset: const Offset(120, 0),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onSelected: (path) {
            NavigationService().routerGo(context, path);
            searchContentRead.initState();
          },
          itemBuilder: (BuildContext context) {
            return children.map<PopupMenuEntry<String>>((child) {
              return PopupMenuItem<String>(
                value: child['path'] ?? '/',
                child:
                    Text(child['title'], style: const TextStyle(fontSize: 13)),
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

      return MouseRegion(
        onEnter: (_) => incrementHover(),
        onExit: (_) => decrementHover(),
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
              onEnter: (_) => incrementHover(),
              onExit: (_) => decrementHover(),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children
                      .map<Widget>((child) => buildMenuChild(ref, child))
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

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {
            if (title == '내복') {
              NavigationService().routerGo(context, InnerRoute);
            } else if (title == 'SALE') {
              NavigationService().routerGo(context, SaleRoute);
            }
            searchContentRead.initState();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => incrementHover(),
      onExit: (_) => decrementHover(),
      child: MenuAnchor(
        controller: controller,
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStatePropertyAll(3),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        menuChildren: [
          MouseRegion(
            onEnter: (_) => incrementHover(),
            onExit: (_) => decrementHover(),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items
                    .map<Widget>((item) => buildMenuChild(ref, item))
                    .toList(),
              ),
            ),
          )
        ],
        builder: (context, menuController, child) {
          return Padding(
            padding: const EdgeInsets.only(right: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: menuController.isOpen
                        ? const Color(0xFFD4CBE5)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                title,
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
