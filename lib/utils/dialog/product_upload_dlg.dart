// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:more_pic/global/custom_widget/custom_widget.dart';
// import 'package:more_pic/provider/product_db_provider.dart';

// class ProductUploadDlg extends HookConsumerWidget {
//   final String category;

//   const ProductUploadDlg({super.key, required this.category});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final nameController = useTextEditingController();
//     final priceController = useTextEditingController();
//     final sizeController =
//         useTextEditingController(text: '80, 90'); // 💡 기본값을 주거나 비워둘 수 있습니다.

//     final mainImage = useState<XFile?>(null);
//     final detailImages = useState<List<XFile>>([]);

//     final picker = ImagePicker();

//     Future<void> pickMainImage() async {
//       final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         mainImage.value = XFile(pickedFile.path);
//       }
//     }

//     Future<void> pickDetailImages() async {
//       final pickedFiles = await picker.pickMultiImage();
//       if (pickedFiles != null) {
//         final List<XFile> updatedList = [
//           ...detailImages.value,
//           ...pickedFiles.map((e) => XFile(e.path))
//         ].take(3).toList();
//         detailImages.value = updatedList;
//       }
//     }

//     return CustomWidget.dialogCustomForm(
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CustomWidget.customDialogTitle(context, ref,
//                 title: '새 상품 업로드', isShowCloseBtn: true),
//             const SizedBox(height: 15),

//             // 📝 텍스트 입력 섹션 (상품명)
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(
//                   labelText: '상품명', border: OutlineInputBorder()),
//             ),
//             const SizedBox(height: 15),

//             // 📝 텍스트 입력 섹션 (가격)
//             TextField(
//               controller: priceController,
//               decoration: const InputDecoration(
//                   labelText: '가격',
//                   border: OutlineInputBorder(),
//                   suffixText: '원'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 15),

//             // 📝 텍스트 입력 섹션 (사이즈 추가! ⭐️)
//             TextField(
//               controller: sizeController,
//               decoration: const InputDecoration(
//                   labelText: '사이즈 정보 (예: 80, 90, 100)',
//                   border: OutlineInputBorder()),
//             ),
//             const SizedBox(height: 25),

//             // 🖼️ 대표 이미지 영역
//             const Text('대표 이미지 (1개 필수)',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//             const SizedBox(height: 8),
//             InkWell(
//               onTap: pickMainImage,
//               child: Container(
//                 width: double.infinity,
//                 height: 150,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: (mainImage.value != null &&
//                         mainImage.value!.path.isNotEmpty)
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           mainImage.value!.path,
//                           fit: BoxFit.cover,
//                           // 혹시나 브라우저가 또 헛발질 주소를 긁을 때 쾅 터지는 걸 방지하는 에러 가드
//                           errorBuilder: (context, error, stackTrace) =>
//                               const Center(
//                             child: Icon(Icons.broken_image_outlined,
//                                 color: Colors.red, size: 32),
//                           ),
//                         ),
//                       )
//                     : const Center(
//                         child: Icon(Icons.add_a_photo_outlined,
//                             color: Colors.grey, size: 32)),
//               ),
//             ),
//             const SizedBox(height: 25),

//             // 🖼️ 상세 이미지 영역 (최대 3개)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('상세 이미지 (${detailImages.value.length}/3)',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 14)),
//                 if (detailImages.value.length < 3)
//                   TextButton.icon(
//                     onPressed: pickDetailImages,
//                     icon: const Icon(Icons.add, size: 16),
//                     label: const Text('추가'),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: 3,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//               ),
//               itemBuilder: (context, index) {
//                 final bool hasData = index < detailImages.value.length;
//                 return Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     border: Border.all(color: Colors.grey.shade200),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: hasData
//                       ? Stack(
//                           children: [
//                             Positioned.fill(
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(6),
//                                 child: Image.network(
//                                     detailImages.value[index].path,
//                                     fit: BoxFit.cover),
//                               ),
//                             ),
//                             Positioned(
//                               top: 2,
//                               right: 2,
//                               child: InkWell(
//                                 onTap: () {
//                                   final list = [...detailImages.value];
//                                   list.removeAt(index);
//                                   detailImages.value = list;
//                                 },
//                                 child: Container(
//                                   decoration: const BoxDecoration(
//                                       color: Colors.black54,
//                                       shape: BoxShape.circle),
//                                   child: const Icon(Icons.close,
//                                       color: Colors.white, size: 16),
//                                 ),
//                               ),
//                             )
//                           ],
//                         )
//                       : const Center(
//                           child:
//                               Icon(Icons.image_outlined, color: Colors.grey)),
//                 );
//               },
//             ),
//             const SizedBox(height: 35),

//             // 🚀 최종 서버 제출 버튼
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF6B4EAD),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: () async {
//                   if (nameController.text.isEmpty ||
//                       priceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('상품명과 가격을 입력해 주세요.')));
//                     return;
//                   }
//                   if (mainImage.value == null) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('대표 이미지는 필수 등록 항목입니다.')));
//                     return;
//                   }

//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (context) => const Center(
//                         child: CircularProgressIndicator(
//                             color: Color(0xFF6B4EAD))),
//                   );

//                   try {
//                     // 💡 size 변수까지 야무지게 바인딩해서 파이어베이스에 토스!
//                     await ref
//                         .read(productDBProvider(category).notifier)
//                         .uploadProduct(
//                           name: nameController.text,
//                           price: int.tryParse(priceController.text) ?? 0,
//                           size: sizeController.text, // 👈 추가된 size 입력값 배달!
//                           mainImageFile: mainImage.value!,
//                           detailImageFiles: detailImages.value,
//                         );

//                     if (context.mounted) {
//                       Navigator.pop(context); // 로딩 다이얼로그 닫기
//                       Navigator.pop(context); // 업로드 팝업 창 닫기
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                           content: Text('구글 서버에 성공적으로 등록되었습니다!🎉')));
//                     }
//                   } catch (e) {
//                     if (context.mounted) Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('업로드 중 장애 발생: $e')));
//                   }
//                 },
//                 child: const Text('서버에 등록하기',
//                     style:
//                         TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/provider/product_provider.dart';

