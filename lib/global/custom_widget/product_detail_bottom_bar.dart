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

class ProductDetailBottomBar extends HookConsumerWidget {
  final String productId;
  final String productName;
  final int price;
  final List<String> colors;
  final List<String> sizes;

  const ProductDetailBottomBar({
    Key? key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.colors,
    required this.sizes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).length;

    // 옵션 모달 호출
    void showOptionModal() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => _OptionModalContent(
          productId: productId,
          productName: productName,
          price: price,
          colors: colors,
          sizes: sizes,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64, // 💡 [핵심]: 고정 높이를 주어야 Center가 화면 전체로 늘어나는 것을 방지합니다!
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Row(
                children: [
                  // 주문서 바로가기 (뱃지)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment_outlined, size: 28),
                        onPressed: () {
                          NavigationService()
                              .routerGo(context, OrderFormScreenRoute);
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
                  const SizedBox(width: 12),

                  // 담기 버튼
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: showOptionModal,
                        child: const Text('주문서에 담기',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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

// 모달 내부 상태를 위한 HookConsumerWidget 위젯
class _OptionModalContent extends HookConsumerWidget {
  final String productId;
  final String productName;
  final int price;
  final List<String> colors;
  final List<String> sizes;

  const _OptionModalContent({
    Key? key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.colors,
    required this.sizes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = useState<String?>(null);
    final selectedSize = useState<String?>(null);
    final quantity = useState<int>(1);

    final formatCurrency =
        NumberFormat.currency(locale: "ko_KR", symbol: "", decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2, // 최대 2줄까지 허용
                  overflow: TextOverflow.ellipsis, // 넘치면 ... 처리
                ),
              ),
              const SizedBox(width: 12), // 상호 간격 확보
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context))
            ],
          ),
          const Divider(),

          // 1. 색상
          const Text("색상", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = selectedColor.value == color;
              return ChoiceChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (selected) =>
                    selectedColor.value = selected ? color : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 2. 사이즈
          const Text("사이즈", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final isSelected = selectedSize.value == size;
              return ChoiceChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (selected) =>
                    selectedSize.value = selected ? size : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. 수량
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("수량", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (quantity.value > 1) quantity.value--;
                    },
                  ),
                  Text('${quantity.value}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => quantity.value++,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 담기 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () {
                if (selectedColor.value == null || selectedSize.value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('색상과 사이즈를 모두 선택해주세요!')),
                  );
                  return;
                }

                final item = CartItem(
                  id: '${productId}_${selectedColor.value}_${selectedSize.value}',
                  name: productName,
                  color: selectedColor.value!,
                  size: selectedSize.value!,
                  quantity: quantity.value,
                  price: price,
                );

                ref.read(cartProvider.notifier).addItem(item);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('주문서에 상품이 담겼습니다!'),
                    action: SnackBarAction(
                      label: '주문서 작성',
                      textColor: Colors.amber,
                      onPressed: () {
                        NavigationService()
                            .routerGo(context, OrderFormScreenRoute);
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              child:
                  Text('₩ ${formatCurrency.format(price * quantity.value)} 담기'),
            ),
          ),
        ],
      ),
    );
  }
}
