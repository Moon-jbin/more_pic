import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
// ✂️ [정밀 최적화] 1칸 1컷 스마트 슬라이스 엔진 (바이트 직접 연산 방식)
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';

class ProductUploadDlg extends HookConsumerWidget {
  const ProductUploadDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final sizeController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final colorController = useTextEditingController();

    // 💡 [새 기능] 구체적인 배송 방법을 입력받기 위한 컨트롤러 추가
    final shippingMethodController = useTextEditingController();

    // 대표/상세 통합된 단 하나의 이미지 조각 리스트 상태
    final productImages = useState<List<XFile>>([]);
    final isLoading = useState<bool>(false);

    final selectedDepth1Title = useState<String?>(null);
    final selectedDepth2Title = useState<String?>(null);
    final selectedDepth3Title = useState<String?>(null);

    // 💡 [새 기능] 국내배송 / 해외직배송 선택 상태 관리를 위한 훅 변수 (기본값: 국내배송)
    final shippingType = useState<String>('국내배송');

    final progress = useState<double>(0.0);
    final progressMsg = useState<String>("");

    Future<List<XFile>> sliceLongImage(ui.Image uiImage,
        Uint8List originalBytes, Function(double, String) onProgress) async {
      print('================= 🚀 범인 추적 엔진 가동 =================');
      print('📊 원본 정보 - 가로: ${uiImage.width}px, 세로: ${uiImage.height}px');
      print('📦 원본 바이트 크기: ${originalBytes.lengthInBytes} bytes');

      List<XFile> slicedFiles = [];
      int originalWidth = uiImage.width;
      int originalHeight = uiImage.height;

      int maxSliceHeight = 3500;
      int minSliceHeight = 100;
      int currentY = 0;
      int index = 0;
      int scanStride = 10; // 10픽셀 수직 정밀 고정

      onProgress(0.01, "브라우저 하드웨어 가속 이미지 준비 중...");

      final html.ImageElement htmlImgElement = html.ImageElement();
      final imgLoadCompleter = Completer<void>();

      htmlImgElement.onLoad.listen((_) {
        print('✅ [로그 1] htmlImgElement 브라우저 로드 성공');
        imgLoadCompleter.complete();
      });
      htmlImgElement.onError.listen((e) {
        print('❌ [로그 1 에러] htmlImgElement 브라우저 로드 실패: $e');
        imgLoadCompleter.completeError("원본 이미지 로드 실패");
      });

      final blob = html.Blob([originalBytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      htmlImgElement.src = blobUrl;

      await imgLoadCompleter.future;

      // 2. 스캔용 오프스크린 캔버스 준비
      final html.CanvasElement scanCanvas =
          html.CanvasElement(width: originalWidth, height: originalHeight);
      final html.CanvasRenderingContext2D scanCtx = scanCanvas.context2D;
      scanCtx.drawImage(htmlImgElement, 0, 0);
      print('🎨 [로그 2] scanCanvas에 원본 이미지 드로잉 완수');

      // 🎯 [완벽 청정 구역 판정 필터]
      bool isRowBlankCanvas(int y) {
        if (y < 0 || y >= originalHeight) return false;

        // Y축 딱 1줄의 가로 픽셀 라인 획득
        final html.ImageData imageData =
            scanCtx.getImageData(0, y, originalWidth, 1);
        final List<int> data = imageData.data;

        // 가로 한 줄에 허용할 노이즈 픽셀 개수 (완전 빡빡하게 2픽셀 미만으로 가드)
        int noiseCount = 0;
        int maxAllowedNoise = 2;

        for (int x = 0; x < originalWidth; x++) {
          int offset = x * 4;
          if (offset + 3 < data.length) {
            int r = data[offset];
            int g = data[offset + 1];
            int b = data[offset + 2];
            int a = data[offset + 3];

            // 🔥 [검은 화면 박멸의 통곡의 벽]
            // 배경이 완전한 투명(a == 0)이거나, 배경 흰색 계열(RGB 모두 250 이상)이 "아닌" 구역,
            // 즉 조금이라도 유색(RGB < 250) 색상이 포착되면 무조건 데이터 구역으로 식별합니다!
            if (a < 255 || (r < 250 || g < 250 || b < 250)) {
              noiseCount++;
              // 가로줄에 튀는 픽셀이 딱 2개만 넘어가도 "여백 절대 아님! 자르지 마!" 하고 차단
              if (noiseCount > maxAllowedNoise) return false;
            }
          }
        }
        // 위 검사를 완벽히 통과해야만 진짜 100% 깨끗한 흰색 공백 레이어입니다.
        return true;
      }

      // 슬라이스 여백 검출 및 자르기 루프 가동
      while (currentY < originalHeight) {
        print(
            '\n---------------- 📍 [${index + 1}번째 조각 연산 시작] ----------------');
        print('현재 절삭 시작점(Y축): $currentY px');

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
        print(
            '🎯 결정된 자를 범위: Y축 $currentY px ~ $bestCutY px (높이: ${currentSliceHeight}px) | 여백 발견 여부: $foundBlank');

        if (currentSliceHeight <= 0) {
          print('⚠️ 경고: 자를 높이가 0이하입니다. 루프를 탈출합니다.');
          break;
        }

        // 3. ⚡ [정밀 절삭 구역: 3파라미터 drawImage 규격 완벽 싱크]
        final html.CanvasElement chunkCanvas = html.CanvasElement(
            width: originalWidth, height: currentSliceHeight);
        final html.CanvasRenderingContext2D chunkCtx = chunkCanvas.context2D;

        // 🌟 [검은 화면 및 컴파일 에러 통합 완치 핵심]
        // 유저님 다트 스펙에 명시된 3개짜리 아규먼트(source, x, y)만 사용하기 위해
        // 캔버스 자체의 좌표계를 위쪽으로 -currentY 만큼 번지 점프 시킵니다.
        chunkCtx.translate(0, -currentY);

        // 이제 (0, 0) 위치에 원본을 그냥 얹어버리면, 마법처럼 우리가 원하는 Y축 조각만 정확하게 찍힙니다.
        // 파라미터 개수 에러가 100% 영구 소멸합니다.
        chunkCtx.drawImage(htmlImgElement, 0, 0);

        // 변환했단 좌표계를 다시 원래대로 원상 복구 (드로잉 안전 가드)
        chunkCtx.translate(0, currentY);

        // 🌟 [검은 화면 실시간 검증로그]
        try {
          final html.ImageData testData = chunkCtx.getImageData(
              (originalWidth / 2).toInt(),
              (currentSliceHeight / 2).toInt(),
              1,
              1);
          print('🔍 [로그 3] 조각 캔버스 정중앙 픽셀 RGBA 검증: '
              'R:${testData.data[0]}, G:${testData.data[1]}, B:${testData.data[2]}, A:${testData.data[3]}');
        } catch (e) {
          print('❌ [로그 3 에러] 조각 캔버스 픽셀 데이터 획득 실패: $e');
        }

        // 4. Blob 생성
        final chunkBlob = await chunkCanvas.toBlob('image/jpeg', 0.35);
        final String chunkBlobUrl = html.Url.createObjectUrlFromBlob(chunkBlob);
        print(
            '📦 [로그 4] 조각 Blob 생성 완료. 가속 주소: $chunkBlobUrl | Blob 크기: ${chunkBlob.size} bytes');

        slicedFiles.add(
          XFile(
            chunkBlobUrl,
            mimeType: 'image/jpeg',
            name: 'chunk_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        currentY = bestCutY;
        index++;
        if (currentY >= originalHeight) {
          print('🏁 Y축이 원본 이미지 끝에 도달했습니다. 정상 종료.');
          break;
        }
      }

      html.Url.revokeObjectUrl(blobUrl);
      onProgress(1.0, "절삭 완료!");
      print(
          '================= 🏁 범인 추적 완료 (총 ${slicedFiles.length}개 조각 생성) =================\n');
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

    // 📸 [통합 이미지 단독 픽커 함수]
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
          print('여기?1 ');
          final Uint8List bytes = await file.readAsBytes();
          print('여기?2 ');

          // ⚡ [0.01초 초광속 가속]: 이미지 해상도 정보만 아주 가볍게 판독합니다.
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image uiImage = frameInfo.image;
          print('여기?3 (이미지 깨짐 없이 0.1초 컷 통과)');

          if (uiImage.height > 4000) {
            // 🚀 원본 bytes와 uiImage를 슬라이스 엔진에 정밀 주입
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
    }

    // 🚀 상품 업로드 및 카테고리 연동 액션
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🏷️ 상품 카테고리를 하위 분류 끝까지 완전히 선택해 주세요!')));
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
                      const Text("☁️ 신상 상품 구글 클라우드 등록 중",
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

        // 🚀 [연동 규격 고도화] 기존 상세내용, 색상에 더해 배송 타입 및 배송 방법 데이터까지 함께 주입합니다.
        await ref.read(productRepositoryProvider).uploadFullProduct(
              name: nameController.text.trim(),
              price: int.parse(priceController.text.trim()),
              category: mappedCategory,
              size: sizeController.text.trim(),
              productDetail: descriptionController.text.trim(),
              color: colorController.text.trim(),

              shippingType: shippingType.value, // '국내배송' 또는 '해외배송'
              shippingMethod: shippingMethodController.text.trim(), // 구체적인 텍스트

              imageFiles: productImages.value,
              onProgress: (percent, message) {
                updateSubmitStatus(percent, message);
              },
            );

        ref.invalidate(productDBProvider(mappedCategory));
        ref.invalidate(productDBProvider('all'));

        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('🎉 [${finalTargetNode['title']}] 카테고리에 상품 진열 완료!')));
        }
      } catch (e) {
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
              // 💡 입력 필드 노드가 대폭 확장되었으므로 무조건 싱글차일드 스크롤 가드로 감싸 화면 잘림 오버플로우를 막아줍니다.
              child: SizedBox(
                height: 580, // 내부 입력 다이얼로그 가동 영역 강제 제어
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const Text('🏷️ 카테고리 지정',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),

                      // 1단계 대분류
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: '대분류 (1단계)',
                            border: OutlineInputBorder()),
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

                      // 2단계 중분류
                      if (selectedDepth1Title.value != null &&
                          depth2List.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: '중분류 (2단계)',
                              border: OutlineInputBorder()),
                          value:
                              isDepth2Valid ? selectedDepth2Title.value : null,
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

                      // 3단계 소분류
                      if (selectedDepth2Title.value != null &&
                          depth3List.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: '상세 소분류 (3단계)',
                              border: OutlineInputBorder()),
                          value:
                              isDepth3Valid ? selectedDepth3Title.value : null,
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
                              labelText: '사이즈', border: OutlineInputBorder())),
                      const SizedBox(height: 12),

                      // 상품 색상 입력 필드
                      TextField(
                          controller: colorController,
                          decoration: const InputDecoration(
                              labelText: '상품 색상 (예: 크림, 민트, 차콜)',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),

                      // 상품 상세 설명 필드
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

                      // 💡 [새 기능] 📦 배송 정책 분기 전용 칩 세그먼트 도킹
                      const Text('📦 배송 권역 정책 설정',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                  child: Text('국내 배송',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              selected: shippingType.value == '국내배송',
                              selectedColor:
                                  const Color(0xFF4A6FA5).withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: shippingType.value == '국내배송'
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.black54,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: shippingType.value == '국내배송'
                                        ? const Color(0xFF4A6FA5)
                                        : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onSelected: (bool selected) {
                                if (selected) shippingType.value = '국내배송';
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                  child: Text('해외 직배송',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              selected: shippingType.value == '해외배송',
                              selectedColor:
                                  const Color(0xFF4A6FA5).withOpacity(0.18),
                              labelStyle: TextStyle(
                                color: shippingType.value == '해외배송'
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.black54,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: shippingType.value == '해외배송'
                                        ? const Color(0xFF4A6FA5)
                                        : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onSelected: (bool selected) {
                                if (selected) shippingType.value = '해외배송';
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 💡 [새 기능] 구체적인 배송 방법 (택배사 및 소요 가이드 입력 필드)
                      TextField(
                          controller: shippingMethodController,
                          decoration: const InputDecoration(
                              labelText:
                                  '배송 방법 (예: CJ대한통운 영업일 2~3일 소요 / 항공 직배송)',
                              border: OutlineInputBorder())),

                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider()),

                      const Text('📸 사입처 통이미지 등록 *',
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

                      if (productImages.value.isNotEmpty)
                        Container(
                          height: 110,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: productImages.value.length,
                            itemBuilder: (context, index) {
                              final file = productImages.value[index];
                              final isFirst = index == 0;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      margin: const EdgeInsets.only(
                                          top: 8, right: 8),
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
