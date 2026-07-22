import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/global/custom_widget/recently_viewed_floationg_bar.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/cart_provider.dart';
import 'package:more_pic/provider/global_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/screen/order_form_screen.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router_name.dart';
import 'dart:html' as html;

import 'package:shimmer/shimmer.dart';

// 💡 [수정 위치]: lib/global/custom_widget/custom_widget.dart 내 CustomScaffold 클래스 전체

// FILE: lib/global/custom_widget/custom_widget.dart 내 CustomScaffold 클래스 수정

class CustomScaffold extends HookConsumerWidget {
  final Widget Function(BuildContext context, ScrollController scrollController)
      bodyBuilder;
  final String category;
  final bool showSearchIcon;
  final Widget? bottomNavigationBar;

  const CustomScaffold({
    super.key,
    required this.bodyBuilder,
    required this.category,
    this.showSearchIcon = true,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    // 🚀 장바구니 개수 구독
    final cartCount = ref.watch(cartProvider).length;

    final paginatedState = ref.watch(paginatedProductProvider(category));
    final filterProducts = paginatedState.maybeWhen(
      data: (stateData) => stateData.items.cast<ProductModel>(),
      orElse: () => const <ProductModel>[],
    );

    final menuAsync = ref.watch(globalMenuProvider);
    final List<Map<String, dynamic>> currentMenuData = menuAsync.maybeWhen(
      data: (menuList) => menuList,
      orElse: () => const <Map<String, dynamic>>[],
    );

    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          if (scrollController.offset > 150) {
            if (!showButton.value) showButton.value = true;
          } else {
            if (showButton.value) showButton.value = false;
          }

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

    return Scaffold(
        drawer: CustomWidget.customDrawer(context, ref, currentMenuData),
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.deepPurple[100],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      '♥ 로그인 시 회원가 확인 가능 ♥',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverHeaderDelegate(
                    isScrolled: isScrolled.value,
                    height: isMobile(context) ? 70 : 110,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu,
                                  color: Colors.black, size: 28),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          CustomWidget.customLogo(context, ref,
                              fontSize: 24, letterSpacing: 1.5),

                          // 🚀 우측 아이콘 그룹 (검색 + 장바구니)
                          Row(
                            children: [
                              if (showSearchIcon)
                                IconButton(
                                  icon: const Icon(Icons.search,
                                      color: Colors.black),
                                  onPressed: () => ref
                                      .read(searchBarOpenProvider.notifier)
                                      .open(),
                                ),

                              // 🛒 주문서 바로가기 (뱃지)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.assignment_outlined,
                                        color: Colors.black, size: 26),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const OrderFormScreen()),
                                      );
                                    },
                                  ),
                                  if (cartCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle),
                                        constraints: const BoxConstraints(
                                            minWidth: 16, minHeight: 16),
                                        child: Text(
                                          '$cartCount',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: bodyBuilder(context, scrollController),
                ),
              ],
            ),
            SlidingSearchBar(currentScreenItems: filterProducts),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const RecentlyViewedFloatingBar(),
            const SizedBox(height: 15),
            CustomWidget.buildChannelTalkFloatingBtn(context),
            CustomWidget.customFloatingBtn(
              showButton: showButton,
              scrollController: scrollController,
            ),
          ],
        ));
  }
}

