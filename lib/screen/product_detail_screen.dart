import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/data/inner_data.dart';
import 'package:more_pic/data/kids_outer_jumper_jacket_data.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/data/new_born_socks_data.dart';
import 'package:more_pic/model/product_item.dart';

class ProductDetailScreen extends HookConsumerWidget {
  final String category; // newbornClothes, kidsOuter 등
  final String productId; // p_001 등

  const ProductDetailScreen(
      {super.key, required this.category, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ 넘겨받은 카테고리 주소에 따라 뒤져야 할 데이터셋을 타겟팅합니다.
    List<ProductItem> targetData;
    switch (category) {
      case 'newbornClothes':
        targetData = newBornClothesProducts;
        break;
      case 'newbornSocks':
        targetData = newBornSocksProducts;
        break;
      case 'kidsOuter':
        targetData = kidsOuterJumperJacketData;
        break;
      case 'inner':
        targetData = innerData;
        break;
      default:
        targetData = []; // 예외 가드
    }

    // 2️⃣ 타겟팅된 데이터 리스트에서 ID가 일치하는 상품 딱 1개를 찾습니다.
    final product = targetData.firstWhere(
      (item) => item.id == productId,
      orElse: () => ProductItem(
          id: "-1",
          name: '상품 없음',
          size: '',
          price: 0,
          image: '',
          detailImages: [],
          categoryName: ''),
    );

    // 3️⃣ 찾아온 단 하나의 product 데이터로 화면을 똑같이 그려줍니다.
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Center(
          child: Column(
        children: [
          Image.network(product.image),
          Column(
            children:
                product.detailImages.map((url) => Image.network(url)).toList(),
          )
        ],
      )),
    );
  }
}
