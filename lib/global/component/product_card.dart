// 3. 개별 상품 카드 컴포넌트
import 'package:flutter/material.dart';
import 'package:more_pic/model/product_item.dart';

class ProductCard extends StatelessWidget {
  final ProductItem product;
  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1 / 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Center(
              child:
                  Icon(Icons.image_outlined, color: Colors.black26, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          product.option,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          product.size,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A6FA5),
              fontWeight: FontWeight.w400),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          product.originalPrice,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
            decoration: product.originalPrice != product.salePrice
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          product.salePrice,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ],
    );
  }
}