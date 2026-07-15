import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/global_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;

// 💡 [2] 고정 레이아웃과 반응형 컨트롤러를 품은 스캐폴드
class CustomScaffold extends HookConsumerWidget {
  final Widget Function(BuildContext context, ScrollController scrollController)
      bodyBuilder;
  final String category;
  final bool showSearchIcon;

  const CustomScaffold({
    super.key,
    required this.bodyBuilder,
    required this.category,
    this.showSearchIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    final paginatedState = ref.watch(paginatedProductProvider(category));
    final filterProducts = paginatedState.maybeWhen(
      data: (stateData) => stateData.items.cast<ProductModel>(),
      orElse: () => const <ProductModel>[],
    );

    // 🌟 파이어베이스 원격 실시간 메뉴판 장부 구독 감시
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
                          if (showSearchIcon)
                            IconButton(
                              icon:
                                  const Icon(Icons.search, color: Colors.black),
                              onPressed: () => ref
                                  .read(searchBarOpenProvider.notifier)
                                  .open(),
                            )
                          else
                            const SizedBox(width: 40),
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
            SlidingSearchBar(currentScreenItems: filterProducts)
          ],
        ),
        floatingActionButton: CustomWidget.customFloatingBtn(
            showButton: showButton, scrollController: scrollController));
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
    final adminWatch = ref.watch(adminSettingsProvider);
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          SafeArea(
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
          if (adminWatch) ...[
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
          ],
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuData
                  .map((menu) => buildDrawerMenu(context, ref, menu))
                  .toList(),
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

  // 🌟 [이전 작동 코드 구조 100% 복구 이식]: 타입 꼬임 방벽 및 파이어베이스 트리 재귀 순회 파싱
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
      title: Text(menu['title'] ?? '',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
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
            const String kakaoUrl = 'https://pf.kakao.com/_xbyxdwX';

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

// 🌟 [완치]: 계좌번호를 클릭하면 자동으로 클립보드에 복사해 주는 스마트 컴포넌트 개조
  static Widget buildPaymentInfoContent(BuildContext context) {
    const String accountNumber = '3333-37-7919709'; // 👈 복사될 순수 계좌번호 타깃

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('무통장 계좌정보',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              '은행 ',
              style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            ),
            const Text(
              '카카오뱅크 ',
              style: TextStyle(fontSize: 12),
            ),

            // 🌟 [핵심 가드]: 계좌번호 구역을 클릭(터치)할 수 있는 감지 레이어로 감쌉니다.
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () async {
                // 1️⃣ 구글 안드로이드 / iOS / 웹 브라우저 통합 클립보드에 계좌번호 강제 수혈!
                await Clipboard.setData(
                    const ClipboardData(text: accountNumber));

                // 2️⃣ 사용자에게 복사가 완료되었음을 친절하게 스낵바로 알림 전파
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .clearSnackBars(); // 기존 스낵바 밀어내기 소독
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 계좌번호($accountNumber)가 클립보드에 복사되었습니다!'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating, // 이쁘게 떠오르는 스타일 가드
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6FA5)
                      .withOpacity(0.08), // 마우스 가져갔을 때 힌트 팁 색상
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      accountNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A6FA5), // 💡 클릭 가능한 녀석임을 시각적으로 분리
                        decoration:
                            TextDecoration.underline, // 밑줄 쳐서 가독성 100점 튜닝
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.copy_rounded,
                        size: 12, color: Color(0xFF4A6FA5)), // 복사 유도 아이콘 도킹
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

  static Widget customFloatingBtn(
      {required ValueNotifier<bool> showButton,
      required ScrollController scrollController}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showButton.value ? 1.0 : 0.0,
      child: showButton.value
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (scrollController.hasClients) {
                  scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic);
                }
              },
              child:
                  const Icon(Icons.arrow_upward_rounded, color: Colors.black87),
            )
          : const SizedBox.shrink(),
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
  static Widget dialogCustomForm({
    double? width,
    double? height,
    required Widget child,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            width: 0.3,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        width: width,
        height: height,
        // 🌟 [완치 가드]: width가 null(동적)일 때 IntrinsicWidth가 올바르게 작동하도록 제어하되,
        // 자식들의 Row(Expanded)가 무한대로 폭주하여 크래시가 나지 않도록 최대 가로 범위를 명확히 제한합니다!
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // 수동 지정된 width가 없으면 최소 320, 최대 600까지 내부에서 늘어나도록 락을 겁니다.
            minWidth: width ?? 320,
            maxWidth: width ?? 600,
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
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
}
