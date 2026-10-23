import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String categoryId;
  final String storeId;
  final String storeName;
  final double normalPrice;
  final double promoPrice;
  final int stock;
  final DateTime expiryDate;
  final bool isFlashDeal;
  final double rating;
  final int reviewCount;
  /// Poids unitaire en kilogrammes (pour le calcul de livraison)
  final double weightKg;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.storeId,
    required this.storeName,
    required this.normalPrice,
    required this.promoPrice,
    required this.stock,
    required this.expiryDate,
    required this.isFlashDeal,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.weightKg = 1.0,
  });

  double get discountPercent {
    if (normalPrice <= 0) return 0;
    return ((normalPrice - promoPrice) / normalPrice) * 100;
  }

  double get savings => normalPrice - promoPrice;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String? get expiryBadge {
    final d = daysUntilExpiry;
    if (d < 0) return 'Expiré';
    if (d == 0) return "Aujourd'hui";
    if (d <= 1) return 'J-1';
    if (d <= 3) return 'J-3';
    if (d <= 7) return 'J-7';
    return null;
  }

  bool get isExpiringSoon => daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isAvailable => stock > 0 && daysUntilExpiry >= 0;

  @override
  List<Object?> get props => [id, name, promoPrice, stock, expiryDate, isFlashDeal];
}
