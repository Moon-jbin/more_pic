import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/component/tag_input_widget.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:more_pic/provider/search_provider.dart';

class ProductUploadDlg extends HookConsumerWidget {
  const ProductUploadDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final sizeController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final colorController = useTextEditingController();
    final shippingMethodController = useTextEditingController();

    final productImages = useState<List<XFile>>([]);
    final isLoading = useState<bool>(false);

    // 🌟 파이어베이스 동적 메뉴 실시간 수혈
    final menuAsync = ref.watch(globalMenuProvider);
    final List<Map<String, dynamic>> menuData = (menuAsync.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 🌟 [완치 포인트 1]: 무제한 깊이를 수용하기 위해 선택된 타이틀 경로를 '배열'로 관리합니다!
    final selectedPath1 = useState<List<String>>([]);

    // 🌟 [완치 포인트 2]: 더블 업로드용 추가 카테고리 역시 배열 경로로 무제한 관리합니다.
    final isDoubleCategoryEnabled = useState<bool>(false);
    final selectedPath2 = useState<List<String>>([]);

    final shippingType = useState<String>('국내배송');
    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    // 🌟 [동적 트리 계산기]
    List<List<Map<String, dynamic>>> getActiveDropdownLevels(
        List<String> currentPath) {
      List<List<Map<String, dynamic>>> levels = [menuData];

      List<Map<String, dynamic>> currentLevelItems = menuData;
      for (String title in currentPath) {
        final parentNode = currentLevelItems.firstWhere(
          (node) => node['title'] == title,
          orElse: () => {},
        );

        if (parentNode.containsKey('children') &&
            parentNode['children'] != null) {
          final List<Map<String, dynamic>> children =
              (parentNode['children'] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
          if (children.isNotEmpty) {
            levels.add(children);
            currentLevelItems = children;
          } else {
            break;
          }
        } else {
          break;
        }
      }
      return levels;
    }

    // 🌟 [최종 말단 노드 추적기]
    Map<String, dynamic>? getFinalSelectedNode(List<String> path) {
      if (path.isEmpty) return null;
      List<Map<String, dynamic>> currentLevel = menuData;
      Map<String, dynamic>? finalNode;

      for (String title in path) {
        finalNode = currentLevel.firstWhere((node) => node['title'] == title,
            orElse: () => {});
        if (finalNode.containsKey('children') &&
            finalNode['children'] != null) {
          currentLevel = (finalNode['children'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return (finalNode != null && finalNode.isNotEmpty) ? finalNode : null;
    }

    // 이미지 슬라이서 보존
    Future<List<XFile>> sliceLongImage(ui.Image uiImage,
        Uint8List originalBytes, Function(double, String) onProgress) async {
      List<XFile> slicedFiles = [];
      int originalWidth = uiImage.width;
      int originalHeight = uiImage.height;
      int maxSliceHeight = 3500;
      int minSliceHeight = 100;
      int currentY = 0;
      int index = 0;
      int scanStride = 10;

      onProgress(0.01, "브라우저 하드웨어 가속 이미지 준비 중...");
      final html.ImageElement htmlImgElement = html.ImageElement();
      final imgLoadCompleter = Completer<void>();

      htmlImgElement.onLoad.listen((_) => imgLoadCompleter.complete());
      htmlImgElement.onError
          .listen((e) => imgLoadCompleter.completeError("원본 이미지 로드 실패"));

      final blob = html.Blob([originalBytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      htmlImgElement.src = blobUrl;
      await imgLoadCompleter.future;

      final html.CanvasElement scanCanvas =
          html.CanvasElement(width: originalWidth, height: originalHeight);
      final html.CanvasRenderingContext2D scanCtx = scanCanvas.context2D;
      scanCtx.drawImage(htmlImgElement, 0, 0);

      bool isRowBlankCanvas(int y) {
        if (y < 0 || y >= originalHeight) return false;
        final html.ImageData imageData =
            scanCtx.getImageData(0, y, originalWidth, 1);
        final List<int> data = imageData.data;
        int noiseCount = 0;
        int maxAllowedNoise = 2;

        for (int x = 0; x < originalWidth; x++) {
          int offset = x * 4;
          if (offset + 3 < data.length) {
            int r = data[offset];
            int g = data[offset + 1];
            int b = data[offset + 2];
            int a = data[offset + 3];
            if (a < 255 || (r < 250 || g < 250 || b < 250)) {
              noiseCount++;
              if (noiseCount > maxAllowedNoise) return false;
            }
          }
        }
        return true;
      }

      while (currentY < originalHeight) {
        double percent = (currentY / originalHeight).clamp(0.1, 0.85);
        onProgress(percent, "상세 페이지 [${index + 1}번째 조각] 여백 분석 중...");

        int searchLimitY = (currentY + maxSliceHeight).clamp(0, originalHeight);
        int bestCutY = searchLimitY;
        bool foundBlank = false;

        for (int checkY = currentY + minSliceHeight;
            checkY < searchLimitY;
            checkY += scanStride) {
          if (isRowBlankCanvas(checkY)) {
            bestCutY = checkY;
            foundBlank = true;
            break;
          }
        }

        if (!foundBlank && (originalHeight - currentY <= maxSliceHeight)) {
          bestCutY = originalHeight;
        } else if (!foundBlank) {
          for (int checkY = searchLimitY;
              checkY >= currentY + minSliceHeight;
              checkY -= scanStride) {
            if (isRowBlankCanvas(checkY)) {
              bestCutY = checkY;
              foundBlank = true;
              break;
            }
          }
        }

        int currentSliceHeight = bestCutY - currentY;
        if (currentSliceHeight <= 0) break;

        final html.CanvasElement chunkCanvas = html.CanvasElement(
            width: originalWidth, height: currentSliceHeight);
        final html.CanvasRenderingContext2D chunkCtx = chunkCanvas.context2D;
        chunkCtx.translate(0, -currentY);
        chunkCtx.drawImage(htmlImgElement, 0, 0);
        chunkCtx.translate(0, currentY);

        final chunkBlob = await chunkCanvas.toBlob('image/jpeg', 0.35);
        final String chunkBlobUrl = html.Url.createObjectUrlFromBlob(chunkBlob);

        slicedFiles.add(XFile(chunkBlobUrl,
            mimeType: 'image/jpeg',
            name:
                'chunk_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg'));
        currentY = bestCutY;
        index++;
      }
      html.Url.revokeObjectUrl(blobUrl);
      return slicedFiles;
    }

    String convertPathToCategory(String path) {
      if (path == '/') return 'newProduct';
      if (path.isEmpty) return 'unknown';
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) return 'unknown';
      String result = parts[0];
      for (int i = 1; i < parts.length; i++) {
        String word = parts[i];
        final subParts = word.split('_');
        for (var sub in subParts) {
          if (sub.isNotEmpty) result += sub[0].toUpperCase() + sub.substring(1);
        }
      }
      return result;
    }

    // 🚀 상품 업로드 처리 액션
    Future<void> submitProduct() async {
      final finalTargetNode = getFinalSelectedNode(selectedPath1.value);

      if (finalTargetNode == null ||
          (finalTargetNode.containsKey('children') &&
              finalTargetNode['children'] != null &&
              (finalTargetNode['children'] as List).isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🏷️ [1번 카테고리] 가장 마지막 하위 단계까지 완전히 선택해 주세요!')));
        return;
      }

      dynamic finalDoubleTargetNode;
      if (isDoubleCategoryEnabled.value) {
        finalDoubleTargetNode = getFinalSelectedNode(selectedPath2.value);
        if (finalDoubleTargetNode == null ||
            (finalDoubleTargetNode.containsKey('children') &&
                finalDoubleTargetNode['children'] != null &&
                (finalDoubleTargetNode['children'] as List).isNotEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('🏷️ [추가 카테고리] 활성화하셨으므로 마지막 하위 단계까지 선택해 주세요!')));
          return;
        }
      }

      if (nameController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty ||
          productImages.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📝 상품명, 가격, 등록 이미지는 필수 항목입니다!')));
        return;
      }

      try {
        isLoading.value = true;
        progress.value = 0.0;
        progressMsg.value = "구글 클라우드 세션 연결 중...";
        StateSetter? submitPopupSetState;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(builder: (context, setPopupState) {
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
                      const Text("☁️ 신상 상품 구글 클라우드 멀티 진열 중",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                          value: progress.value,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF4A6FA5),
                          minHeight: 10),
                      const SizedBox(height: 16),
                      Text("${(progress.value * 100).toInt()}% 전송 완료",
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
            });
          },
        );

        void updateSubmitStatus(double p, String m) {
          progress.value = p;
          progressMsg.value = m;
          if (submitPopupSetState != null) submitPopupSetState!(() {});
        }

        final String mappedCategory =
            convertPathToCategory(finalTargetNode['path'] ?? '');
        final List<String> finalCategories = [mappedCategory];

        if (isDoubleCategoryEnabled.value && finalDoubleTargetNode != null) {
          final String mappedDoubleCategory =
              convertPathToCategory(finalDoubleTargetNode['path'] ?? '');
          if (!finalCategories.contains(mappedDoubleCategory)) {
            finalCategories.add(mappedDoubleCategory);
          }
        }

        await ref.read(productRepositoryProvider).uploadFullProduct(
              name: nameController.text.trim(),
              price: int.parse(priceController.text.trim()),
              categories: finalCategories,
              size: sizeController.text,
              productDetail: descriptionController.text.trim(),
              color: colorController.text,
              shippingType: shippingType.value,
              shippingMethod: shippingMethodController.text.trim(),
              imageFiles: productImages.value,
              onProgress: (percent, message) {
                updateSubmitStatus(percent, "구글 매대에 이쁘게 진열 중: $message");
              },
            );

        ref.invalidate(paginatedProductProvider('all'));
        ref.invalidate(paginatedProductProvider(mappedCategory));

        if (isDoubleCategoryEnabled.value && finalDoubleTargetNode != null) {
          final String mappedDoubleCategory =
              convertPathToCategory(finalDoubleTargetNode['path'] ?? '');
          ref.invalidate(paginatedProductProvider(mappedDoubleCategory));
        }

        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        if (context.mounted) {
          Navigator.of(context).pop();
          String successMsg = '🎉 [${finalTargetNode['title']}] 매대에 진열 완료!';
          if (isDoubleCategoryEnabled.value) {
            successMsg += ' & [${finalDoubleTargetNode['title']}] 동시 복사 완료!';
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(successMsg)));
        }
      } catch (e) {
        if (context.mounted && ModalRoute.of(context)?.isCurrent == false) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ 멀티 등록 실패: $e')));
      } finally {
        isLoading.value = false;
      }
    }

    if (menuAsync.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A6FA5)));
    }

    final dropdownLevels1 = getActiveDropdownLevels(selectedPath1.value);
    final dropdownLevels2 = getActiveDropdownLevels(selectedPath2.value);

    // 📸 이미지 픽커 엔진
    final ImagePicker picker = ImagePicker();
    Future<void> pickCombinedProductImage() async {
      final List<XFile>? files = await picker.pickMultiImage();
      if (files == null || files.isEmpty) return;

      progress.value = 0.0;
      progressMsg.value = "도매처 원본 해체 준비 중...";
      StateSetter? popupSetState;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setPopupState) {
            popupSetState = setPopupState;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              content: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("📐 통이미지 해체 및 자동 섬네일 추출",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                        value: progress.value,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF4A6FA5),
                        minHeight: 10),
                    const SizedBox(height: 16),
                    Text("${(progress.value * 100).toInt()}% 완료",
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
          });
        },
      );

      void updateStatus(double p, String m) {
        progress.value = p;
        progressMsg.value = m;
        if (popupSetState != null) popupSetState!(() {});
      }

      List<XFile> finalProcessedList = [];
      int fileCount = 0;
      await Future.delayed(const Duration(seconds: 1));

      for (var file in files) {
        fileCount++;
        final Uint8List bytes = await file.readAsBytes();

        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image uiImage = frameInfo.image;

        if (uiImage.height > 4000) {
          List<XFile> chunks =
              await sliceLongImage(uiImage, bytes, (percent, msg) {
            double fileBase = (fileCount - 1) / files.length;
            double currentFilePercent = percent / files.length;
            updateStatus((fileBase + currentFilePercent).clamp(0.0, 1.0),
                "[${fileCount}/${files.length}] $msg");
          });
          finalProcessedList.addAll(chunks);
        } else {
          finalProcessedList.add(file);
        }
      }

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      productImages.value = finalProcessedList;
    }

    return CustomWidget.dialogCustomForm(
        width: 900,
        height: 700,
        child: Column(
          children: [
            CustomWidget.customDialogTitle(context, ref,
                title: '스마트 상품 업로드', isShowCloseBtn: true),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 5),
              child: SizedBox(
                height: 580,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const Text('🏷️ 카테고리 지정',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),

                      ...List.generate(dropdownLevels1.length, (levelIndex) {
                        final itemsInLevel = dropdownLevels1[levelIndex];
                        final String? selectedVal =
                            selectedPath1.value.length > levelIndex
                                ? selectedPath1.value[levelIndex]
                                : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                                'lvl1_${levelIndex}_${selectedPath1.value.take(levelIndex).join("_")}'),
                            decoration: InputDecoration(
                              labelText: levelIndex == 0
                                  ? '대분류 (1단계) *'
                                  : '${levelIndex + 1}단계 하위 그룹',
                              border: const OutlineInputBorder(),
                            ),
                            value: selectedVal,
                            items: itemsInLevel.map((node) {
                              return DropdownMenuItem<String>(
                                value: node['title'] as String,
                                child: Text(node['title'] as String),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final newPath = selectedPath1.value
                                    .take(levelIndex)
                                    .toList();
                                newPath.add(val);
                                selectedPath1.value = newPath;
                              }
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('카테고리 더블 업로드 (다른 코너에도 동시에 진열하기)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A6FA5))),
                        value: isDoubleCategoryEnabled.value,
                        activeColor: const Color(0xFF4A6FA5),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          isDoubleCategoryEnabled.value = val ?? false;
                        },
                      ),

                      if (isDoubleCategoryEnabled.value) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(
                                  color:
                                      const Color(0xFF4A6FA5).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(6)),
                          child: Column(
                            children: List.generate(dropdownLevels2.length,
                                (levelIndex) {
                              final itemsInLevel = dropdownLevels2[levelIndex];
                              final String? selectedVal =
                                  selectedPath2.value.length > levelIndex
                                      ? selectedPath2.value[levelIndex]
                                      : null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey(
                                      'lvl2_${levelIndex}_${selectedPath2.value.take(levelIndex).join("_")}'),
                                  decoration: InputDecoration(
                                    labelText: levelIndex == 0
                                        ? '추가 대분류 (1단계) *'
                                        : '추가 ${levelIndex + 1}단계 하위 그룹',
                                    border: const OutlineInputBorder(),
                                  ),
                                  value: selectedVal,
                                  items: itemsInLevel.map((node) {
                                    return DropdownMenuItem<String>(
                                      value: node['title'] as String,
                                      child: Text(node['title'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final newPath = selectedPath2.value
                                          .take(levelIndex)
                                          .toList();
                                      newPath.add(val);
                                      selectedPath2.value = newPath;
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ),
                      ],

                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider()),

                      TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                              labelText: '상품명 *',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: '판매 가격(원) *',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: '권장 사이즈 (예: S, M, L / 3M)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          labelText: '상품 색상 (예: 크림, 민트, 차콜)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                          controller: descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: '상품 상세 설명 및 코디 제안',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder())),

                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider()),
                      const Text('📸 사입처 통이미지 등록 *',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'PC는 사진을 마우스로 드래그, 모바일은 우측 하단 아이콘을 터치하여 이동하세요.\n맨 앞의 사진이 자동으로 [대표 이미지]가 됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton.icon(
                        onPressed: pickCombinedProductImage,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(productImages.value.isEmpty
                            ? '사입처 통사진 등록하기'
                            : '사진 변경하기 (${productImages.value.length}개 조각)'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6FA5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 0),
                      ),
                      const SizedBox(height: 12),

                      // 🔥 [이미지 드래그 앤 드롭 기능 적용]
                      if (productImages.value.isNotEmpty)
                        Container(
                          height: 110,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            buildDefaultDragHandles: false,
                            physics: const ClampingScrollPhysics(),
                            itemCount: productImages.value.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final items =
                                  List<XFile>.from(productImages.value);
                              final item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);
                              productImages.value = items;
                            },
                            itemBuilder: (context, index) {
                              final file = productImages.value[index];
                              final isFirst = index == 0;

                              final Widget imageContainer = Container(
                                width: 90,
                                height: 90,
                                margin: const EdgeInsets.only(top: 8, right: 8),
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
                                  child: Image.network(file.path,
                                      fit: BoxFit.cover),
                                ),
                              );

                              return Container(
                                key: ValueKey(file.path + index.toString()),
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    // 💡 PC면 사진 전체 즉시 드래그, 모바일이면 사진 영역은 스와이프(가로 스크롤) 허용
                                    isDesktopOrWeb
                                        ? ReorderableDragStartListener(
                                            index: index,
                                            child: imageContainer,
                                          )
                                        : imageContainer,

                                    if (isFirst)
                                      Positioned(
                                        top: 12,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          color: const Color(0xFF4A6FA5),
                                          child: const Text('대표',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: InkWell(
                                        onTap: () {
                                          final updatedList = List<XFile>.from(
                                              productImages.value);
                                          updatedList.removeAt(index);
                                          productImages.value = updatedList;
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),

                                    // 🎯 모바일 전용 즉시 이동 손잡이 (우측 하단)
                                    if (!isDesktopOrWeb)
                                      Positioned(
                                        bottom: 4,
                                        right: 16, // 마진, 패딩 고려 위치
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                                              ],
                                            ),
                                            child: const Icon(Icons.open_with_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: isLoading.value
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('취소')),
                          ElevatedButton(
                            onPressed: isLoading.value ? null : submitProduct,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A6FA5),
                                foregroundColor: Colors.white),
                            child: isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('등록하기'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}