import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ProductUploadDlg extends HookConsumerWidget {
  const ProductUploadDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final sizeController = useTextEditingController();

    // ⚡ [구조 변경] 대표/상세 통합된 단 하나의 이미지 조각 리스트 상태만 유지!
    final productImages = useState<List<XFile>>([]);
    final isLoading = useState<bool>(false);

    final selectedDepth1Title = useState<String?>(null);
    final selectedDepth2Title = useState<String?>(null);
    final selectedDepth3Title = useState<String?>(null);

    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    /// ✂️ [최종 완결판] 맨 마지막 조각에 2개가 겹치는 버그를 철통 방어하는 정밀 절삭 엔진
    Future<List<XFile>> sliceLongImage(
        Uint8List originalBytes, Function(double, String) onProgress) async {
      List<XFile> slicedFiles = [];

      final img.Image? srcImage = img.decodeImage(originalBytes);
      if (srcImage == null) return [];

      int originalWidth = srcImage.width;
      int originalHeight = srcImage.height;

      int maxSliceHeight = 3500;
      int minSliceHeight = 100; // ⚡ 짧은 이미지 방어선
      int currentY = 0;
      int index = 0;
      int scanStride = 10; // ⚡ 쾌속 스캔 보폭

      // 너그러운 여백 검사 가드 (미세 압축 먼지 무시)
      bool isRowBlank(img.Image image, int y) {
        int noiseCount = 0;
        int maxAllowedNoise = (image.width * 0.01).toInt();

        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (pixel.r < 243 || pixel.g < 243 || pixel.b < 243) {
            noiseCount++;
            if (noiseCount > maxAllowedNoise) return false;
          }
        }
        return true;
      }

      while (currentY < originalHeight) {
        double percent = (currentY / originalHeight).clamp(0.1, 0.95);
        onProgress(percent, "상세 페이지 [${index + 1}번째 조각] 여백 분석 중...");

        // ⭕ [구조 변경] 남은 높이가 maxSliceHeight 이하더라도 섣불리 종료하지 않고,
        // 일단 그 남은 구간 안에 '여백 절취선'이 더 존재하는지 한 번 더 꼼꼼히 뒤집니다!
        int searchLimitY = (currentY + maxSliceHeight).clamp(0, originalHeight);

        int bestCutY = searchLimitY;
        bool foundBlank = false;

        // 🎯 순방향 정밀 스캔 가동 (현재 Y에서 다음 마진 이후부터 searchLimitY까지 탐색)
        for (int checkY = currentY + minSliceHeight;
            checkY < searchLimitY;
            checkY += scanStride) {
          if (isRowBlank(srcImage, checkY)) {
            bestCutY = checkY;
            foundBlank = true;
            break; // ⚡ 남은 구간 내부에서 여백을 찾았다면 즉시 절단선 지정 후 탈출!
          }
        }

        // 만약 지정된 범위 안에서 여백을 전혀 못 찾았는데, 진짜 남은 이미지가 maxSliceHeight보다 작다면
        // 이때서야 비로소 진짜 마지막 조각으로 인정하고 남은 영역을 통째로 자릅니다.
        if (!foundBlank && (originalHeight - currentY <= maxSliceHeight)) {
          bestCutY = originalHeight;
        }
        // 만약 남은 높이는 3500px가 넘는데 여백을 못 찾았다면 역방향으로 맥시멈 라인을 잡습니다.
        else if (!foundBlank) {
          for (int checkY = searchLimitY;
              checkY >= currentY + minSliceHeight;
              checkY -= scanStride) {
            if (isRowBlank(srcImage, checkY)) {
              bestCutY = checkY;
              foundBlank = true;
              break;
            }
          }
        }

        // 조각 크기 최종 크롭 및 바이너리 추출
        int currentSliceHeight = bestCutY - currentY;

        // 안전 가드: 혹시 모를 오작동으로 제자리 슬라이싱(0px)이 일어나는 것을 방지
        if (currentSliceHeight <= 0) break;

        img.Image croppedZone = img.copyCrop(srcImage,
            x: 0,
            y: currentY,
            width: originalWidth,
            height: currentSliceHeight);
        final Uint8List chunkBytes =
            Uint8List.fromList(img.encodeJpg(croppedZone, quality: 95));

        slicedFiles.add(
          XFile.fromData(
            chunkBytes,
            mimeType: 'image/jpeg',
            name: 'chunk_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        // 자른 지점으로 워프
        currentY = bestCutY;
        index++;

        // 진짜 이미지 끝자락까지 도달했다면 루프 완전 탈출
        if (currentY >= originalHeight) break;
      }

      onProgress(1.0, "절삭 완료!");
      return slicedFiles;
    }

    String convertPathToCategory(String path) {
      if (path.isEmpty) return 'unknown';
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) return 'unknown';

      String result = parts[0];
      for (int i = 1; i < parts.length; i++) {
        String word = parts[i];
        final subParts = word.split('_');
        for (var sub in subParts) {
          if (sub.isNotEmpty) {
            result += sub[0].toUpperCase() + sub.substring(1);
          }
        }
      }
      return result;
    }

    // 카테고리 트리 파싱
    dynamic targetDepth1;
    for (var node in menuData) {
      if (node['title'] == selectedDepth1Title.value) {
        targetDepth1 = node;
        break;
      }
    }

    final List<dynamic> depth2List =
        (targetDepth1 != null && targetDepth1['children'] != null)
            ? targetDepth1['children']
            : [];
    dynamic targetDepth2;
    for (var node in depth2List) {
      if (node['title'] == selectedDepth2Title.value) {
        targetDepth2 = node;
        break;
      }
    }
    final List<dynamic> depth3List =
        (targetDepth2 != null && targetDepth2['children'] != null)
            ? targetDepth2['children']
            : [];

    bool isDepth2Valid = false;
    for (var node in depth2List) {
      if (node['title'] == selectedDepth2Title.value) {
        isDepth2Valid = true;
        break;
      }
    }
    bool isDepth3Valid = false;
    for (var node in depth3List) {
      if (node['title'] == selectedDepth3Title.value) {
        isDepth3Valid = true;
        break;
      }
    }

    final ImagePicker picker = ImagePicker();

    // 📸 [통합 이미지 단독 픽커 함수] - 고르자마자 1번째 조각이 자동 대표가 됨!
    Future<void> pickCombinedProductImage() async {
      final List<XFile>? files = await picker.pickMultiImage();
      if (files != null && files.isNotEmpty) {
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
                        minHeight: 10,
                      ),
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
          final Uint8List bytes =
              await file.readAsBytes(); // 중복 읽기 해결! 단 한 번만 로드 ⭐
          final img.Image? checkImg = img.decodeImage(bytes);

          if (checkImg != null && checkImg.height > 4000) {
            List<XFile> chunks = await sliceLongImage(bytes, (percent, msg) {
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
    }

    // 🚀 [최종 진화형] 서버 전송 시에도 실시간 프로그레스 바 팝업 강제 연동
    Future<void> submitProduct() async {
      dynamic finalTargetNode;
      if (selectedDepth3Title.value != null && depth3List.isNotEmpty) {
        for (var node in depth3List) {
          if (node['title'] == selectedDepth3Title.value) {
            finalTargetNode = node;
            break;
          }
        }
      } else if (selectedDepth2Title.value != null && depth2List.isNotEmpty) {
        finalTargetNode = targetDepth2;
      } else if (selectedDepth1Title.value != null) {
        finalTargetNode = targetDepth1;
      }

      if (finalTargetNode == null ||
          (finalTargetNode['children'] != null &&
              (finalTargetNode['children'] as List).isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🏷️ 카테고리를 소분류 끝까지 선택해 주세요!')));
        return;
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

        // 1. 프로그레스 값 초기화
        progress.value = 0.0;
        progressMsg.value = "구글 스토리지 세션 연결 중...";

        StateSetter? submitPopupSetState;

        // 2. 서버 전송 전용 프로그레스 다이얼로그 강제 소환! 🚀
        showDialog(
          context: context,
          barrierDismissible: false, // 전송 중 딴 데 눌러서 꺼지는 버그 가드
          builder: (context) {
            return StatefulBuilder(builder: (context, setPopupState) {
              submitPopupSetState = setPopupState; // 지휘봉 획득
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                content: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("☁️ 신상 상품 구글 클라우드 등록 중",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 20),

                      // 📊 서버 전송용 실시간 파란 게이지 바 가동!
                      LinearProgressIndicator(
                        value: progress.value,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF4A6FA5),
                        minHeight: 10,
                      ),
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

        // 팝업 내부 화면 강제 렌더링용 헬퍼 함수
        void updateSubmitStatus(double p, String m) {
          progress.value = p;
          progressMsg.value = m;
          if (submitPopupSetState != null) {
            submitPopupSetState!(() {});
          }
        }

        final String mappedCategory =
            convertPathToCategory(finalTargetNode['path'] ?? '');

        // 3. 콜백을 탑재하여 수정된 리포지토리 함수 전격 호출! ⭐
        await ref.read(productRepositoryProvider).uploadFullProduct(
              name: nameController.text.trim(),
              price: int.parse(priceController.text.trim()),
              category: mappedCategory,
              size: sizeController.text.trim(),
              imageFiles: productImages.value,
              onProgress: (percent, message) {
                // 구글 스토리지에서 던져주는 진행률과 안내 문구를 팝업창에 실시간으로 때려 박습니다.
                updateSubmitStatus(percent, message);
              },
            );

        // 4. 전송 완료 시 띄워둔 전송용 프로그레스 다이얼로그 먼저 닫기
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // 5. 최종 상품 등록 다이얼로그(본체 창) 닫고 스낵바 출력
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🎉 [${finalTargetNode['title']}] 상품 등록 완료!')));
        }
      } catch (e) {
        // 에러나서 터졌을 때도 팝업창은 닫아주는 안전장치
        if (context.mounted && ModalRoute.of(context)?.isCurrent == false) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ 등록 실패: $e')));
      } finally {
        isLoading.value = false;
      }
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- 카테고리 폼 (기존과 동일) ---
                    const Text('🏷️ 카테고리 지정',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: '대분류 (1단계)', border: OutlineInputBorder()),
                      value: selectedDepth1Title.value,
                      items: menuData
                          .map((node) => DropdownMenuItem<String>(
                              value: node['title'] as String,
                              child: Text(node['title'] as String)))
                          .toList(),
                      onChanged: (val) {
                        selectedDepth1Title.value = val;
                        selectedDepth2Title.value = null;
                        selectedDepth3Title.value = null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedDepth1Title.value != null &&
                        depth2List.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: '중분류 (2단계)',
                            border: OutlineInputBorder()),
                        value: isDepth2Valid ? selectedDepth2Title.value : null,
                        items: depth2List
                            .map((node) => DropdownMenuItem<String>(
                                value: node['title'] as String,
                                child: Text(node['title'] as String)))
                            .toList(),
                        onChanged: (val) {
                          selectedDepth2Title.value = val;
                          selectedDepth3Title.value = null;
                        },
                      ),
                    const SizedBox(height: 10),
                    if (selectedDepth2Title.value != null &&
                        depth3List.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: '상세 소분류 (3단계)',
                            border: OutlineInputBorder()),
                        value: isDepth3Valid ? selectedDepth3Title.value : null,
                        items: depth3List
                            .map((node) => DropdownMenuItem<String>(
                                value: node['title'] as String,
                                child: Text(node['title'] as String)))
                            .toList(),
                        onChanged: (val) {
                          selectedDepth3Title.value = val;
                        },
                      ),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider()),

                    // --- 텍스트 필드 폼 (기존과 동일) ---
                    TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: '상품명 *', border: OutlineInputBorder())),
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
                            labelText: '사이즈', border: OutlineInputBorder())),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider()),

                    // ---------------------------------------------------------------------
                    // ⚡ [완전 단축] 메인/상세 통합 이미지 업로드 UI 구역
                    // ---------------------------------------------------------------------
                    const Text('📸 도매처 통이미지 등록 *',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('첫 번째 조각이 자동으로 메인 대표 썸네일로 지정됩니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 💡 [실시간 프리뷰 구역] 맨 첫 번째 조각을 대표 이미지 마크해주는 센스!
                    if (productImages.value.isNotEmpty)
                      Container(
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productImages.value.length,
                          itemBuilder: (context, index) {
                            final file = productImages.value[index];
                            final isFirst = index == 0; // 대표 이미지 플래그
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  Container(
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
                                      child: Image.network(file.path,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                  // ⭐ 대표 이미지 뱃지 달아주기
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
                                  // ❌ 삭제 버튼
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
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // --- 하단 취소/등록 버튼 동일 ---
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
          ],
        ));
  }
}