class CustomWidget {
  static Widget customLogo(BuildContext context, WidgetRef ref,
      {double fontSize = 22, double? letterSpacing, bool isDrawer = false}) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        context.go('/');
        searchContentRead.initState();
      },
      child: Image.asset(
          width: isMobile(context) || isDrawer ? 120 : 240,
          'images/more_pic_logo.png'),
    );
  }

  static Widget customDrawer(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> menuData) {
    final adminRead = ref.watch(adminSettingsProvider.notifier);
    final adminSettingsWatch = ref.watch(adminSettingsProvider);
    final adminSettingsRead = ref.watch(adminSettingsProvider.notifier);

    // 🚀 장바구니 품목 수량 구독
    final cartCount = ref.watch(cartProvider).length;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customLogo(context, ref, isDrawer: true),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // 관리자 전용 메뉴 편집 버튼
          if (adminSettingsWatch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40)),
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: const Text('카테고리 편집기'),
                onPressed: () {
                  Navigator.pop(context);
                  showMenuEditDialog(context, menuData);
                },
              ),
            ),

          if (adminSettingsWatch) const Divider(height: 1),

          // 🚀 [추가] 드로어 메뉴 목록 상단에 '주문서 작성 (장바구니)' 전용 타일 배치
          if (cartCount > 0)
            ListTile(
              leading:
                  const Icon(Icons.assignment_outlined, color: Colors.black87),
              title: Row(
                children: [
                  const Text(
                    '주문서 작성',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (cartCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing:
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              onTap: () {
                Navigator.pop(context); // 드로어 닫기
                NavigationService().routerGo(context, OrderFormScreenRoute);
              },
            ),
          if (cartCount > 0)
            const Divider(height: 1, indent: 16, endIndent: 16),

          // 카테고리 메뉴 리스트
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuData
                  .map((menu) => buildDrawerMenu(context, ref, menu))
                  .toList(),
            ),
          ),

          // 하단 회원 관련 버튼
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade500,
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  onPressed: () async {
                    if (adminSettingsRead.isLoggedIn) {
                      await adminRead.logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('안전하게 로그아웃 되었습니다.')),
                        );
                      }
                    } else {
                      showAdminLoginDialog(context);
                    }
                  },
                  child: Text(
                    adminSettingsRead.isLoggedIn ? '로그아웃' : '로그인 / 회원가입',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTopMenu(String title) => InkWell(
      onTap: () {},
      child: Text(title,
          style: const TextStyle(fontSize: 11, color: Colors.grey)));
  static Widget buildDivider() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('|',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade300)));
  static Widget buildFooterMenu(String title, {bool isBold = false}) => InkWell(
      onTap: () {},
      child: Text(title,
          style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal)));
  static Widget buildFooterSectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black));
