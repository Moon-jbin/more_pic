import 'package:flutter/material.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/global/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MORE PIC',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'NotoSansKR',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class MorePicWebService extends StatelessWidget {
  const MorePicWebService({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Scaffold(
      // 모바일용 사이드 메뉴 (Drawer)
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.white,
              child: Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MORE PIC',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomWidget.buildTopMenu('회원가입'),
                        CustomWidget.buildDivider(),
                        CustomWidget.buildTopMenu('로그인'),
                        CustomWidget.buildDivider(),
                        CustomWidget.buildTopMenu('주문조회'),
                        CustomWidget.buildDivider(),
                        CustomWidget.buildTopMenu('최근본상품'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: menuData
                          .map((menu) => CustomWidget.buildDrawerMenu(menu))
                          .toList(),
                    ),
                  ),
                ],
              ),
            )
          : null,
      // 💡 해결 포인트: LayoutBuilder와 ConstrainedBox 조합으로 무한 스크롤과 Sticky 푸터를 동시 만족시킵니다.
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // 브라우저 화면 창의 현재 높이를 최소 높이로 강제 확보합니다.
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Container(
                // 외부 배경색이나 구조 보정용
                color: Colors.white,
                child: Column(
                  // 세로축 분할을 spaceBetween 대신 MainAxisSize.max + 정렬 구조로 변경하여 오버플로우를 차단합니다.
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [1] 최상단 연보라색 배너
                    Container(
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

                    // [2] 메인 본문 레이아웃 그룹
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),

                          // 우측 상단 유틸리티 메뉴
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CustomWidget.buildTopMenu('회원가입'),
                              CustomWidget.buildDivider(),
                              CustomWidget.buildTopMenu('로그인'),
                              CustomWidget.buildDivider(),
                              CustomWidget.buildTopMenu('주문조회'),
                              CustomWidget.buildDivider(),
                              CustomWidget.buildTopMenu('최근본상품'),
                              CustomWidget.buildDivider(),
                              Row(
                                children: [
                                  CustomWidget.buildTopMenu('고객센터'),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 로고 및 카테고리 네비게이션 영역
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    if (isMobile)
                                      Builder(
                                        builder: (context) => IconButton(
                                          icon: const Icon(Icons.menu,
                                              color: Colors.black, size: 28),
                                          onPressed: () =>
                                              Scaffold.of(context).openDrawer(),
                                        ),
                                      ),
                                    const Text(
                                      'MORE PIC',
                                      style: TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!isMobile)
                                    Row(
                                      children: menuData.map((menu) {
                                        return DesktopHoverMenu(
                                          title: menu['title'],
                                          items: menu['children'] ?? [],
                                        );
                                      }).toList(),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Row(
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.search,
                                              color: Colors.black, size: 26),
                                          onPressed: () {}),
                                      const SizedBox(width: 5),
                                      IconButton(
                                          icon: const Icon(Icons.person_outline,
                                              color: Colors.black, size: 26),
                                          onPressed: () {}),
                                      const SizedBox(width: 5),
                                      IconButton(
                                          icon: const Icon(
                                              Icons.local_mall_outlined,
                                              color: Colors.black,
                                              size: 26),
                                          onPressed: () {}),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: isMobile ? 40 : 80),

                          // 💡 Dynamic Router Body 주입부
                          // screenBody,

                          SizedBox(height: isMobile ? 60 : 100),
                        ],
                      ),
                    ),

                    // 💡 [핵심 최적화]: SingleChildScrollView 계열 내부에서 에러를 유발하는 Spacer() 대신
                    // 빈 공간이 있을 때만 늘어나 푸터를 아래로 밀어내주는 고정형 확장 패딩 역할을 합니다.
                    const SizedBox(height: 40),

                    // [3] 하단 푸터 (Footer) 영역
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF5F6FA),
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 50, vertical: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MORE PIC',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 20,
                            runSpacing: 10,
                            children: [
                              CustomWidget.buildFooterMenu('회사소개'),
                              CustomWidget.buildFooterMenu('이용약관'),
                              CustomWidget.buildFooterMenu('개인정보처리방침',
                                  isBold: true),
                              CustomWidget.buildFooterMenu('이용안내'),
                            ],
                          ),
                          const SizedBox(height: 30),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 700) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomWidget.buildFooterSectionTitle(
                                        '쇼핑몰 기본정보'),
                                    const SizedBox(height: 10),
                                    CustomWidget.buildInfoWrap(),
                                    const SizedBox(height: 30),
                                    CustomWidget.buildFooterSectionTitle(
                                        '고객센터 정보'),
                                    const SizedBox(height: 10),
                                    CustomWidget.buildCustomerInfoContent(),
                                    const SizedBox(height: 30),
                                    CustomWidget.buildFooterSectionTitle(
                                        '결제정보'),
                                    const SizedBox(height: 10),
                                    CustomWidget.buildPaymentInfoContent(),
                                  ],
                                );
                              } else {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomWidget.buildFooterSectionTitle(
                                              '쇼핑몰 기본정보'),
                                          const SizedBox(height: 15),
                                          CustomWidget.buildInfoWrap(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomWidget.buildFooterSectionTitle(
                                              '고객센터 정보'),
                                          const SizedBox(height: 15),
                                          CustomWidget
                                              .buildCustomerInfoContent(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomWidget.buildFooterSectionTitle(
                                              '결제정보'),
                                          const SizedBox(height: 15),
                                          CustomWidget
                                              .buildPaymentInfoContent(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
  Widget _buildMenuChild(Map<String, dynamic> item) {
    final List? children = item['children'];
    final bool hasChildren = children != null && children.isNotEmpty;

    Widget menuWidget;

    if (!hasChildren) {
      // 하위 리스트가 없는 경우 일반 버튼
      menuWidget = MenuItemButton(
        onPressed: () {
          print('${item['path']}');
          NavigationService().routerGo(context, item['path'] ?? '/');
        },
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          item['title'],
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black87),
        ),
      );
    } else {
      // 하위 리스트가 더 있는 경우 서브 확장 버튼
      menuWidget = SubmenuButton(
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
        ),
        // 자식 노드가 펼쳐지는 오버레이 영역에도 상위 호버 스택 이벤트를 연동시킵니다.
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
        child: Text(
          item['title'],
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      );
    }

    // 각 아이템 버튼들의 감지 영역을 스택에 누적시킵니다.
    return MouseRegion(
      onEnter: (_) => _incrementHover(),
      onExit: (_) => _decrementHover(),
      child: menuWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 하위 카테고리가 아예 없는 단독 메뉴 탭 처리
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {},
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
