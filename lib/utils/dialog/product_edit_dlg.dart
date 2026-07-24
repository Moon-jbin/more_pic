// FILE: lib/utils/dialog/product_edit_dlg.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/search_provider.dart';

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
    final isImageEditMode = useState<bool>(false);
    final mixedImages = useState<List<dynamic>>(product.images.toList());

    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 450.0;

    final menuAsync = ref.watch(globalMenuProvider);
    final List<Map<String, dynamic>> menuData = (menuAsync.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // ⭐️ 선택된 경로 상태 (예: ['KIDS (2Y~)', 'OUTER', '점퍼/자켓'])
    final selectedPath1 = useState<List<String>>([]);
    final isDoubleCategoryEnabled = useState<bool>(false);
    final selectedPath2 = useState<List<String>>([]);

    final isInitialized = useState<bool>(false);

    // 경로(path: /kids/outer/jumper_jacket)에서 카테고리 ID(kidsOuterJumperJacket) 변환
    String extractCategoryIdFromPath(String path) {
      if (path == '/' || path.isEmpty) return 'all';
      final clean = path.startsWith('/') ? path.substring(1) : path;
      final parts = clean.split('/');
      if (parts.length == 1) return parts.first;

      String result = parts[0];
      for (int i = 1; i < parts.length; i++) {
        final subParts = parts[i].split('_');
        for (var sub in subParts) {
          if (sub.isNotEmpty) {
            result += sub[0].toUpperCase() + sub.substring(1);
          }
        }
      }
      return result;
    }

    // 카테고리 슬러그로부터 초기 트리 경로(['BABY', 'OUTER', '가디건'])를 찾아내는 함수
    List<String> getPathFromSlug(
        String targetSlug, List<Map<String, dynamic>> nodes) {
      List<String>? search(
          List<Map<String, dynamic>> currentNodes, List<String> currentPath) {
        for (var node in currentNodes) {
          final newPath = [...currentPath, node['title'] as String];
          final String nodePath = node['path'] ?? '';
          if (extractCategoryIdFromPath(nodePath) == targetSlug) {
            return newPath;
          }
          if (node['children'] != null &&
              (node['children'] as List).isNotEmpty) {
            final found = search(
                List<Map<String, dynamic>>.from(node['children']), newPath);
            if (found != null) return found;
          }
        }
        return null;
      }

      return search(nodes, []) ?? [];
    }

    // 최초 1회 기존 카테고리 경로 자동 복원
    useEffect(() {
      if (!isInitialized.value &&
          menuData.isNotEmpty &&
          product.categoryNames.isNotEmpty) {
        selectedPath1.value =
            getPathFromSlug(product.categoryNames[0], menuData);
        if (product.categoryNames.length > 1) {
          selectedPath2.value =
              getPathFromSlug(product.categoryNames[1], menuData);
          isDoubleCategoryEnabled.value = true;
        }
        isInitialized.value = true;
      }
      return null;
    }, [menuData]);

    bool nodeTitleEquals(dynamic a, dynamic b) {
      return a.toString().trim().toLowerCase() ==
          b.toString().trim().toLowerCase();
    }

    // ⭐️ 선택된 경로에 따라 동적으로 N단계 드롭다운 목록들을 생성해주는 함수
    List<List<Map<String, dynamic>>> getActiveDropdownLevels(
        List<String> currentPath) {
      List<List<Map<String, dynamic>>> levels = [menuData];
      List<Map<String, dynamic>> currentLevelItems = menuData;

      for (String title in currentPath) {
        final parentNode = currentLevelItems.firstWhere(
          (node) => nodeTitleEquals(node['title'], title),
          orElse: () => {},
        );
        if (parentNode.containsKey('children') &&
            parentNode['children'] != null) {
          final children = (parentNode['children'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (children.isNotEmpty) {
            levels.add(children);
            currentLevelItems = children;
          } else
            break;
        } else
          break;
      }
      return levels;
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ 상품명과 가격은 필수 항목입니다.')));
        return;
      }

      final int? editedPrice = int.tryParse(editedPriceStr);
      if (editedPrice == null) return;

      List<String> finalCategories = [];

      // ⭐️ 1. 메인 카테고리: 사용자가 선택한 트리의 '가장 하위 노드'를 정밀 탐색
      if (selectedPath1.value.isNotEmpty) {
        List<Map<String, dynamic>> currentSearchLevel = menuData;
        Map<String, dynamic>? lastFoundNode;

        for (String title in selectedPath1.value) {
          final found = currentSearchLevel.firstWhere(
            (n) => nodeTitleEquals(n['title'], title),
            orElse: () => {},
          );
          if (found.isNotEmpty) {
            lastFoundNode = found;
            if (found['children'] != null &&
                (found['children'] as List).isNotEmpty) {
              currentSearchLevel = (found['children'] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
          }
        }

        if (lastFoundNode != null && lastFoundNode['path'] != null) {
          final String catId1 =
              extractCategoryIdFromPath(lastFoundNode['path']);
          if (catId1.isNotEmpty && catId1 != 'all') {
            finalCategories.add(catId1);
          }
        }
      }

      // ⭐️ 2. 더블(추가) 카테고리 탐색
      if (isDoubleCategoryEnabled.value && selectedPath2.value.isNotEmpty) {
        List<Map<String, dynamic>> currentSearchLevel2 = menuData;
        Map<String, dynamic>? lastFoundNode2;

        for (String title in selectedPath2.value) {
          final found = currentSearchLevel2.firstWhere(
            (n) => nodeTitleEquals(n['title'], title),
            orElse: () => {},
          );
          if (found.isNotEmpty) {
            lastFoundNode2 = found;
            if (found['children'] != null &&
                (found['children'] as List).isNotEmpty) {
              currentSearchLevel2 = (found['children'] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
          }
        }

        if (lastFoundNode2 != null && lastFoundNode2['path'] != null) {
          final String catId2 =
              extractCategoryIdFromPath(lastFoundNode2['path']);
          if (catId2.isNotEmpty &&
              catId2 != 'all' &&
              !finalCategories.contains(catId2)) {
            finalCategories.add(catId2);
          }
        }
      }

      // 방어 로직: 카테고리 추출 실패 시 기존 첫 카테고리 유지
      if (finalCategories.isEmpty && product.categoryNames.isNotEmpty) {
        finalCategories.add(product.categoryNames[0]);
      }

      if (kDebugMode) {
        print(
            "🎯 [카테고리 최종 이동 결과] 기존: ${product.categoryNames} -> 변경: $finalCategories");
      }

      try {
        isSubmitting.value = true;

        if (isImageEditMode.value) {
          StateSetter? submitPopupSetState;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                StatefulBuilder(builder: (context, setPopupState) {
              submitPopupSetState = setPopupState;
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("정보 및 이미지 수정 중...",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                        value: progress.value, color: const Color(0xFF4A6FA5)),
                    const SizedBox(height: 16),
                    Text(progressMsg.value,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
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
                categories: finalCategories,
                size: editedSize,
                color: editedColor,
                mixedImages: mixedImages.value,
                onProgress: updateSubmitStatus,
              );

          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        } else {
          await ref.read(productRepositoryProvider).updateProductTextInfo(
                productId: product.id,
                name: editedName,
                price: editedPrice,
                categories: finalCategories,
                size: editedSize,
                color: editedColor,
              );
        }

        // 관련 리버팟 전체 캐시 초기화
        ref.invalidate(paginatedProductProvider('all'));
        ref.invalidate(paginatedProductProvider(currentCategory));
        for (var cat in product.categoryNames) {
          ref.invalidate(paginatedProductProvider(cat));
        }
        for (var cat in finalCategories) {
          ref.invalidate(paginatedProductProvider(cat));
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '🎉 카테고리가 [${finalCategories.join(', ')}] (으)로 이동되었습니다!')),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('서버 반영 실패: $e')));
      } finally {
        isSubmitting.value = false;
      }
    }

    final dropdownLevels1 = getActiveDropdownLevels(selectedPath1.value);
    final dropdownLevels2 = getActiveDropdownLevels(selectedPath2.value);

    return SizedBox(
      width: dialogWidth,
      child: CustomWidget.dialogCustomForm(
        width: dialogWidth,
        isScrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomWidget.customDialogTitle(
              context,
              ref,
              title: '🛠️ 상품 수정 및 카테고리 이동',
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
                        prefixIcon: Icon(Icons.shopping_bag_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: '판매 가격 (원) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                        labelText: '권장 사이즈',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                        labelText: '상품 색상',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.palette_outlined)),
                  ),
                  const SizedBox(height: 16),

                  // ⭐️ 계층적 카테고리 트리 선택 메뉴
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFF9F9F9),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('카테고리 이동 및 다중 진열',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A6FA5))),
                        leading: const Icon(Icons.account_tree_outlined,
                            color: Color(0xFF4A6FA5)),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          // ⭐️ 단계별 트리 드롭다운 연쇄 생성
                          ...List.generate(dropdownLevels1.length,
                              (levelIndex) {
                            final itemsInLevel = dropdownLevels1[levelIndex];
                            final String? selectedVal =
                                selectedPath1.value.length > levelIndex
                                    ? selectedPath1.value[levelIndex]
                                    : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: levelIndex == 0
                                      ? '메인 카테고리 (1단계) *'
                                      : '${levelIndex + 1}단계 하위 메뉴',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                value: selectedVal,
                                items: itemsInLevel.map((node) {
                                  final String title = node['title'] as String;
                                  final bool hasChildren =
                                      node['children'] != null &&
                                          (node['children'] as List).isNotEmpty;
                                  return DropdownMenuItem<String>(
                                    value: title,
                                    child:
                                        Text(hasChildren ? '$title ▶' : title),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    // 상위 드롭다운 선택 시 자식 단계의 이전 선택값들은 초기화하고 새 경로 설정
                                    final List<String> updated =
                                        List<String>.from(selectedPath1.value
                                            .take(levelIndex));
                                    updated.add(val);
                                    selectedPath1.value = updated;
                                  }
                                },
                              ),
                            );
                          }),

                          const Divider(height: 24),

                          // 더블 진열 체크박스
                          CheckboxListTile(
                            title: const Text('카테고리 더블 진열 (다른 코너에도 복사 진열)',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                            value: isDoubleCategoryEnabled.value,
                            activeColor: const Color(0xFF4A6FA5),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                isDoubleCategoryEnabled.value = val ?? false,
                          ),

                          // 더블 진열 계층 드롭다운
                          if (isDoubleCategoryEnabled.value)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Column(
                                children: List.generate(dropdownLevels2.length,
                                    (levelIndex) {
                                  final itemsInLevel =
                                      dropdownLevels2[levelIndex];
                                  final String? selectedVal =
                                      selectedPath2.value.length > levelIndex
                                          ? selectedPath2.value[levelIndex]
                                          : null;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: levelIndex == 0
                                            ? '추가 진열 (1단계)'
                                            : '추가 ${levelIndex + 1}단계 하위',
                                        border: const OutlineInputBorder(),
                                      ),
                                      value: selectedVal,
                                      items: itemsInLevel.map((node) {
                                        final String title =
                                            node['title'] as String;
                                        final bool hasChildren =
                                            node['children'] != null &&
                                                (node['children'] as List)
                                                    .isNotEmpty;
                                        return DropdownMenuItem<String>(
                                          value: title,
                                          child: Text(
                                              hasChildren ? '$title ▶' : title),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final List<String> updated =
                                              List<String>.from(selectedPath2
                                                  .value
                                                  .take(levelIndex));
                                          updated.add(val);
                                          selectedPath2.value = updated;
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이미지 수정 영역
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
                            subtitle: const Text('기존 사진을 변경하거나 위치를 바꿀 수 있습니다.',
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
                                buildDefaultDragHandles: false,
                                physics: const ClampingScrollPhysics(),
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
                                          width: isFirst ? 2.5 : 1),
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
                                            : imageContainer,
                                        if (isFirst)
                                          Positioned(
                                              top: 12,
                                              left: 4,
                                              child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                                  color:
                                                      const Color(0xFF4A6FA5),
                                                  child: const Text('메인',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight
                                                              .bold)))),
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
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 12)),
                                          ),
                                        ),
                                        if (!isDesktopOrWeb)
                                          Positioned(
                                              bottom: 4,
                                              right: 16,
                                              child: ReorderableDragStartListener(
                                                  index: index,
                                                  child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.6),
                                                          shape:
                                                              BoxShape.circle),
                                                      child: const Icon(
                                                          Icons
                                                              .open_with_rounded,
                                                          color: Colors.white,
                                                          size: 16)))),
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6FA5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          elevation: 0),
                      onPressed: isSubmitting.value ? null : handleUpdate,
                      child: isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
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