// 🔥 기존 buildDrawerMenu 함수를 아래와 같이 수정합니다.
  static Widget buildDrawerMenu(
      BuildContext context, WidgetRef ref, Map<String, dynamic> menu) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final List<dynamic> rawChildren = menu['children'] ?? [];

    if (rawChildren.isEmpty) {
      return ListTile(
          title: Text(menu['title'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          dense: true,
          onTap: () {
            context.go(menu['path'] ?? '/');
            searchContentRead.initState();
          });
    }
    return ExpansionTile(
      // 🔥 ExpansionTile의 title을 InkWell로 감싸서 터치 이벤트를 가져갑니다.
      title: InkWell(
        onTap: () {
          String targetPath = menu['path'] ?? '/';
          if (targetPath.startsWith('/category')) {
            targetPath = targetPath.replaceFirst('/category', '');
          }
          if (targetPath.isEmpty) targetPath = '/';

          context.go(targetPath);
          searchContentRead.initState();
          Navigator.pop(context); // 페이지 이동 후 드로어 닫기
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(menu['title'] ?? '',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ),
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: rawChildren
          .map<Widget>((child) => buildDrawerMenu(
              context, ref, Map<String, dynamic>.from(child as Map)))
          .toList(),
    );
  }

  // 💻 [반응형 푸터 구조 사수]: 문구 100% 매핑
  static Widget buildInfoWrap() {
    return Wrap(
      spacing: 15,
      runSpacing: 8,
      children: [
        _buildInfoText('상호명', '원앤그레인'),
        _buildInfoText('사업자 등록번호', '543-02-04088'),
        _buildInfoText('통신판매업 신고번호', '2026-화도수동-0435'),
        _buildInfoText('개인정보보호책임자', '원앤그레인'),
      ],
    );
  }

  // static Widget buildCustomerInfoContent() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildCustomerInfoRow('상담/주문 이메일', 'morepick@naver.com'),
  //       const SizedBox(height: 15),
  //       const Text('CS운영시간',
  //           style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 12,
  //               color: Colors.black87)),
  //       const SizedBox(height: 4),
  //       const Text('오전 9시 ~ 오후 5시',
  //           style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
  //     ],
  //   );
  // }
  // 🌟 [완치]: 카카오톡 채널톡 바로가기 링크 및 아이콘이 이쁘게 탑재된 고객센터 컴포넌트
  static Widget buildCustomerInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            // 💡 웹 브라우저 환경에서 깔끔하게 새 탭(_blank)을 열어 카카오톡 채널로 점프시킵니다.
            html.window.open(kakaoUrl, '_blank');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              // 카카오톡 시그니처 옐로우 컬러와 폰트 디자인 밸런스 튜닝
              color: const Color(0xFFFEE500),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxConstraints.expand().maxWidth > 0 // 컴파일 에러 방지용 가벼운 섀도우
                    ? BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    : const BoxShadow(),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min, // 글자 길이에 딱 맞게 쫀득하게 축소
              children: [
                Icon(
                  Icons.chat_bubble_rounded, // 카카오톡 느낌의 대화창 아이콘
                  size: 14,
                  color: Color(0xFF191919),
                ),
                SizedBox(width: 6),
                Text(
                  '모어픽 채널톡 바로가기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191919), // 카카오톡 전용 다크 그레이 글자색
                  ),
                ),
              ],
            ),
          ),
        ),
        // const SizedBox(height: 15),
        // _buildCustomerInfoRow('상담/주문 이메일', 'morepick@naver.com'),
        const SizedBox(height: 15),
        const Text('CS운영시간',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87)),
        const SizedBox(height: 4),
        const Text('오전 9시 ~ 오후 5시',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666))),

        // 🌟 [새 기능 도킹]: 고객센터 안내 맨 하단에 카카오톡 채널톡 바로가기 배치
      ],
    );
  }

  ///```
  /// Custom TextButton
  ///```
  static Widget customTextButton(
      {required String title,
      required VoidCallback onPressed,
      EdgeInsetsGeometry? padding,
      FontWeight? fontWeight = FontWeight.normal,
      Color? backgroundColor = Colors.white}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0)),
          side: BorderSide(width: 0.5, color: Colors.black.withOpacity(0.3))),
      child: Text(title,
          style: TextStyle(color: Colors.black, fontWeight: fontWeight)),
    );
  }