class ProductUploadDlg extends HookConsumerWidget {
  const ProductUploadDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final sizeController = useTextEditingController();

    final mainImage = useState<XFile?>(null);
    final detailImages = useState<List<XFile>>([]);
    final isLoading = useState<bool>(false);

    // 단순 문자열 상태값 유지
    final selectedDepth1Title = useState<String?>(null);
    final selectedDepth2Title = useState<String?>(null);
    final selectedDepth3Title = useState<String?>(null);

    // 공용 메뉴 데이터
    final List<dynamic> menuData = [
      {
        'title': '신생아~3M',
        'children': [
          {'title': '옷', 'path': '/newborn/clothes'},
          {'title': '양말 등 잡화', 'path': '/newborn/socks'},
        ]
      },
      {
        'title': 'BABY (0~18m)',
        'children': [
          {
            'title': 'OUTER',
            'children': [
              {'title': '점퍼/자켓', 'path': '/baby/outer/jumper_jacket'},
              {
                'title': '가디건',
                'children': [
                  {
                    'title': '(상세분류) Cropped',
                    'path': '/baby/outer/cardigan/cropped'
                  },
                  {
                    'title': '(상세분류) Graphic Tees',
                    'path': '/baby/outer/cardigan/graphic_tees'
                  },
                ]
              },
              {'title': '조끼', 'path': '/baby/outer/vest'},
            ]
          },
          {'title': 'TOP', 'path': '/baby/top'},
          {'title': 'BOTTOM', 'path': '/baby/bottom'},
          {'title': 'SET/DRESS', 'path': '/baby/set_dress'},
        ]
      },
      {
        'title': 'KIDS (24m~)',
        'children': [
          {
            'title': 'OUTER',
            'children': [
              {'title': '점퍼/자켓', 'path': '/kids/outer/jumper_jacket'},
              {
                'title': '가디건',
                'children': [
                  {
                    'title': '(상세분류) Cropped',
                    'path': '/kids/outer/cardigan/cropped'
                  },
                  {
                    'title': '(상세분류) Graphic Tees',
                    'path': '/kids/outer/cardigan/graphic_tees'
                  },
                ]
              },
              {'title': '조끼', 'path': '/kids/outer/vest'},
            ]
          },
          {'title': 'TOP', 'path': '/kids/top'},
          {'title': 'BOTTOM', 'path': '/kids/bottom'},
          {'title': 'SET/DRESS', 'path': '/kids/set_dress'},
        ]
      },
      {'title': '내복', 'path': '/inner'},
      {
        'title': 'ACC',
        'children': [
          {'title': '양말(BABY)', 'path': '/acc/socks_baby'},
          {'title': '양말(KIDS)', 'path': '/acc/socks_kids'},
          {'title': '모자/보넷', 'path': '/acc/hats_beanies'},
          {'title': '헤어악세사리', 'path': '/acc/hair_accessories'},
          {'title': '기타', 'path': '/acc/other'},
        ]
      },
      {
        'title': 'SEASON',
        'children': [
          {'title': '여름(수영복 등)', 'path': '/season/summer'},
          {'title': '겨울(방한아이템 등)', 'path': '/season/winter'},
          {'title': '명절(한복 등)', 'path': '/season/holidays'},
        ]
      },
      {'title': 'SALE', 'path': '/sale'},
    ];

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

    // 💡 [초안전 모드] firstWhere를 통째로 폐기하고 순수 고전 for 루프로만 타겟을 추출합니다.
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

