import 'package:flutter/material.dart';
import 'package:more_pic/data/menu_data.dart';

class CustomWidget {
  static customScaffold(BuildContext context,
      {required Widget body, Widget? drawer}) {
    return Scaffold(body: body, drawer: customDrawer(context, menuData));
  }

  static customSubMenuItemBtn({
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

  static customMenuItemBtn({
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
  static Widget customDrawer(
      BuildContext context, List<Map<String, dynamic>> menuData) {
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
                buildTopMenu('회원가입'),
                buildDivider(),
                buildTopMenu('로그인'),
                buildDivider(),
                buildTopMenu('주문조회'),
                buildDivider(),
                buildTopMenu('최근본상품'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuData.map((menu) => buildDrawerMenu(menu)).toList(),
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

  static Widget buildDrawerMenu(Map<String, dynamic> menu) {
    if (menu['children'] == null || (menu['children'] as List).isEmpty) {
      return ListTile(
          title: Text(menu['title'],
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          dense: true,
          onTap: () {});
    }
    return ExpansionTile(
      title: Text(menu['title'],
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: (menu['children'] as List)
          .map<Widget>((child) => buildDrawerMenu(child))
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
}