// 🌟 [완치]: 화면 폭이 좁아져도 절대 오버플로우가 나지 않도록 'Wrap' 설계를 도입한 결제정보 섹션
  static Widget buildPaymentInfoContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('입금 계좌', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),

        // 🌟 [완치 포인트]: Row 대신 Wrap을 사용하여, 화면 우측 경계선에 닿으면
        // 텍스트와 복사 버튼이 에러 없이 자동으로 다음 줄로 내려앉도록(자동 줄바꿈) 방어합니다!
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4, // 가로 사이 간격
          runSpacing: 6, // 줄바꿈 시 세로 간격
          children: [
            const Text(
              '은행 ',
              style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            ),
            const Text(
              '카카오뱅크 ',
              style: TextStyle(fontSize: 12),
            ),

            // 💡 터치 복사 영역
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () async {
                await Clipboard.setData(
                    const ClipboardData(text: accountNumber));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 계좌번호($accountNumber)가 클립보드에 복사되었습니다!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6FA5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      accountNumber,
                      style: TextStyle(
                        fontSize: 11, // 💡 가독성을 깨지 않는 선에서 폰트 크기를 살짝 다듬어 컴팩트화
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A6FA5),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.copy_rounded,
                        size: 11, color: Color(0xFF4A6FA5)),
                  ],
                ),
              ),
            ),

            const Text(
              ' 문은미(원앤그레인)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 11, color: Colors.black87, fontFamily: 'NotoSansKR'),
        children: [
          TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
              text: value, style: const TextStyle(color: Color(0xFF666666))),
        ],
      ),
    );
  }

  static Widget _buildCustomerInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label  ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  static Widget customFooter(BuildContext context, WidgetRef ref,
      {required bool isMobile}) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F6FA),
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomWidget.customLogo(context, ref, fontSize: 28),
          const SizedBox(height: 25),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              CustomWidget.buildFooterMenu('회사소개'),
              CustomWidget.buildFooterMenu('이용약관'),
              CustomWidget.buildFooterMenu('개인정보처리방침', isBold: true),
              CustomWidget.buildFooterMenu('이용안내'),
            ],
          ),
          const SizedBox(height: 35),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildFooterSectionTitle('쇼핑몰 기본정보'),
                    const SizedBox(height: 12),
                    buildInfoWrap(),
                    const SizedBox(height: 35),
                    buildFooterSectionTitle('고객센터 정보'),
                    const SizedBox(height: 12),
                    buildCustomerInfoContent(),
                    const SizedBox(height: 35),
                    buildFooterSectionTitle('결제정보'),
                    const SizedBox(height: 12),
                    buildPaymentInfoContent(context),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildFooterSectionTitle('쇼핑몰 기본정보'),
                          const SizedBox(height: 15),
                          buildInfoWrap(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildFooterSectionTitle('고객센터 정보'),
                          const SizedBox(height: 15),
                          buildCustomerInfoContent(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildFooterSectionTitle('결제정보'),
                          const SizedBox(height: 15),
                          buildPaymentInfoContent(context),
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
    );
  }

  // 🌟 1. Top 버튼: 사라질 때 높이도 0으로 줄어들도록 AnimatedSize 적용
  static Widget customFloatingBtn(
      {required ValueNotifier<bool> showButton,
      required ScrollController scrollController}) {
    final isHovered = useState(false);

    // 💡 AnimatedSize를 통해 showButton이 false일 때 버튼 크기를 0으로 축소시킵니다.
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: showButton.value
          ? Padding(
              padding: const EdgeInsets.only(top: 12), // 채널톡 버튼과 Top 버튼 사이의 간격
              child: MouseRegion(
                onEnter: (_) => isHovered.value = true,
                onExit: (_) => isHovered.value = false,
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform:
                      Matrix4.translationValues(0, isHovered.value ? -4 : 0, 0),
                  child: FloatingActionButton.small(
                    heroTag: 'top_button',
                    backgroundColor: Colors.white,
                    elevation: isHovered.value ? 6 : 2,
                    onPressed: () {
                      if (scrollController.hasClients) {
                        scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuart,
                        );
                      }
                    },
                    child: const Icon(Icons.arrow_upward,
                        color: Colors.black, size: 18),
                  ),
                ),
              ),
            )
          : const SizedBox(width: 40, height: 0), // 💡 숨겨졌을 때는 높이를 0으로 제거!
    );
  }

  ///```
  /// Dialog custom Form
  /// width, height만 조절 하여 Form 생성 (가로, 세로 스크롤 가능)
  ///```
  // static Widget dialogCustomForm(
  //     {double width = 500, double height = 500, required Widget child}) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Container(
  //       decoration: BoxDecoration(
  //           color: Colors.white,
  //           border:
  //               Border.all(width: 0.3, color: Colors.black.withOpacity(0.5))),
  //       width: width,
  //       height: height,
  //       child: SingleChildScrollView(child: child),
  //     ),
  //   );
  // }
  // static Widget dialogCustomForm({
  //   double? width,
  //   double? height,
  //   required Widget child,
  // }) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         border: Border.all(
  //           width: 0.3,
  //           color: Colors.black.withOpacity(0.5),
  //         ),
  //       ),
  //       width: width,
  //       height: height,
  //       // 🌟 [완치 가드]: width가 null(동적)일 때 IntrinsicWidth가 올바르게 작동하도록 제어하되,
  //       // 자식들의 Row(Expanded)가 무한대로 폭주하여 크래시가 나지 않도록 최대 가로 범위를 명확히 제한합니다!
  //       child: ConstrainedBox(
  //         constraints: BoxConstraints(
  //           // 수동 지정된 width가 없으면 최소 320, 최대 600까지 내부에서 늘어나도록 락을 겁니다.
  //           minWidth: width ?? 320,
  //           maxWidth: width ?? 600,
  //         ),
  //         child: SingleChildScrollView(child: child),
  //       ),
  //     ),
  //   );
  // }

  static Widget dialogCustomForm({
    double? width,
    double? height,
    required Widget child,
    bool isScrollable =
        false, // 🌟 [완치 가드]: 기본값은 false(반응형). 가로 스크롤이 진짜 필요할 때만 true로 켭니다.
  }) {
    // 💡 1단계: 가로 스크롤이 필요 없는 일반 팝업은 스크롤 없이 고정/반응형 컨테이너를 즉시 리턴
    final Widget coreContainer = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 0.3,
          color: Colors.black.withOpacity(0.5),
        ),
      ),
      width: width,
      height: height,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? 320,
          maxWidth: width ?? 600,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );

    // 💡 2단계: 가로 스크롤 옵션이 켜져 있을 때만 무한대 constraints 가로 스크롤러로 감쌉니다.
    if (isScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: coreContainer,
      );
    }

    return coreContainer;
  }

  // static customDialogTitle(BuildContext context, WidgetRef ref,
  //     {required String title,
  //     bool isShowOtherBtn = false,
  //     bool isShowCloseBtn = false,
  //     VoidCallback? otherBtnOnPressed,
  //     VoidCallback? onClosePressed,
  //     Icon otherIcon = const Icon(Icons.close, color: Colors.white)}) {
  //   final globalFunctionRead = ref.read(globalProviderFunction.notifier);
  //   return Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 8),
  //       height: 40,
  //       color: Colors.deepPurple[100],
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(title, style: const TextStyle(color: Colors.white)),
  //           Row(
  //             children: [
  //               isShowOtherBtn
  //                   ? IconButton(onPressed: otherBtnOnPressed, icon: otherIcon)
  //                   : Container(),
  //               isShowCloseBtn
  //                   ? IconButton(
  //                       onPressed: onClosePressed ??
  //                           () {
  //                             globalFunctionRead.dialogCloseFn(context);
  //                           },
  //                       icon: const Icon(Icons.close, color: Colors.white))
  //                   : Container()
  //             ],
  //           )
  //         ],
  //       ));
  // }

  static Widget customDialogTitle(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    bool isShowOtherBtn = false,
    bool isShowCloseBtn = false,
    VoidCallback? otherBtnOnPressed,
    VoidCallback? onClosePressed,
    Icon otherIcon = const Icon(Icons.close, color: Colors.white),
  }) {
    final globalFunctionRead = ref.read(globalProviderFunction.notifier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 40,
      color: Colors.deepPurple[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🌟 [완치 포인트]: 타이틀이 무한정 길어져도 우측 버튼 영역을 침범하지 않고
          // 안전하게 말줄임표(...)로 제한되도록 가드를 칩니다.
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis, // 글자가 넘치면 '...' 처리
              maxLines: 1, // 한 줄로 고정
            ),
          ),
          const SizedBox(width: 8), // 타이틀과 버튼 사이 최소 여백
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isShowOtherBtn
                  ? IconButton(onPressed: otherBtnOnPressed, icon: otherIcon)
                  : Container(),
              isShowCloseBtn
                  ? IconButton(
                      onPressed: onClosePressed ??
                          () {
                            globalFunctionRead.dialogCloseFn(context);
                          },
                      icon: const Icon(Icons.close, color: Colors.white),
                    )
                  : Container()
            ],
          )
        ],
      ),
    );
  }

  static Widget buildShimmerPlaceholder(
      {double? width, double? height, double borderRadius = 0}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0), // 바탕이 되는 연한 회색
      highlightColor: const Color(0xFFF5F5F5), // 지나가는 반짝이는 빛 색상
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white, // 배경 영역
      ),
    );
  }

  // // 🌟 PC 환경: 캡슐 통합형 [ 💬 모어픽 채널톡 ]
  // // 🌟 모바일 환경: 원형 아이콘 [ 💬 ]
  // static Widget buildChannelTalkFloatingBtn(BuildContext context) {
  //   final bool mobileMode = isMobile(context); // 모바일 여부 감지

  //   return Material(
  //     elevation: 4,
  //     borderRadius: BorderRadius.circular(24),
  //     color: const Color(0xFFFEE500), // 카카오/채널톡 시그니처 옐로우
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(24),
  //       onTap: () {
  //         // 💬 채널톡 URL 이동 또는 SDK 호출
  //         const String kakaoUrl = 'https://pf.kakao.com/_xbyxdwX';

  //         // 💡 웹 브라우저 환경에서 깔끔하게 새 탭(_blank)을 열어 카카오톡 채널로 점프시킵니다.
  //         html.window.open(kakaoUrl, '_blank');
  //       },
  //       child: AnimatedContainer(
  //         duration: const Duration(milliseconds: 200),
  //         padding: EdgeInsets.symmetric(
  //           horizontal: mobileMode ? 10 : 14,
  //           vertical: mobileMode ? 10 : 9,
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Icon(
  //               Icons.chat_bubble_rounded,
  //               color: Colors.black,
  //               size: 16,
  //             ),

  //             // 🌟 모바일이 아닐 때(PC/웹)만 텍스트 노출
  //             if (!mobileMode) ...[
  //               const SizedBox(width: 8),
  //               const Text(
  //                 '모어픽 채널톡',
  //                 style: TextStyle(
  //                   color: Colors.black,
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.bold,
  //                   letterSpacing: -0.3,
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // 📁 lib/global/custom_widget/custom_widget.dart

  static Widget buildChannelTalkFloatingBtn(BuildContext context) {
    final bool mobileMode = isMobile(context);

    if (mobileMode) {
      // 📱 모바일: 단순 원형 small FAB
      return FloatingActionButton.small(
        heroTag: 'channelTalkBtn',
        elevation: 3,
        backgroundColor: const Color(0xFFFEE500),
        // shape: const CircleBorder(),
        onPressed: () {
          // 채널톡 열기

          // 💡 웹 브라우저 환경에서 깔끔하게 새 탭(_blank)을 열어 카카오톡 채널로 점프시킵니다.
          html.window.open(kakaoUrl, '_blank');
        },
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.black,
          size: 18,
        ),
      );
    }

    // 💻 PC/웹: small 버전 높이(40px)에 맞춘 슬림 캡슐 FAB
    return SizedBox(
      height: 40, // 🌟 small FAB 기본 높이인 40px로 슬림하게 강제 지정!
      child: FloatingActionButton.extended(
        heroTag: 'channelTalkBtn',
        elevation: 3,
        backgroundColor: const Color(0xFFFEE500),
        // 상하 패딩과 최소 크기 제약을 40px 높이에 맞춰 축소
        extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          // 채널톡 열기

          // 💡 웹 브라우저 환경에서 깔끔하게 새 탭(_blank)을 열어 카카오톡 채널로 점프시킵니다.
          html.window.open(kakaoUrl, '_blank');
        },
        icon: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.black,
          size: 17,
        ),
        label: const Text(
          '모어픽 채널톡',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  static Widget buildCartBadgeIcon(BuildContext context, int cartCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.assignment_outlined,
              color: Colors.black, size: 26),
          onPressed: () {
            NavigationService().routerGo(context, OrderFormScreenRoute);
          },
        ),
        if (cartCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$cartCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
