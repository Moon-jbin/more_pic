import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/global.dart';
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

    // ✨ 새롭게 추가: 등록 완료 후 스크롤을 맨 위로 올려줄 컨트롤러
    final dialogScrollController = useScrollController();

    final productImages = useState<List<XFile>>([]);
    final isLoading = useState<bool>(false);

    final menuAsync = ref.watch(globalMenuProvider);
    final List<Map<String, dynamic>> menuData = (menuAsync.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final selectedPath1 = useState<List<String>>([]);

    final isDoubleCategoryEnabled = useState<bool>(false);
    final isSyncSubCategory = useState<bool>(false);
    final selectedPath2 = useState<List<String>>([]);

    final shippingType = useState<String>('국내배송');
    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    useEffect(() {
      if (isDoubleCategoryEnabled.value &&
          isSyncSubCategory.value &&
          selectedPath2.value.isNotEmpty) {
        final tier1 = selectedPath2.value.first;
        final syncPath = [tier1];

        if (selectedPath1.value.length > 1) {
          syncPath.addAll(selectedPath1.value.sublist(1));
        }

        if (selectedPath2.value.join('_') != syncPath.join('_')) {
          Future.microtask(() {
            selectedPath2.value = syncPath;
          });
        }
      }
      return null;
    }, [
      selectedPath1.value,
      isSyncSubCategory.value,
      isDoubleCategoryEnabled.value
    ]);

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

    Future<List<XFile>> sliceLongImageWeb(
        html.ImageElement htmlImgElement,
        int originalWidth,
        int originalHeight,
        Function(double, String) onProgress) async {
      List<XFile> slicedFiles = [];
      int maxSliceHeight = 3500;
      int minSliceHeight = 100;
      int currentY = 0;
      int index = 0;
      int scanStride = 10;

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
        onProgress(percent, "상세 이미지 [${index + 1}번째 조각] 여백 분석 중.");

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

        final chunkBlob = await chunkCanvas.toBlob('image/jpg', 0.35);
        final String chunkBlobUrl = html.Url.createObjectUrlFromBlob(chunkBlob);

        final slicedChunk = XFile(chunkBlobUrl,
            mimeType: 'image/jpg',
            name:
                'chunk_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        slicedFiles.add(slicedChunk);

        if (kDebugMode) {
          final chunkBytes = await slicedChunk.readAsBytes();
          print(
              "✂️ [Slice 분할 완료] 조각 #${index + 1} | 크기: ${chunkBytes.lengthInBytes ~/ 1024} KB");
        }

        currentY = bestCutY;
        index++;
      }
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

    Future<void> submitProduct() async {
      final finalTargetNode = getFinalSelectedNode(selectedPath1.value);

      if (finalTargetNode == null ||
          (finalTargetNode.containsKey('children') &&
              finalTargetNode['children'] != null &&
              (finalTargetNode['children'] as List).isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('⚠️ [1차 카테고리] 가장 마지막 하위 단계까지 온전하게 선택해주세요')));
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
              content: Text('⚠️ [추가 카테고리] 활성화하셨다면 마지막 하위 단계까지 선택해주세요')));
          return;
        }
      }

      if (nameController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty ||
          productImages.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❗️ 상품명, 가격, 대표 이미지는 필수 입력값입니다')));
        return;
      }

      try {
        isLoading.value = true;
        progress.value = 0.0;
        progressMsg.value = "구름 클라우드 통신 연결 중.";
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
                      const Text("새 신상 상품 구름 클라우드 멀티 진열 중",
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
                updateSubmitStatus(percent, "구름 매장에 예쁘게 진열 중 $message");
              },
            );

        ref.invalidate(paginatedProductProvider('all'));
        ref.invalidate(paginatedProductProvider(mappedCategory));

        if (isDoubleCategoryEnabled.value && finalDoubleTargetNode != null) {
          final String mappedDoubleCategory =
              convertPathToCategory(finalDoubleTargetNode['path'] ?? '');
          ref.invalidate(paginatedProductProvider(mappedDoubleCategory));
        }

        if (context.mounted)
          Navigator.of(context, rootNavigator: true).pop(); // 로딩 팝업 닫기

        if (context.mounted) {
          // ✨ 다이얼로그 닫기 코드(Navigator.pop) 제거!

          // ✨ 카테고리 정보는 그대로 두고, 글자와 이미지만 초기화
          nameController.clear();
          priceController.clear();
          sizeController.clear();
          colorController.clear();
          descriptionController.clear();
          shippingMethodController.clear();
          productImages.value = []; // 이미지 비우기

          // ✨ 등록 즉시 스크롤을 맨 위로 올려 다음 상품 입력을 돕습니다
          if (dialogScrollController.hasClients) {
            dialogScrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }

          // 성공 메시지 띄우기
          String successMsg =
              '🎉 [${finalTargetNode['title']}] 진열 완료! 바로 다음 상품을 등록하세요!';
          if (isDoubleCategoryEnabled.value) {
            successMsg += ' ([${finalDoubleTargetNode['title']}] 동시 등록 완료)';
          }

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(successMsg),
            duration: const Duration(seconds: 3), // 편의상 조금 넉넉히 노출
          ));
        }
      } catch (e) {
        if (context.mounted && ModalRoute.of(context)?.isCurrent == false) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❗️ 멀티 등록 실패: $e')));
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

    final ImagePicker picker = ImagePicker();
    Future<void> pickCombinedProductImage() async {
      final List<XFile>? files = await picker.pickMultiImage();
      if (files == null || files.isEmpty) return;

      if (kDebugMode) {
        print("📸 [이미지 선택 완료] 총 ${files.length}개 선택됨. 처리 시작...");
      }

      progress.value = 0.0;
      progressMsg.value = "판매할 원본 본체 준비 중.";
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
                    const Text("원 이미지를 신체 자동 분할 추출",
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
        final int originalKb = bytes.lengthInBytes ~/ 1024;

        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final html.ImageElement htmlImgElement = html.ImageElement();
        final imgLoadCompleter = Completer<void>();

        htmlImgElement.onLoad.listen((_) => imgLoadCompleter.complete());
        htmlImgElement.onError
            .listen((e) => imgLoadCompleter.completeError("이미지 디코딩 실패"));
        htmlImgElement.src = blobUrl;

        await imgLoadCompleter.future;

        int imgWidth = htmlImgElement.naturalWidth;
        int imgHeight = htmlImgElement.naturalHeight;

        if (kDebugMode) {
          print(
              "\n📄 [이미지 #${fileCount}/${files.length}] 파일명: ${file.name} | 해상도: ${imgWidth}x${imgHeight} | 원본 용량: ${originalKb} KB");
        }

        if (imgHeight > 1500) {
          if (kDebugMode) {
            print(
                "✂️ [Slice 분할 대상] 세로 높이(${imgHeight}px) > 1500px ➡️ 캔버스 자르기 실행");
          }
          List<XFile> rawChunks = await sliceLongImageWeb(
              htmlImgElement, imgWidth, imgHeight, (percent, msg) {
            double fileBase = (fileCount - 1) / files.length;
            double currentFilePercent = (percent * 0.5) / files.length;
            updateStatus((fileBase + currentFilePercent).clamp(0.0, 1.0),
                "[$fileCount/${files.length}] $msg");
          });

          // ⭐️ [신규] 잘라낸 슬라이스 조각들도 flutter_image_compress로 2차 압축!
          int chunkIndex = 0;
          for (var chunk in rawChunks) {
            chunkIndex++;
            updateStatus(
                ((fileCount -
                            1 +
                            (0.5 + (chunkIndex / rawChunks.length) * 0.5)) /
                        files.length)
                    .clamp(0.0, 1.0),
                "[$fileCount/${files.length}] 슬라이스 조각 #${chunkIndex} 경량화 압축 중...");

            final Uint8List chunkBytes = await chunk.readAsBytes();
            final Uint8List compressedChunkBytes =
                await FlutterImageCompress.compressWithList(
              chunkBytes,
              quality: 70, // 슬라이스 조각 최적화 퀄리티
              format: CompressFormat.jpeg,
            );

            final compressedChunk = XFile.fromData(
              compressedChunkBytes,
              name: chunk.name,
              mimeType: 'image/jpeg',
            );

            finalProcessedList.add(compressedChunk);

            if (kDebugMode) {
              final int beforeKb = chunkBytes.lengthInBytes ~/ 1024;
              final int afterKb = compressedChunkBytes.lengthInBytes ~/ 1024;
              print(
                  "   └ 🗜️ 조각 #${chunkIndex} 압축: ${beforeKb} KB ➡️ ${afterKb} KB");
            }
          }
        } else {
          updateStatus((fileCount / files.length).clamp(0.0, 1.0),
              "[$fileCount/${files.length}] flutter_image_compress 최적화 압축 중...");

          final Uint8List compressedBytes =
              await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1080,
            minHeight: 1080,
            quality: 75,
            format: CompressFormat.jpeg,
          );

          final int compressedKb = compressedBytes.lengthInBytes ~/ 1024;
          final double ratio = originalKb > 0
              ? ((originalKb - compressedKb) / originalKb * 100)
              : 0;

          if (kDebugMode) {
            print("🗜️ [flutter_image_compress 압축 완료]");
            print("   - 압축 전: ${originalKb} KB");
            print("   - 압축 후: ${compressedKb} KB");
            print("   - 절감률: ${ratio.toStringAsFixed(1)}% 감소");
          }

          final compressedFile = XFile.fromData(
            compressedBytes,
            name: file.name,
            mimeType: 'image/jpeg',
          );
          finalProcessedList.add(compressedFile);
        }

        html.Url.revokeObjectUrl(blobUrl);
      }

      if (kDebugMode) {
        print(
            "\n✅ [전체 이미지 처리 완료] 최종 생성된 업로드 큐 파일 수: ${finalProcessedList.length}개\n");
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
                title: '신상품 상품 업로드', isShowCloseBtn: true),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 5),
              child: SizedBox(
                height: 580,
                child: SingleChildScrollView(
                  controller: dialogScrollController, // ✨ 여기에 스크롤 컨트롤러 장착
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const Text('제 1차 카테고리 지정',
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

                                if (isDoubleCategoryEnabled.value &&
                                    isSyncSubCategory.value &&
                                    selectedPath2.value.isNotEmpty) {
                                  final tier1 = selectedPath2.value.first;
                                  final syncPath = [tier1];
                                  if (newPath.length > 1) {
                                    syncPath.addAll(newPath.sublist(1));
                                  }
                                  selectedPath2.value = syncPath;
                                }
                              }
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('카테고리 더블 업로드 (다른 코너에도 동시 진열하기)',
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
                          if (!isDoubleCategoryEnabled.value) {
                            isSyncSubCategory.value = false;
                          }
                        },
                      ),
                      if (isDoubleCategoryEnabled.value) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: CheckboxListTile(
                            title: const Text('메인 카테고리와 하위 그룹 동일하게 자동 지정',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            value: isSyncSubCategory.value,
                            activeColor: const Color(0xFF4A6FA5),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            onChanged: (val) {
                              isSyncSubCategory.value = val ?? false;

                              if (isSyncSubCategory.value &&
                                  selectedPath2.value.isNotEmpty) {
                                final tier1 = selectedPath2.value.first;
                                final syncPath = [tier1];
                                if (selectedPath1.value.length > 1) {
                                  syncPath
                                      .addAll(selectedPath1.value.sublist(1));
                                }
                                selectedPath2.value = syncPath;
                              }
                            },
                          ),
                        ),
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

                              final bool isSyncDisabled =
                                  isSyncSubCategory.value && levelIndex > 0;

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
                                    filled: isSyncDisabled,
                                    fillColor: isSyncDisabled
                                        ? Colors.grey.shade200
                                        : null,
                                  ),
                                  value: selectedVal,
                                  items: itemsInLevel.map((node) {
                                    return DropdownMenuItem<String>(
                                      value: node['title'] as String,
                                      child: Text(node['title'] as String),
                                    );
                                  }).toList(),
                                  onChanged: isSyncDisabled
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            if (isSyncSubCategory.value &&
                                                levelIndex == 0) {
                                              final newPath = [val];
                                              if (selectedPath1.value.length >
                                                  1) {
                                                newPath.addAll(selectedPath1
                                                    .value
                                                    .sublist(1));
                                              }
                                              selectedPath2.value = newPath;
                                            } else {
                                              final newPath = selectedPath2
                                                  .value
                                                  .take(levelIndex)
                                                  .toList();
                                              newPath.add(val);
                                              selectedPath2.value = newPath;
                                            }
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
                              labelText: '판매 가격 (원) *',
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
                      const Text('메인 도입부 및 상세이미지 등록 *',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'PC에서는 사진을 마우스로 드래그, 모바일은 우측 상단 아이콘을 터치하여 이동하세요\n순서상 맨앞의 사진이 자동으로 [메인 썸네일]이 됩니다.',
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
                            ? '파일 복사해 등록하기'
                            : '사진 변경하기 (${productImages.value.length}개 조각)'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6FA5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 0),
                      ),
                      const SizedBox(height: 12),
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
                                          child: const Text('메인',
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
                                    if (!isDesktopOrWeb)
                                      Positioned(
                                        bottom: 4,
                                        right: 16,
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 4)
                                              ],
                                            ),
                                            child: const Icon(
                                                Icons.open_with_rounded,
                                                color: Colors.white,
                                                size: 16),
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
                                  : () => Navigator.of(context)
                                      .pop(), // 취소 버튼으로만 닫을 수 있음
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