    // 중분류/소분류 리스트 안에 현재 선택된 타이틀 잔상이 진짜 존재하는지 검증용 플래그
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
    Future<void> pickMainImage() async {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) mainImage.value = file;
    }

    Future<void> pickDetailImages() async {
      final List<XFile> files = await picker.pickMultiImage();
      detailImages.value = [...detailImages.value, ...files];
    }

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

      bool hasMoreChildren = false;
      if (finalTargetNode != null && finalTargetNode['children'] != null) {
        hasMoreChildren = (finalTargetNode['children'] as List).isNotEmpty;
      }

      if (finalTargetNode == null || hasMoreChildren) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🏷️ 상품 카테고리를 하위 상세 분류까지 끝까지 선택해 주세요!')),
        );
        return;
      }

      if (nameController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty ||
          mainImage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📝 상품명, 가격, 대표 이미지는 필수 항목입니다!')),
        );
        return;
      }

      try {
        isLoading.value = true;
        final String finalPath = finalTargetNode['path'] ?? '';
        final String mappedCategory = convertPathToCategory(finalPath);

        await ref.read(productRepositoryProvider).uploadFullProduct(
              name: nameController.text.trim(),
              price: int.parse(priceController.text.trim()),
              category: mappedCategory,
              size: sizeController.text.trim(),
              mainImageFile: mainImage.value!,
              detailImageFiles: detailImages.value,
            );

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '🎉 [${finalTargetNode['title']}] 카테고리에 상품이 진열되었습니다!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ 등록 실패: $e')));
      } finally {
        isLoading.value = false;
      }
    }

    return AlertDialog(
      title: const Text('✨ 신규 부업 상품 진열하기',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏷️ 카테고리 지정',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),

              // 1단계 대분류
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: '대분류 (1단계)', border: OutlineInputBorder()),
                value: selectedDepth1Title.value,
                items: menuData.map((node) {
                  return DropdownMenuItem<String>(
                    value: node['title'] as String,
                    child: Text(node['title'] as String),
                  );
                }).toList(),
                onChanged: (val) {
                  selectedDepth1Title.value = val;
                  selectedDepth2Title.value = null;
                  selectedDepth3Title.value = null;
                },
              ),
              const SizedBox(height: 10),

              // 2단계 중분류
              if (selectedDepth1Title.value != null && depth2List.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: '중분류 (2단계)', border: OutlineInputBorder()),
                  value: isDepth2Valid ? selectedDepth2Title.value : null,
                  items: depth2List.map((node) {
                    return DropdownMenuItem<String>(
                      value: node['title'] as String,
                      child: Text(node['title'] as String),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedDepth2Title.value = val;
                    selectedDepth3Title.value = null;
                  },
                ),
              const SizedBox(height: 10),

              // 3단계 소분류
              if (selectedDepth2Title.value != null && depth3List.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: '상세 소분류 (3단계)', border: OutlineInputBorder()),
                  value: isDepth3Valid ? selectedDepth3Title.value : null,
                  items: depth3List.map((node) {
                    return DropdownMenuItem<String>(
                      value: node['title'] as String,
                      child: Text(node['title'] as String),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedDepth3Title.value = val;
                  },
                ),

              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider()),

              // [B] 입력 폼
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '상품명 *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '판매 가격(원) *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                      labelText: '사이즈', border: OutlineInputBorder())),
              const SizedBox(height: 16),

              // [C] 이미지 픽커 존
              const Text('🖼️ 대표 이미지(Main) *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: pickMainImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6)),
                  child: (mainImage.value != null &&
                          mainImage.value!.path.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(mainImage.value!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.broken_image))),
                        )
                      : const Center(
                          child: Icon(Icons.add_a_photo_outlined,
                              color: Colors.grey, size: 28)),
                ),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------------
// 📸 [D] 상세 이미지 리스트 및 프리뷰/삭제 구역 (추가 및 교체)
// ---------------------------------------------------------------------
              const Text('📸 상세 이미지 리스트(선택)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

// 사진 선택 버튼
              ElevatedButton.icon(
                onPressed: pickDetailImages,
                icon: const Icon(Icons.collections),
                label: Text('상세 사진 추가 (${detailImages.value.length}개)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 10),

// 💡 [핵심 추가] 선택된 상세 사진들이 있을 때만 썸네일 가로 스크롤 리스트를 펼칩니다.
              if (detailImages.value.isNotEmpty)
                Container(
                  height: 90, // 썸네일이 들어갈 아담한 세로 높이
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // 가로 스크롤 활성화
                    itemCount: detailImages.value.length,
                    itemBuilder: (context, index) {
                      final file = detailImages.value[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            // 1. 이미지 썸네일 박스
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(
                                  top: 6, right: 6), // X 버튼 공간 마련을 위한 마진
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  file.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            // 2. ❌ 우측 상단 개별 삭제 버튼 무브!
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () {
                                  // 💡 클릭한 인덱스의 사진만 리스트에서 쏙 빼서 제외시킵니다.
                                  final updatedList =
                                      List<XFile>.from(detailImages.value);
                                  updatedList.removeAt(index);
                                  detailImages.value = updatedList;
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
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
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed:
                isLoading.value ? null : () => Navigator.of(context).pop(),
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
    );
  }
}
