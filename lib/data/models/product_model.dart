import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.categoryId,
    required super.storeId,
    required super.storeName,
    required super.normalPrice,
    required super.promoPrice,
    required super.stock,
    required super.expiryDate,
    required super.isFlashDeal,
    super.rating,
    super.reviewCount,
    super.weightKg,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String? ?? '',
      normalPrice: (json['normalPrice'] as num).toDouble(),
      promoPrice: (json['promoPrice'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      isFlashDeal: json['isFlashDeal'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'storeId': storeId,
        'storeName': storeName,
        'normalPrice': normalPrice,
        'promoPrice': promoPrice,
        'stock': stock,
        'expiryDate': expiryDate.toIso8601String(),
        'isFlashDeal': isFlashDeal,
        'rating': rating,
        'reviewCount': reviewCount,
        'weightKg': weightKg,
      };
}
