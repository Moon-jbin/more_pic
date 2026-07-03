import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/global/component/product_list_page.dart';
import 'package:more_pic/global/custom_widget.dart';

class NewbornClothesScreen extends HookConsumerWidget {
  const NewbornClothesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomWidget.customScaffold(context,
        body: ProductListPage(itemData: newBornClothesProducts));
  }
}
