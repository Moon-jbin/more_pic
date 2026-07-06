// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:more_pic/data/acc_hair_acc_data.dart';
// import 'package:more_pic/data/acc_hats_beanies_data.dart';
// import 'package:more_pic/data/acc_other_data.dart';
// import 'package:more_pic/data/acc_socks_baby_data.dart';
// import 'package:more_pic/data/acc_socks_kids_data.dart';
// import 'package:more_pic/data/baby_bottom_data.dart';
// import 'package:more_pic/data/baby_outer_cardigan_grapich_tees_data.dart';
// import 'package:more_pic/data/baby_outer_jumper_jacket_data.dart';
// import 'package:more_pic/data/baby_outer_vest_data.dart';
// import 'package:more_pic/data/baby_outter_cardigan_cropped_data.dart';
// import 'package:more_pic/data/baby_set_dress_data.dart';
// import 'package:more_pic/data/baby_top_data.dart';
// import 'package:more_pic/data/inner_data.dart';
// import 'package:more_pic/data/kids_bottom_data.dart';
// import 'package:more_pic/data/kids_outer_cardigan_grapich_tees_data.dart';
// import 'package:more_pic/data/kids_outer_jumper_jacket_data.dart';
// import 'package:more_pic/data/kids_outer_vest_data.dart';
// import 'package:more_pic/data/kids_outter_cardigan_cropped_data.dart';
// import 'package:more_pic/data/kids_set_dress_data.dart';
// import 'package:more_pic/data/kids_top_data.dart';
// import 'package:more_pic/data/new_born_clothes_data.dart';
// import 'package:more_pic/data/new_born_socks_data.dart';
// import 'package:more_pic/data/sale_data.dart';
// import 'package:more_pic/data/season_holidays_data.dart';
// import 'package:more_pic/data/season_summer_data.dart';
// import 'package:more_pic/data/season_winter_data.dart';
// import 'package:more_pic/global/component/product_list_page.dart';
// import 'package:more_pic/global/custom_widget.dart';

// ///```
// /// 신생아~3M / 옷 Page
// ///```
// class NewbornClothesScreen extends HookConsumerWidget {
//   const NewbornClothesScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomScaffold(bodyBuilder: (context, scrollController) {
//       return ProductListPage(
//           itemData: newBornClothesProducts, scrollController: scrollController);
//     });
//   }
// }

// ///```
// /// 신생아~3M / 양말 등 잡화 Page
// ///```
// class NewbornSocksScreen extends HookConsumerWidget {
//   const NewbornSocksScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: newBornSocksProducts));
//   }
// }

// ////////=====================BABY=======================================
// ///```
// /// BABY (0~18) / OUTER / 점퍼 자켓 Page
// ///```
// class BabyOuterJumperJacketScreen extends HookConsumerWidget {
//   const BabyOuterJumperJacketScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyOuterJumperJacketData));
//   }
// }

// ///```
// /// BABY (0~18) / OUTER / 가디건 / Cropped Page
// ///```
// class BabyOuterCardiganCroppedScreen extends HookConsumerWidget {
//   const BabyOuterCardiganCroppedScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyOuterCardiganCroppedData));
//   }
// }

// ///```
// /// BABY (0~18) / OUTER / 가디건 / Graphic Tees Page
// ///```
// class BabyOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
//   const BabyOuterCardiganGraphicTeesScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyOuterCardiganGrapichTeesData));
//   }
// }

// ///```
// /// BABY (0~18) / OUTER / vest Page
// ///```
// class BabyOuterVestScreen extends HookConsumerWidget {
//   const BabyOuterVestScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyOuterVestData));
//   }
// }

// ///```
// /// BABY (0~18) / TOP Page
// ///```
// class BabyTopScreen extends HookConsumerWidget {
//   const BabyTopScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyTopData));
//   }
// }

// ///```
// /// BABY (0~18) / BOTTOM Page
// ///```
// class BabyBottomScreen extends HookConsumerWidget {
//   const BabyBottomScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babyBottomData));
//   }
// }

// ///```
// /// BABY (0~18) / SET_DRESS Page
// ///```
// class BabySetDressScreen extends HookConsumerWidget {
//   const BabySetDressScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: babySetDressData));
//   }
// }

// //============================KIDS =================================
// ///```
// /// KIDS (24M~) / OUTER / 점퍼 자켓 Page
// ///```
// class KidsOuterJumperJacketScreen extends HookConsumerWidget {
//   const KidsOuterJumperJacketScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsOuterJumperJacketData));
//   }
// }

// ///```
// /// KIDS (24M~) / OUTER / 가디건 / Cropped Page
// ///```
// class KidsOuterCardiganCroppedScreen extends HookConsumerWidget {
//   const KidsOuterCardiganCroppedScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsOuterCardiganCroppedData));
//   }
// }

// ///```
// /// KIDS (24M~) / OUTER / 가디건 / Graphic Tees Page
// ///```
// class KidsOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
//   const KidsOuterCardiganGraphicTeesScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsOuterCardiganGrapichTeesData));
//   }
// }

