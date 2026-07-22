// FILE: lib/screen/order_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/cart_provider.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'dart:html' as html;

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var newString = '';

    if (text.length <= 3) {
      newString = text;
    } else if (text.length <= 7) {
      newString = '${text.substring(0, 3)}-${text.substring(3)}';
    } else if (text.length <= 11) {
      newString =
          '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7)}';
    } else {
      newString =
          '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class OrderFormScreen extends HookConsumerWidget {
  const OrderFormScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final addressController = useTextEditingController();

    final isCombinedShipping = useState<bool>(false);

    final formatCurrency =
        NumberFormat.currency(locale: "ko_KR", symbol: "", decimalDigits: 0);

    // 🚀 정가(1.7배) 총합과 회원 적용 실총합 계산
    final originalTotalPrice = cartItems.fold<int>(
      0,
      (sum, item) => sum + ((item.price * 1.7).toInt() * item.quantity),
    );

    final productTotalPrice = cartItems.fold<int>(
      0,
      (sum, item) {
        final itemDisplayPrice =
            isLoggedIn ? item.price : (item.price * 1.7).toInt();
        return sum + (itemDisplayPrice * item.quantity);
      },
    );

    final shippingFee = isCombinedShipping.value ? 0 : 3500;
    final finalTotalPrice = productTotalPrice + shippingFee;

    // 카톡 전송용 텍스트 (완성형)
    String generateOrderText() {
      final buffer = StringBuffer();
      buffer.writeln('이름 : ${nameController.text.trim()}');
      buffer.writeln('핸드폰 : ${phoneController.text.trim()}');
      buffer.writeln('주소 : ${addressController.text.trim()}');
      buffer.writeln('………………………………');

      for (var item in cartItems) {
        final itemDisplayPrice =
            isLoggedIn ? item.price : (item.price * 1.7).toInt();
        final itemTotal = itemDisplayPrice * item.quantity;
        buffer.writeln(
            '- ${item.name}/${item.color}/${item.size}/${item.quantity}/${formatCurrency.format(itemTotal)}');
      }

      buffer.writeln('………………………………');
      buffer.writeln('상품 총 금액');
      buffer.writeln('₩ ${formatCurrency.format(productTotalPrice)}');
      buffer.writeln('');
      buffer.writeln('배송비');
      if (isCombinedShipping.value) {
        buffer.writeln('기존건합배');
      } else {
        buffer.writeln('₩ ${formatCurrency.format(shippingFee)}');
      }
      buffer.writeln('>합배송은 배송비 0원입니다.');
      buffer.writeln(' "기존건합배" 기재');
      buffer.writeln('');
      buffer.writeln('배송비포함 총 입금금액');
      buffer.writeln('₩ ${formatCurrency.format(finalTotalPrice)}');
      buffer.writeln('………………………………');
      buffer.write('예금주)3333377919709 카카오뱅크 문은미');

      return buffer.toString();
    }

    void copyAndProcessOrder() {
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주문서에 담긴 상품이 없습니다.')),
        );
        return;
      }

      if (formKey.currentState!.validate()) {
        final orderText = generateOrderText();

        Clipboard.setData(ClipboardData(text: orderText));

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.content_copy_rounded,
                    color: Colors.black87, size: 24),
                SizedBox(width: 8),
                Text('주문서 복사 완료',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '양식에 맞춘 주문서 텍스트가 복사되었습니다!\n채널톡 상담창에 붙여넣기(Ctrl+V / 긴 터치) 해주세요.',
                  style: TextStyle(height: 1.4, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      orderText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('닫기',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                ),
                onPressed: () {
                  html.window.open(kakaoUrl, '_blank');
                },
                icon: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.black, size: 18),
                label: const Text('채널톡 열기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        );
      }
    }

    return CustomScaffold(
      category: '주문서 작성',
      showSearchIcon: true,
      bodyBuilder: (context, scrollController) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isLoggedIn)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer,
                                color: Colors.red.shade400, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '로그인 시 파격적인 할인가 적용이 됩니다!',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: () {
                                showAdminLoginDialog(context);
                              },
                              child: const Text('로그인',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.assignment_outlined,
                                  color: Colors.black87, size: 24),
                              SizedBox(width: 8),
                              Text(
                                '주문서 작성',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '주문자 정보를 입력 후 주문서를 복사하여 채널톡으로 전달해 주세요.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (cartItems.isEmpty) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.remove_shopping_cart_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '주문서에 담긴 상품이 없습니다.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        '주문자 정보',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '이름 :',
                          hintText: '성함을 입력해 주세요',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: '핸드폰 :',
                          hintText: '010-0000-0000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '핸드폰 번호를 입력해 주세요.';
                          }
                          if (value.trim().length < 12) {
                            return '올바른 전화번호를 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '주소 :',
                          hintText: '배송 받으실 전체 주소를 입력해 주세요',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '주소를 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '주문LIST',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => cartNotifier.clearCart(),
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.grey),
                            label: const Text('전체 비우기',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ),
                        ],
                      ),
                      Text(
                        '[상품명/색상/사이즈/수량/금액]',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                      const Divider(),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          final int itemOrigPrice = (item.price * 1.7).toInt();
                          final int itemDisplayPrice =
                              isLoggedIn ? item.price : itemOrigPrice;
                          final int itemTotal =
                              itemDisplayPrice * item.quantity;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.name}/${item.color}/${item.size}/${item.quantity}개',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // 🚀 리스트 내역 금액 표현 (로그인 시 취소선 + 회원가)
                                      if (isLoggedIn) ...[
                                        Text(
                                          '₩ ${formatCurrency.format(itemOrigPrice * item.quantity)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            decoration: TextDecoration
                                                .lineThrough, // 취소선
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '₩ ${formatCurrency.format(itemTotal)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          '₩ ${formatCurrency.format(itemTotal)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          cartNotifier.updateQuantity(
                                              item.id, item.quantity - 1);
                                        }
                                      },
                                    ),
                                    Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 18),
                                      onPressed: () {
                                        cartNotifier.updateQuantity(
                                            item.id, item.quantity + 1);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.grey),
                                      onPressed: () =>
                                          cartNotifier.removeItem(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('상품 총 금액',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),

                                // 🚀 정산 박스 금액 표시
                                if (isLoggedIn)
                                  Row(
                                    children: [
                                      Text(
                                        '₩ ${formatCurrency.format(originalTotalPrice)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₩ ${formatCurrency.format(productTotalPrice)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    '₩ ${formatCurrency.format(productTotalPrice)}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('배송비',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    // const SizedBox(width: 8),
                                    // InkWell(
                                    //   onTap: () {
                                    //     isCombinedShipping.value =
                                    //         !isCombinedShipping.value;
                                    //   },
                                    //   child: Row(
                                    //     children: [
                                    //       SizedBox(
                                    //         width: 24,
                                    //         height: 24,
                                    //         child: Checkbox(
                                    //           value: isCombinedShipping.value,
                                    //           activeColor: Colors.black,
                                    //           onChanged: (val) {
                                    //             isCombinedShipping.value =
                                    //                 val ?? false;
                                    //           },
                                    //         ),
                                    //       ),
                                    //       const SizedBox(width: 4),
                                    //       const Text(
                                    //         '기존건합배 (배송비 0원)',
                                    //         style: TextStyle(
                                    //             fontSize: 12,
                                    //             color: Colors.blueAccent,
                                    //             fontWeight: FontWeight.w600),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                                Text(
                                  isCombinedShipping.value
                                      ? '₩ 0'
                                      : '₩ ${formatCurrency.format(shippingFee)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isCombinedShipping.value
                                        ? Colors.blueAccent
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.only(top: 4),
                            //   child: Text(
                            //     '>합배송은 배송비 0원입니다. "기존건합배" 기재',
                            //     style: TextStyle(
                            //         fontSize: 12, color: Colors.grey.shade600),
                            //   ),
                            // ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '배송비포함 총 입금금액',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₩ ${formatCurrency.format(finalTotalPrice)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '입금 계좌 안내',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4, // 가로 사이 간격
                              runSpacing: 6, // 줄바꿈 시 세로 간격
                              children: [
                                const Text(
                                  '카카오뱅크 ',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // 💡 터치 복사 영역
                                InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () async {
                                    await Clipboard.setData(const ClipboardData(
                                        text: accountNumber));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '📋 계좌번호($accountNumber)가 클립보드에 복사되었습니다!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A6FA5)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          accountNumber,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A6FA5),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.copy_rounded,
                                            size: 13, color: Color(0xFF4A6FA5)),
                                      ],
                                    ),
                                  ),
                                ),

                                const Text(
                                  ' 문은미(원앤그레인)',
                                  style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: copyAndProcessOrder,
                          icon: const Icon(Icons.copy, size: 20),
                          label: const Text(
                            '주문서 작성 완료 (복사하기)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
