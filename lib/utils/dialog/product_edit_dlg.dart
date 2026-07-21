import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/product_db_provider.dart'; // 📌 ProductModel 상주 위치

class ProductEditDlg extends HookConsumerWidget {
  final ProductModel product; // 📌 확실한 ProductModel 타입 주입
  final String currentCategory; // 📌 수정 완료 후 새로고침을 저격하기 위한 카테고리 매개변수

  const ProductEditDlg({
    super.key,
    required this.product,
    required this.currentCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 1. 순정 ProductModel 명세에만 칼같이 맞춘 컨트롤러 매핑 (미사용 필드 완전 제거!)
    final nameController = useTextEditingController(text: product.name);
    final priceController =
        useTextEditingController(text: product.price.toString());
    final sizeController = useTextEditingController(text: product.size);
    final colorController = useTextEditingController(text: product.color);

    final isSubmitting = useState<bool>(false); // 연타 방지용 락업 상태

    // 🌟 2. 모바일/PC 반응형 대칭 너비 가드 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 450.0;

    // 🎯 [핵심] 수정하기 비동기 파이프라인
    Future<void> handleUpdate() async {
      if (isSubmitting.value) return; // 연속 클릭 차단

      final String editedName = nameController.text.trim();
      final String editedPriceStr = priceController.text.trim();
      final String editedSize = sizeController.text.trim();
      final String editedColor = colorController.text.trim();

      if (editedName.isEmpty || editedPriceStr.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ 상품명과 가격은 필수 입력 항목입니다.')),
        );
        return;
      }

      final int? editedPrice = int.tryParse(editedPriceStr);
      if (editedPrice == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ 가격은 올바른 숫자 형태로만 적어주세요.')),
        );
        return;
      }

      try {
        isSubmitting.value = true; // 로딩 가동 및 버튼 락

        await ref.read(productRepositoryProvider).updateProductTextInfo(
              productId: product.id,
              name: editedName,
              price: editedPrice,
              size: editedSize,
              color: editedColor,
            );

        // 🌟 [무결성 연쇄 동기화]: 캐시를 무효화하여 수정 후 실시간으로 화면 갱신
        ref.invalidate(paginatedProductProvider('all'));
        ref.invalidate(paginatedProductProvider(currentCategory));
        for (var cat in product.categoryNames) {
          ref.invalidate(paginatedProductProvider(cat));
        }

        if (context.mounted) {
          Navigator.pop(context); // 팝업 유연하게 닫기
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 상품 텍스트 정보가 실시간 수정 및 배포되었습니다!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ 서버 반영 실패: $e')),
          );
        }
      } finally {
        isSubmitting.value = false; // 락 해제
      }
    }

    return SizedBox(
      width: dialogWidth,
      child: CustomWidget.dialogCustomForm(
        width: dialogWidth,
        height: 380, // 입력 폼 개수가 줄었으므로 세로 높이를 520에서 380으로 콤팩트하게 다듬음
        isScrollable: false, // 우측 삐져나옴 버그 원천 차단
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomWidget.customDialogTitle(
              context,
              ref,
              title: '📝 상품 정보 편집',
              isShowCloseBtn: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // 1. 상품명
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '상품명 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. 가격 (숫자 입력만 허용)
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '판매 가격 (원) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. 사이즈
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: '권장 사이즈 (예: S, M, L / 3M)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. 색상
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: '상품 색상 (예: 크림, 챠콜)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. 수정 완료 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6FA5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting.value ? null : handleUpdate,
                      child: isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('수정 정보 저장하기',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