// ///```
// /// KIDS (24M~) / OUTER / vest Page
// ///```
// class KidsOuterVestScreen extends HookConsumerWidget {
//   const KidsOuterVestScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsOuterVestData));
//   }
// }

// ///```
// /// KIDS (24M~) / TOP Page
// ///```
// class KidsTopScreen extends HookConsumerWidget {
//   const KidsTopScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsTopData));
//   }
// }

// ///```
// /// KIDS (24M~) / BOTTOM Page
// ///```
// class KidsBottomScreen extends HookConsumerWidget {
//   const KidsBottomScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsBottomData));
//   }
// }

// ///```
// /// KIDS (24M~) / SET_DRESS Page
// ///```
// class KidsSetDressScreen extends HookConsumerWidget {
//   const KidsSetDressScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: kidsSetDressData));
//   }
// }

// ///=======================내복==========================
// ///```
// /// 내복 Page
// ///```
// class InnerScreen extends HookConsumerWidget {
//   const InnerScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: innerData));
//   }
// }

// ///========================ACC===========================
// ///```
// /// ACC / 양말(BABY) Page
// ///```
// class AccSocksBabyScreen extends HookConsumerWidget {
//   const AccSocksBabyScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: accSocksBabyData));
//   }
// }

// ///```
// /// ACC / 양말(BABY) Page
// ///```
// class AccSocksKidsScreen extends HookConsumerWidget {
//   const AccSocksKidsScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: accSocksKidsData));
//   }
// }

// ///```
// /// ACC / 모제_보넷 Page
// ///```
// class AccHatsBeaniesScreen extends HookConsumerWidget {
//   const AccHatsBeaniesScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: accHatsBeaniesData));
//   }
// }

// ///```
// /// ACC / 헤어악세사리 Page
// ///```
// class AccHairAccScreen extends HookConsumerWidget {
//   const AccHairAccScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: accHairAccData));
//   }
// }

// ///```
// /// ACC / 기타 Page
// ///```
// class AccOtherScreen extends HookConsumerWidget {
//   const AccOtherScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: accOtherData));
//   }
// }

// ///========================SEASON ===================================
// ///```
// /// SEASON / 여름(수영복 등) Page
// ///```
// class SeasonSummerScreen extends HookConsumerWidget {
//   const SeasonSummerScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: seasonSummerData));
//   }
// }

// ///```
// /// SEASON / 겨울(방한아이템 등) Page
// ///```
// class SeasonWinterScreen extends HookConsumerWidget {
//   const SeasonWinterScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: seasonWinterData));
//   }
// }

// ///```
// /// SEASON / 명정(한복 등) Page
// ///```
// class SeasonHolidaysScreen extends HookConsumerWidget {
//   const SeasonHolidaysScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: seasonHolidaysData));
//   }
// }

// ///```
// /// Sale Page
// ///```
// class SaleScreen extends HookConsumerWidget {
//   const SaleScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return CustomWidget.customScaffold(context,
//         body: ProductListPage(itemData: saleData));
//   }
// }
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/data/acc_hair_acc_data.dart';
import 'package:more_pic/data/acc_hats_beanies_data.dart';
import 'package:more_pic/data/acc_other_data.dart';
import 'package:more_pic/data/acc_socks_baby_data.dart';
import 'package:more_pic/data/acc_socks_kids_data.dart';
import 'package:more_pic/data/baby_bottom_data.dart';
import 'package:more_pic/data/baby_outer_cardigan_grapich_tees_data.dart';
import 'package:more_pic/data/baby_outer_jumper_jacket_data.dart';
import 'package:more_pic/data/baby_outer_vest_data.dart';
import 'package:more_pic/data/baby_outter_cardigan_cropped_data.dart';
import 'package:more_pic/data/baby_set_dress_data.dart';
import 'package:more_pic/data/baby_top_data.dart';
import 'package:more_pic/data/inner_data.dart';
import 'package:more_pic/data/kids_bottom_data.dart';
import 'package:more_pic/data/kids_outer_cardigan_grapich_tees_data.dart';
import 'package:more_pic/data/kids_outer_jumper_jacket_data.dart';
import 'package:more_pic/data/kids_outer_vest_data.dart';
import 'package:more_pic/data/kids_outter_cardigan_cropped_data.dart';
import 'package:more_pic/data/kids_set_dress_data.dart';
import 'package:more_pic/data/kids_top_data.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/data/new_born_socks_data.dart';
import 'package:more_pic/data/sale_data.dart';
import 'package:more_pic/data/season_holidays_data.dart';
import 'package:more_pic/data/season_summer_data.dart';
import 'package:more_pic/data/season_winter_data.dart';
import 'package:more_pic/global/component/product_list_page.dart';
import 'package:more_pic/global/custom_widget.dart';

///```
/// 신생아~3M / 옷 Page
///```
class NewbornClothesScreen extends HookConsumerWidget {
  const NewbornClothesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: newBornClothesProducts, scrollController: scrollController);
    });
  }
}

