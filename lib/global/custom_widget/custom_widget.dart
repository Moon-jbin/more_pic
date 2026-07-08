import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:more_pic/provider/global_provider.dart';
import 'package:more_pic/provider/product_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router_name.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 💡 [2] 고정 레이아웃과 반응형 컨트롤러를 품은 스캐폴드
class CustomScaffold extends HookConsumerWidget {
  final Widget Function(BuildContext context, ScrollController scrollController)
      bodyBuilder;
  final List<ProductItem> itemData;
  final String category;

  const CustomScaffold(
      {super.key,
      required this.bodyBuilder,
      required this.itemData,
      required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    final allProducts = ref.watch(productManagementProvider);
    final FilterProducts =
        allProducts.where((item) => item.categoryName == category).toList();

    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          if (scrollController.offset > 150) {
            if (!showButton.value) showButton.value = true;
          } else {
            if (showButton.value) showButton.value = false;
          }

          // 2. 💡 [새로 추가]: 조금이라도 스크롤이 내려가면 그림자 상태 ON, 맨 위면 OFF
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
        drawer: CustomWidget.customDrawer(context, ref, menuData),

        // 💡 [핵심 변경]: 공통 CustomScrollView를 여기서 선언하여 전체 스크롤을 하나로 제어합니다.
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                // 📌 섹션 A: 스크롤하면 위로 올라가서 자연스럽게 사라지는 최상단 배너 영역
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

                // 📌 섹션 B: 스크롤을 아무리 내려도 화면 최상단에 고정(Sticky)되는 내비게이션 헤더 영역
                SliverPersistentHeader(
                  pinned: true, // 상단 고정 트루!
                  delegate: SliverHeaderDelegate(
                    isScrolled: isScrolled.value,
                    height:
                        isMobile(context) ? 70 : 110, // 헤더 컴포넌트 실측 높이에 맞게 조정하세요
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
                          // SizedBox(width: isMobile(context) ? 40 : 0)
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.black),
                            onPressed: () {
                              ref.read(searchBarOpenProvider.notifier).open();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 📌 섹션 C: 각 화면에서 던져주는 알맹이(ProductListPage 등)가 들어오는 동적 영역
                SliverToBoxAdapter(
                  child: bodyBuilder(context, scrollController),
                ),
              ],
            ),
            SlidingSearchBar(currentScreenItems: FilterProducts)
          ],
        ),

        // 💡 [두 번째 디자인]: 존재감이 확실해진 흑백 반전 딥 섀도우 Top 버튼
        floatingActionButton: CustomWidget.customFloatingBtn(
            showButton: showButton, scrollController: scrollController));
  }
}

