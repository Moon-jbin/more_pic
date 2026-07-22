import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/model/product_item.dart';

bool isMobile(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  bool isMobile = screenWidth < 900;

  return isMobile;
}

// 예시: global.dart 파일 내부 혹은 하단
// 💡 각 카테고리 페이지의 리스트들을 스프레드 연산자(...)로 전부 합쳐버립니다.
final List<ProductItem> allProducts = [
  ...newBornClothesProducts,
  // ...babyProducts,    <-- 다른 카테고리 데이터 리스트가 생길 때마다
  // ...kidsProducts,    <-- 여기에 쉼표 찍고 차곡차곡 추가해 주시면 됩니다!
];

String numberFormat(int number) {
  String format = NumberFormat('#,###').format(number);

  return format;
}

const String kakaoUrl = 'https://pf.kakao.com/_xbyxdwX';
const String accountNumber = '3333-37-7919709';