///```
/// 신생아~3M / 양말 등 잡화 Page
///```
class NewbornSocksScreen extends HookConsumerWidget {
  const NewbornSocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: newBornSocksProducts, scrollController: scrollController);
    });
  }
}

////////=====================BABY=======================================
///```
/// BABY (0~18) / OUTER / 점퍼 자켓 Page
///```
class BabyOuterJumperJacketScreen extends HookConsumerWidget {
  const BabyOuterJumperJacketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyOuterJumperJacketData,
          scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / OUTER / 가디건 / Cropped Page
///```
class BabyOuterCardiganCroppedScreen extends HookConsumerWidget {
  const BabyOuterCardiganCroppedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyOuterCardiganCroppedData,
          scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / OUTER / 가디건 / Graphic Tees Page
///```
class BabyOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
  const BabyOuterCardiganGraphicTeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyOuterCardiganGrapichTeesData,
          scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / OUTER / vest Page
///```
class BabyOuterVestScreen extends HookConsumerWidget {
  const BabyOuterVestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyOuterVestData, scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / TOP Page
///```
class BabyTopScreen extends HookConsumerWidget {
  const BabyTopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyTopData, scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / BOTTOM Page
///```
class BabyBottomScreen extends HookConsumerWidget {
  const BabyBottomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babyBottomData, scrollController: scrollController);
    });
  }
}

///```
/// BABY (0~18) / SET_DRESS Page
///```
class BabySetDressScreen extends HookConsumerWidget {
  const BabySetDressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: babySetDressData, scrollController: scrollController);
    });
  }
}

//============================KIDS =================================
///```
/// KIDS (24M~) / OUTER / 점퍼 자켓 Page
///```
class KidsOuterJumperJacketScreen extends HookConsumerWidget {
  const KidsOuterJumperJacketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsOuterJumperJacketData,
          scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / OUTER / 가디건 / Cropped Page
///```
class KidsOuterCardiganCroppedScreen extends HookConsumerWidget {
  const KidsOuterCardiganCroppedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsOuterCardiganCroppedData,
          scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / OUTER / 가디건 / Graphic Tees Page
///```
class KidsOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
  const KidsOuterCardiganGraphicTeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsOuterCardiganGrapichTeesData,
          scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / OUTER / vest Page
///```
class KidsOuterVestScreen extends HookConsumerWidget {
  const KidsOuterVestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsOuterVestData, scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / TOP Page
///```
class KidsTopScreen extends HookConsumerWidget {
  const KidsTopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsTopData, scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / BOTTOM Page
///```
class KidsBottomScreen extends HookConsumerWidget {
  const KidsBottomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsBottomData, scrollController: scrollController);
    });
  }
}

///```
/// KIDS (24M~) / SET_DRESS Page
///```
class KidsSetDressScreen extends HookConsumerWidget {
  const KidsSetDressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: kidsSetDressData, scrollController: scrollController);
    });
  }
}

///=======================내복==========================
///```
/// 내복 Page
///```
class InnerScreen extends HookConsumerWidget {
  const InnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: innerData, scrollController: scrollController);
    });
  }
}

///========================ACC===========================
///```
/// ACC / 양말(BABY) Page
///```
class AccSocksBabyScreen extends HookConsumerWidget {
  const AccSocksBabyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: accSocksBabyData, scrollController: scrollController);
    });
  }
}

///```
/// ACC / 양말(KIDS) Page
///```
class AccSocksKidsScreen extends HookConsumerWidget {
  const AccSocksKidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: accSocksKidsData, scrollController: scrollController);
    });
  }
}

///```
/// ACC / 모자_보넷 Page
///```
class AccHatsBeaniesScreen extends HookConsumerWidget {
  const AccHatsBeaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: accHatsBeaniesData, scrollController: scrollController);
    });
  }
}

///```
/// ACC / 헤어악세사리 Page
///```
class AccHairAccScreen extends HookConsumerWidget {
  const AccHairAccScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: accHairAccData, scrollController: scrollController);
    });
  }
}

///```
/// ACC / 기타 Page
///```
class AccOtherScreen extends HookConsumerWidget {
  const AccOtherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: accOtherData, scrollController: scrollController);
    });
  }
}

///========================SEASON ===================================
///```
/// SEASON / 여름(수영복 등) Page
///```
class SeasonSummerScreen extends HookConsumerWidget {
  const SeasonSummerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: seasonSummerData, scrollController: scrollController);
    });
  }
}

///```
/// SEASON / 겨울(방한아이템 등) Page
///```
class SeasonWinterScreen extends HookConsumerWidget {
  const SeasonWinterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: seasonWinterData, scrollController: scrollController);
    });
  }
}

///```
/// SEASON / 명절(한복 등) Page
///```
class SeasonHolidaysScreen extends HookConsumerWidget {
  const SeasonHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: seasonHolidaysData, scrollController: scrollController);
    });
  }
}

///```
/// Sale Page
///
class SaleScreen extends HookConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(bodyBuilder: (context, scrollController) {
      return ProductListPage(
          itemData: saleData, scrollController: scrollController);
    });
  }
}