class CustomWidget {
  static Widget customLogo(BuildContext context, WidgetRef ref,
      {double fontSize = 22, double? letterSpacing, bool isDrawer = false}) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    String imgPath = 'images/more_pic_logo.png';

    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        NavigationService().routerGo(context, MainRoute);
        searchContentRead.initState();
      },
      child: Image.asset(
          width: isMobile(context) || isDrawer ? 120 : 240, imgPath),

      // Text(
      //   'MORE PIC',
      //   style: TextStyle(
      //       fontSize: fontSize,
      //       fontWeight: FontWeight.w900,
      //       fontStyle: FontStyle.italic,
      //       letterSpacing: letterSpacing),
      // ),
    );
  }

  static Widget customSubMenuItemBtn({
    Key? key,
    void Function(bool)? onHover,
    void Function(bool)? onFocusChange,
    void Function()? onOpen,
    void Function()? onClose,
    MenuController? controller,
    ButtonStyle? style,
    MenuStyle? menuStyle,
    Offset? alignmentOffset = const Offset(0, -8),
    Clip clipBehavior = Clip.hardEdge,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    Widget? leadingIcon,
    Widget? trailingIcon,
    Size? fixedSize,
    required List<Widget> menuChildren,
    required Widget? child,
  }) {
    return SubmenuButton(
      key: key,
      onHover: onHover,
      onFocusChange: onFocusChange,
      onOpen: onOpen,
      onClose: onClose,
      controller: controller,
      style: style ??
          TextButton.styleFrom(
            iconColor: Colors.grey,
            alignment: Alignment.center,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            backgroundColor: Colors.white,
            // 기본 스타일을 슬림하게 설정
            minimumSize: const Size(0, 50),
            fixedSize: fixedSize,
            // padding: const EdgeInsets.symmetric(horizontal: 10),
            // visualDensity: const VisualDensity(vertical: -4),
            // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      menuStyle: menuStyle,
      alignmentOffset: alignmentOffset,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      statesController: statesController,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      menuChildren: menuChildren,
      child: child,
    );
  }

  static Widget customMenuItemBtn({
    required String title,
    void Function()? onPressed,
    Widget? leadingIcon,
    EdgeInsetsGeometry? padding =
        const EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
  }) {
    return MenuItemButton(
        leadingIcon: leadingIcon,
        style: MenuItemButton.styleFrom(
          padding: padding,
          backgroundColor: Colors.white,
          // 1. 위아래 여백 압축 (가장 효과가 큼)
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),

          // 3. 최소 높이 지정 (메뉴바 높이와 맞추면 통일감이 생깁니다)
          minimumSize: const Size(0, 45),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ));
  }

  //Drawer 위젯
  static Widget customDrawer(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> menuData) {
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
          // const Divider(height: 1),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 10),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       buildTopMenu('회원가입'),
          //       buildDivider(),
          //       buildTopMenu('로그인'),
          //       buildDivider(),
          //       buildTopMenu('주문조회'),
          //       buildDivider(),
          //       buildTopMenu('최근본상품'),
          //     ],
          //   ),
          // ),
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

  // --- 기존의 헬퍼 메서드들 (_buildTopMenu, _buildDivider 등은 그대로 유지하세요) ---
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

  static Widget buildDrawerMenu(
      BuildContext context, WidgetRef ref, Map<String, dynamic> menu) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    if (menu['children'] == null || (menu['children'] as List).isEmpty) {
      return ListTile(
          title: Text(menu['title'],
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          dense: true,
          onTap: () {
            NavigationService().routerGo(context, menu['path'] ?? '/');
            searchContentRead.initState();
          });
    }
    return ExpansionTile(
      title: Text(menu['title'],
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: (menu['children'] as List)
          .map<Widget>((child) => buildDrawerMenu(context, ref, child))
          .toList(),
    );
  }

  static Widget buildInfoWrap() {
    return Wrap(
      spacing: 15,
      runSpacing: 8,
      children: [
        _buildInfoText('상호명', '원앤그레인'),
        _buildInfoText('대표자명', '모어픽'),
        _buildInfoText('사업장 주소', '00000 모어픽'),
        _buildInfoText('대표 전화', '01080373833'),
        _buildInfoText('사업자 등록번호', '5430204088'),
        _buildInfoText('통신판매업 신고번호', '기타'),
        _buildInfoText('개인정보보호책임자', '모어픽'),
      ],
    );
  }

  static Widget buildCustomerInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomerInfoRow('상담/주문 전화', '01080373833'),
        const SizedBox(height: 8),
        _buildCustomerInfoRow('상담/주문 이메일', 'morepic@naver.com'),
        const SizedBox(height: 15),
        const Text('CS운영시간',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87)),
      ],
    );
  }

  static Widget buildPaymentInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('무통장 계좌정보',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('은행  ',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const Text('0000-000-00000  예금주', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  static Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: Colors.black87),
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
        Text(value,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  ///푸터 위젯
  static Widget customFooter(BuildContext context, WidgetRef ref,
      {required bool isMobile}) {
    return // [3] 하단 푸터 (Footer) 영역
        Container(
      width: double.infinity,
      color: const Color(0xFFF5F6FA),
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomWidget.customLogo(context, ref, fontSize: 28),
          const SizedBox(height: 30),
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
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomWidget.buildFooterSectionTitle('쇼핑몰 기본정보'),
                    const SizedBox(height: 10),
                    CustomWidget.buildInfoWrap(),
                    const SizedBox(height: 30),
                    CustomWidget.buildFooterSectionTitle('고객센터 정보'),
                    const SizedBox(height: 10),
                    CustomWidget.buildCustomerInfoContent(),
                    const SizedBox(height: 30),
                    CustomWidget.buildFooterSectionTitle('결제정보'),
                    const SizedBox(height: 10),
                    CustomWidget.buildPaymentInfoContent(),
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
                          CustomWidget.buildFooterSectionTitle('쇼핑몰 기본정보'),
                          const SizedBox(height: 15),
                          CustomWidget.buildInfoWrap(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomWidget.buildFooterSectionTitle('고객센터 정보'),
                          const SizedBox(height: 15),
                          CustomWidget.buildCustomerInfoContent(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomWidget.buildFooterSectionTitle('결제정보'),
                          const SizedBox(height: 15),
                          CustomWidget.buildPaymentInfoContent(),
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
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: 1.0, // 호버 시 버튼이 살짝 커짐
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // 호버 시 블랙, 평소에는 화이트로 완벽 반전
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEEEEEE),
                        width: 1.0,
                      ),
                      // 💡 유저 피드백 반영: 한눈에 봐도 부각되는 딥 블랙 그림자 튜닝
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16), // 농도 부스팅
                          blurRadius: 10, // 더 풍성하게 퍼지도록
                          offset: const Offset(0, 4), // 입체감 차별화
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      // 아이콘 컬러도 배경에 맞춰 반전
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  ///```
  /// Dialog custom Form
  /// width, height만 조절 하여 Form 생성 (가로, 세로 스크롤 가능)
  ///```
  static Widget dialogCustomForm(
      {double width = 500, double height = 500, required Widget child}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border.all(width: 0.3, color: Colors.black.withOpacity(0.5))),
        width: width,
        height: height,
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  ///```
  /// Dialog Title Widget
  /// @param {String} title - 다이얼로그 제목
  /// @param {bool} isShowOtherBtn - 또 다른 아이콘 보일지 여부
  /// @param {VoidCallback?} otherBtnOnPressed - 또 다른 아이콘버튼 onPressed
  /// @param {Icon} otherIcon - 또 다른 아이콘 위젯 [기본값 : Icons.close]
  ///```
  static customDialogTitle(BuildContext context, WidgetRef ref,
      {required String title,
      bool isShowOtherBtn = false,
      bool isShowCloseBtn = false,
      VoidCallback? otherBtnOnPressed,
      VoidCallback? onClosePressed,
      Icon otherIcon = const Icon(Icons.close, color: Colors.white)}) {
    final globalFunctionRead = ref.read(globalProviderFunction.notifier);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 40,
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            Row(
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
                        icon: const Icon(Icons.close, color: Colors.white))
                    : Container()
              ],
            )
          ],
        ));
  }
}
