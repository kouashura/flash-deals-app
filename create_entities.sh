#!/bin/bash
echo "📝 Création des entités domaine..."

# ============================================================
# PRODUCT ENTITY
# ============================================================
cat > lib/domain/entities/product.dart << 'DART'
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
  });

  /// Pourcentage de réduction
  double get discountPercent {
    if (normalPrice <= 0) return 0;
    return ((normalPrice - promoPrice) / normalPrice) * 100;
  }

  /// Économie en FCFA
  double get savings => normalPrice - promoPrice;

  /// Nombre de jours avant péremption
  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  /// Badge d'expiration : "J-1", "J-3", "J-7" ou null
  String? get expiryBadge {
    final d = daysUntilExpiry;
    if (d < 0) return 'Expiré';
    if (d == 0) return "Aujourd'hui";
    if (d <= 1) return 'J-1';
    if (d <= 3) return 'J-3';
    if (d <= 7) return 'J-7';
    return null;
  }

  /// Produit bientôt périmé (≤ 7 jours)
  bool get isExpiringSoon => daysUntilExpiry <= 7 && daysUntilExpiry >= 0;

  /// Stock faible (≤ 5)
  bool get isLowStock => stock > 0 && stock <= 5;

  /// Disponible
  bool get isAvailable => stock > 0 && daysUntilExpiry >= 0;

  @override
  List<Object?> get props => [
        id,
        name,
        promoPrice,
        stock,
        expiryDate,
        isFlashDeal,
      ];
}
DART

# ============================================================
# CATEGORY ENTITY
# ============================================================
cat > lib/domain/entities/category.dart << 'DART'
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String iconUrl;

  const Category({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, iconUrl];
}
DART

# ============================================================
# STORE ENTITY
# ============================================================
cat > lib/domain/entities/store.dart << 'DART'
import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isOpen;

  const Store({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.isOpen = true,
  });

  @override
  List<Object?> get props => [id, name, address, latitude, longitude];
}
DART

# ============================================================
# USER ENTITY
# ============================================================
cat > lib/domain/entities/user.dart << 'DART'
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? avatarUrl;
  final int loyaltyPoints;

  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.loyaltyPoints = 0,
  });

  @override
  List<Object?> get props => [id, fullName, phone, email];
}
DART

# ============================================================
# CART ITEM ENTITY
# ============================================================
cat > lib/domain/entities/cart_item.dart << 'DART'
import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.promoPrice * quantity;
  double get lineTotalNormal => product.normalPrice * quantity;
  double get lineSavings => lineTotalNormal - lineTotal;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  @override
  List<Object?> get props => [product, quantity];
}
DART

# ============================================================
# CART ENTITY
# ============================================================
cat > lib/domain/entities/cart.dart << 'DART'
import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Cart extends Equatable {
  final List<CartItem> items;

  const Cart({this.items = const []});

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get totalSavings =>
      items.fold(0.0, (sum, item) => sum + item.lineSavings);

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({List<CartItem>? items}) =>
      Cart(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
DART

# ============================================================
# ADDRESS ENTITY
# ============================================================
cat > lib/domain/entities/address.dart << 'DART'
import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String fullAddress;
  final String zone;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.zone,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  @override
  List<Object?> get props =>
      [id, label, fullAddress, zone, latitude, longitude];
}
DART

# ============================================================
# DELIVERY ENTITY
# ============================================================
cat > lib/domain/entities/delivery.dart << 'DART'
import 'package:equatable/equatable.dart';

enum DeliveryStatus {
  pending,      // En attente
  confirmed,    // Confirmée
  preparing,    // En préparation (magasin)
  onTheWay,     // En cours de livraison
  delivered,    // Livré
  cancelled,    // Annulée
}

extension DeliveryStatusX on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.confirmed:
        return 'Confirmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.onTheWay:
        return 'En cours de livraison';
      case DeliveryStatus.delivered:
        return 'Livré';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }
}

class Delivery extends Equatable {
  final String id;
  final String addressId;
  final String zone;
  final double latitude;
  final double longitude;
  final int fee;              // en FCFA (fixe = 1500 pour Abidjan)
  final String timeSlot;
  final DeliveryStatus status;
  final String? trackingCode;

  const Delivery({
    required this.id,
    required this.addressId,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.fee,
    required this.timeSlot,
    this.status = DeliveryStatus.pending,
    this.trackingCode,
  });

  @override
  List<Object?> get props => [id, zone, fee, status];
}
DART

# ============================================================
# ORDER ITEM ENTITY
# ============================================================
cat > lib/domain/entities/order_item.dart << 'DART'
import 'package:equatable/equatable.dart';
import 'product.dart';

class OrderItem extends Equatable {
  final Product product;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [product, quantity, unitPrice];
}
DART

# ============================================================
# ORDER ENTITY
# ============================================================
cat > lib/domain/entities/order.dart << 'DART'
import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'delivery.dart';
import 'payment.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.onTheWay:
        return 'En route';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final Address address;
  final Delivery delivery;
  final Payment payment;
  final double subtotal;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.address,
    required this.delivery,
    required this.payment,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [id, status, total, createdAt];
}
DART

# ============================================================
# PAYMENT ENTITY
# ============================================================
cat > lib/domain/entities/payment.dart << 'DART'
import 'package:equatable/equatable.dart';

enum PaymentMethod {
  orangeMoney,
  mtnMomo,
  moovMoney,
  wave,
  card,
  wallet,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN Mobile Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.wallet:
        return 'Wallet Flash Deals';
    }
  }
}

enum PaymentStatus { pending, processing, success, failed, refunded }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En cours';
      case PaymentStatus.success:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
    }
  }
}

class Payment extends Equatable {
  final String id;
  final PaymentMethod method;
  final double amount;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  @override
  List<Object?> get props => [id, method, amount, status];
}
DART

# ============================================================
# REVIEW ENTITY
# ============================================================
cat > lib/domain/entities/review.dart << 'DART'
import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, productId, rating, createdAt];
}
DART

# ============================================================
# NOTIFICATION ENTITY
# ============================================================
cat > lib/domain/entities/notification.dart << 'DART'
import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;             // 'deal', 'order', 'promo', 'general'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  @override
  List<Object?> get props => [id, title, type, isRead, createdAt];
}
DART

echo "✅ Toutes les entités ont été créées !"
