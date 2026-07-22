import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/global/global.dart'; // isDesktopOrWeb 사용을 위해 추가

class ProductEditDlg extends HookConsumerWidget {
  final ProductModel product;
  final String currentCategory;

  const ProductEditDlg({
    super.key,
    required this.product,
    required this.currentCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: product.name);
    final priceController =
        useTextEditingController(text: product.price.toString());
    final sizeController = useTextEditingController(text: product.size);
    final colorController = useTextEditingController(text: product.color);

    final isSubmitting = useState<bool>(false);

    // 🌟 [핵심 상태]: 사진 편집 모드 토글 및 이미지 혼합 리스트 (String + XFile)
    final isImageEditMode = useState<bool>(false);
    final mixedImages = useState<List<dynamic>>(product.images.toList());

    // 로딩 팝업을 위한 상태
    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 450.0;

    // 📸 새 사진 추가 함수
    Future<void> pickExtraImages() async {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? files = await picker.pickMultiImage();
      if (files != null && files.isNotEmpty) {
        mixedImages.value = [...mixedImages.value, ...files];
      }
    }

    Future<void> handleUpdate() async {
      if (isSubmitting.value) return;

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

      if (isImageEditMode.value && mixedImages.value.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ 이미지를 최소 1장 이상 등록해 주세요.')),
        );
        return;
      }

      try {
        isSubmitting.value = true;

        if (isImageEditMode.value) {
          // 💡 [사진 수정 활성화 시]: 스토리지 업로드 및 DB 갱신 (로딩 팝업 띄움)
          StateSetter? submitPopupSetState;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                StatefulBuilder(builder: (context, setPopupState) {
              submitPopupSetState = setPopupState;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                content: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("상품 정보 및 이미지 수정 중...",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress.value,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF4A6FA5),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 16),
                      Text("${(progress.value * 100).toInt()}% 진행",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(progressMsg.value,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }),
          );

          void updateSubmitStatus(double p, String m) {
            progress.value = p;
            progressMsg.value = m;
            if (submitPopupSetState != null) submitPopupSetState!(() {});
          }

          await ref.read(productRepositoryProvider).updateProductWithImages(
                productId: product.id,
                name: editedName,
                price: editedPrice,
                size: editedSize,
                color: editedColor,
                mixedImages: mixedImages.value,
                onProgress: updateSubmitStatus,
              );

          if (context.mounted)
            Navigator.of(context, rootNavigator: true).pop(); // 팝업 닫기
        } else {
          // 💡 [텍스트만 수정 시]: 빠르고 가볍게 기존 텍스트 로직만 태움 (로딩 팝업 없음)
          await ref.read(productRepositoryProvider).updateProductTextInfo(
                productId: product.id,
                name: editedName,
                price: editedPrice,
                size: editedSize,
                color: editedColor,
              );
        }

        // 캐시 무효화 및 실시간 화면 갱신
        ref.invalidate(paginatedProductProvider('all'));
        ref.invalidate(paginatedProductProvider(currentCategory));
        for (var cat in product.categoryNames) {
          ref.invalidate(paginatedProductProvider(cat));
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 상품 정보가 성공적으로 수정되었습니다!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('❌ 서버 반영 실패: $e')));
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return SizedBox(
      width: dialogWidth,
      child: CustomWidget.dialogCustomForm(
        width: dialogWidth,
        // height: 속성을 제거하여 내부 컨텐츠 크기에 맞춰 스르륵 자연스럽게 늘어나게 만듦
        isScrollable: false,
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
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '상품명 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: '권장 사이즈 (예: S, M, L / 3M)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: '상품 색상 (예: 크림, 챠콜)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🌟 사진 편집 토글 스위치 및 확장 UI
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isImageEditMode.value
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: isImageEditMode.value
                                ? const Color(0xFF4A6FA5).withOpacity(0.05)
                                : Colors.transparent,
                          ),
                          child: SwitchListTile(
                            title: Text('사진 및 순서 수정하기',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isImageEditMode.value
                                        ? const Color(0xFF4A6FA5)
                                        : Colors.black87)),
                            subtitle: const Text('기존 사진을 변경하거나 위치를 옮길 수 있습니다.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            value: isImageEditMode.value,
                            activeColor: const Color(0xFF4A6FA5),
                            onChanged: (val) => isImageEditMode.value = val,
                          ),
                        ),
                        if (isImageEditMode.value) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: pickExtraImages,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('PC/폰에서 새 사진 추가하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey.shade300),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (mixedImages.value.isNotEmpty)
                            Container(
                              height: 110,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ReorderableListView.builder(
                                scrollDirection: Axis.horizontal,
                                buildDefaultDragHandles: true,
                                itemCount: mixedImages.value.length,
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final items =
                                      List<dynamic>.from(mixedImages.value);
                                  final item = items.removeAt(oldIndex);
                                  items.insert(newIndex, item);
                                  mixedImages.value = items;
                                },
                                itemBuilder: (context, index) {
                                  final item = mixedImages.value[index];
                                  final isFirst = index == 0;
                                  final isString = item is String;
                                  final imagePath =
                                      isString ? item : (item as XFile).path;

                                  final Widget imageContainer = Container(
                                    width: 90,
                                    height: 90,
                                    margin:
                                        const EdgeInsets.only(top: 8, right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isFirst
                                            ? const Color(0xFF4A6FA5)
                                            : Colors.grey.shade300,
                                        width: isFirst ? 2.5 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: isString
                                          ? CachedNetworkImage(
                                              imageUrl: imagePath,
                                              fit: BoxFit.cover)
                                          : Image.network(imagePath,
                                              fit: BoxFit.cover),
                                    ),
                                  );

                                  return Container(
                                    key: ValueKey(imagePath + index.toString()),
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        isDesktopOrWeb
                                            ? ReorderableDragStartListener(
                                                index: index,
                                                child: imageContainer)
                                            : ReorderableDelayedDragStartListener(
                                                index: index,
                                                child: imageContainer),
                                        if (isFirst)
                                          Positioned(
                                            top: 12,
                                            left: 4,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              color: const Color(0xFF4A6FA5),
                                              child: const Text('대표',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: InkWell(
                                            onTap: () {
                                              final items = List<dynamic>.from(
                                                  mixedImages.value);
                                              items.removeAt(index);
                                              mixedImages.value = items;
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
