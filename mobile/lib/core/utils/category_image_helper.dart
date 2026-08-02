import 'package:flutter/material.dart';

/// Returns the asset path for a category image based on [categoryCode] and optional [categoryName].
String getCategoryAssetPath(String? categoryCode, [String? categoryName]) {
  final code = (categoryCode ?? '').toUpperCase().trim();
  final name = (categoryName ?? '').toLowerCase().trim();

  // 1. BEVERAGE
  if (code == 'BEVERAGE' ||
      name.contains('uống') ||
      name.contains('beverage') ||
      name.contains('cà phê') ||
      name.contains('trà') ||
      name.contains('nước ngọt') ||
      name.contains('rượu') ||
      name.contains('bia')) {
    return 'assets/images/categories/berverage.jpg';
  }

  // 2. DAIRY
  if (code == 'DAIRY' ||
      name.contains('sữa') ||
      name.contains('dairy') ||
      name.contains('phô mai') ||
      name.contains('bơ') ||
      name.contains('yogurt') ||
      name.contains('sữa chua')) {
    return 'assets/images/categories/dairy.jpg';
  }

  // 3. DESSERT
  if (code == 'DESSERT' ||
      name.contains('tráng miệng') ||
      name.contains('bánh') ||
      name.contains('dessert') ||
      name.contains('kẹo') ||
      name.contains('kem') ||
      name.contains('chè')) {
    return 'assets/images/categories/cake.jpg';
  }

  // 4. DRY_DISH / GRAIN / RICE
  if (code == 'DRY_DISH' ||
      name.contains('món khô') ||
      name.contains('cơm') ||
      name.contains('xôi') ||
      name.contains('chiên')) {
    return 'assets/images/categories/rice.jpg';
  }

  if (code == 'GRAIN' ||
      name.contains('ngũ cốc') ||
      name.contains('tinh bột') ||
      name.contains('grain') ||
      name.contains('yến mạch') ||
      name.contains('mì mì') ||
      name.contains('pasta')) {
    return 'assets/images/categories/pasta.jpg';
  }

  // 5. FAST_FOOD
  if (code == 'FAST_FOOD' ||
      name.contains('nhanh') ||
      name.contains('fast food') ||
      name.contains('burger') ||
      name.contains('pizza') ||
      name.contains('khoai tây chiên')) {
    return 'assets/images/categories/fast_food.jpg';
  }

  // 6. FRUIT
  if (code == 'FRUIT' ||
      name.contains('trái cây') ||
      name.contains('hoa quả') ||
      name.contains('fruit') ||
      name.contains('quả')) {
    return 'assets/images/categories/fruit.jpg';
  }

  // 7. MEAT
  if (code == 'MEAT' ||
      name.contains('thịt') ||
      name.contains('meat') ||
      name.contains('gà') ||
      name.contains('bò') ||
      name.contains('heo') ||
      name.contains('vịt') ||
      name.contains('pork') ||
      name.contains('beef') ||
      name.contains('chicken')) {
    return 'assets/images/categories/meat.jpg';
  }

  // 8. NOODLE_SOUP
  if (code == 'NOODLE_SOUP' ||
      name.contains('nước') ||
      name.contains('bún') ||
      name.contains('phở') ||
      name.contains('mì') ||
      name.contains('hủ tiếu') ||
      name.contains('súp') ||
      name.contains('cháo') ||
      name.contains('noodle')) {
    return 'assets/images/categories/noodle_soup.jpg';
  }

  // 9. SEAFOOD
  if (code == 'SEAFOOD' ||
      name.contains('hải sản') ||
      name.contains('cá') ||
      name.contains('tôm') ||
      name.contains('muc') ||
      name.contains('mực') ||
      name.contains('cua') ||
      name.contains('seafood') ||
      name.contains('fish')) {
    return 'assets/images/categories/hai_san.jpg';
  }

  // 10. SEASONING & OILS
  if (code == 'SEASONING' ||
      code == 'OILS' ||
      name.contains('gia vị') ||
      name.contains('dầu') ||
      name.contains('seasoning') ||
      name.contains('sốt') ||
      name.contains('sauce')) {
    return 'assets/images/categories/seasoning.jpg';
  }

  // 11. VEG
  if (code == 'VEG' ||
      name.contains('rau') ||
      name.contains('củ') ||
      name.contains('veg') ||
      name.contains('nấm')) {
    return 'assets/images/categories/veg1.jpg';
  }

  // Default fallback
  return 'assets/images/categories/fast_food.jpg';
}

/// Returns an [ImageProvider] for a food item given its [imageUrl], [categoryCode], and optional [categoryName].
ImageProvider getFoodImageProvider(String? imageUrl, String? categoryCode, [String? categoryName]) {
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    return NetworkImage(imageUrl.trim());
  }
  return AssetImage(getCategoryAssetPath(categoryCode, categoryName));
}

/// A reusable Flutter Widget for rendering food images with category fallback and error handling.
class CategoryFoodImage extends StatelessWidget {
  final String? imageUrl;
  final String? categoryCode;
  final String? categoryName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CategoryFoodImage({
    super.key,
    required this.imageUrl,
    this.categoryCode,
    this.categoryName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = getCategoryAssetPath(categoryCode, categoryName);

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
