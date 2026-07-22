// FILE: lib/global/custom_widget/product_detail_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/model/cart_model.dart';
import 'package:more_pic/provider/cart_provider.dart';
import 'package:more_pic/screen/order_form_screen.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router_name.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';

class ProductDetailBottomBar extends HookConsumerWidget {
  final String productId;
  final String productName;
  final int basePrice;
  final List<String> colors;
  final List<String> sizes;

  const ProductDetailBottomBar({
    Key? key,
    required this.productId,
    required this.productName,
    required this.basePrice,
    required this.colors,
    required this.sizes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).length;

    void showOptionModal() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => _OptionModalContent(
          productId: productId,
          productName: productName,
          basePrice: basePrice,
          colors: colors,
          sizes: sizes,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.black87),
                          onPressed: () {
                            NavigationService()
                                .routerGo(context, OrderFormScreenRoute);
                          },
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 20, minHeight: 20),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: showOptionModal,
                        child: const Text(
                          '주문서에 상품 담기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionModalContent extends HookConsumerWidget {
  final String productId;
  final String productName;
  final int basePrice;
  final List<String> colors;
  final List<String> sizes;

  const _OptionModalContent({
    Key? key,
    required this.productId,
    required this.productName,
    required this.basePrice,
    required this.colors,
    required this.sizes,
  }) : super(key: key);

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = useState<String?>(null);
    final selectedSize = useState<String?>(null);
    final quantity = useState<int>(1);

    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;

    final int originalTotal = ((basePrice * 1.7).toInt()) * quantity.value;
    final int memberTotal = basePrice * quantity.value;

    final formatCurrency =
        NumberFormat.currency(locale: "ko_KR", symbol: "", decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.close,
                        color: Colors.grey.shade600, size: 24),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              "색상 옵션",
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                return _buildOptionButton(
                  text: color,
                  isSelected: selectedColor.value == color,
                  onTap: () => selectedColor.value =
                      (selectedColor.value == color) ? null : color,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text(
              "사이즈 옵션",
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.map((size) {
                return _buildOptionButton(
                  text: size,
                  isSelected: selectedSize.value == size,
                  onTap: () => selectedSize.value =
                      (selectedSize.value == size) ? null : size,
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("수량",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        color:
                            quantity.value > 1 ? Colors.black87 : Colors.grey,
                        onPressed: () {
                          if (quantity.value > 1) quantity.value--;
                        },
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '${quantity.value}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        color: Colors.black87,
                        onPressed: () => quantity.value++,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🚀 [총 상품 금액 영역]: 로그인 시 취소선 및 회원가 명시
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 상품 금액',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  if (isLoggedIn)
                    Row(
                      children: [
                        Text(
                          '₩ ${formatCurrency.format(originalTotal)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough, // 👈 취소선
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₩ ${formatCurrency.format(memberTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '₩ ${formatCurrency.format(originalTotal)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (selectedColor.value == null ||
                      selectedSize.value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('옵션(색상 및 사이즈)을 모두 선택해주세요.')),
                    );
                    return;
                  }

                  final item = CartItem(
                    id: '${productId}_${selectedColor.value}_${selectedSize.value}',
                    name: productName,
                    color: selectedColor.value!,
                    size: selectedSize.value!,
                    quantity: quantity.value,
                    price: basePrice, // 👈 DB에는 항상 순수 도매가 저장
                  );

                  ref.read(cartProvider.notifier).addItem(item);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('주문서에 상품이 담겼습니다.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      action: SnackBarAction(
                        label: '주문서 가기',
                        textColor: const Color(0xFFFEE500),
                        onPressed: () {
                          NavigationService()
                              .routerGo(context, OrderFormScreenRoute);
                        },
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                child: const Text('주문서에 담기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
