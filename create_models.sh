#!/bin/bash
echo "📝 Création des modèles..."

# ============================================================
# PRODUCT MODEL
# ============================================================
cat > lib/data/models/product_model.dart << 'DART'
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
      };
}
DART

# ============================================================
# CATEGORY MODEL
# ============================================================
cat > lib/data/models/category_model.dart << 'DART'
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconUrl': iconUrl,
      };
}
DART

# ============================================================
# STORE MODEL
# ============================================================
cat > lib/data/models/store_model.dart << 'DART'
import '../../domain/entities/store.dart';

class StoreModel extends Store {
  const StoreModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.rating,
    super.isOpen,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'isOpen': isOpen,
      };
}
DART

# ============================================================
# USER MODEL
# ============================================================
cat > lib/data/models/user_model.dart << 'DART'
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
    super.avatarUrl,
    super.loyaltyPoints,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'loyaltyPoints': loyaltyPoints,
      };
}
DART

# ============================================================
# CART ITEM MODEL
# ============================================================
cat > lib/data/models/cart_item_model.dart << 'DART'
import '../../domain/entities/cart_item.dart';
import 'product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.product,
    required super.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': (product as ProductModel).toJson(),
        'quantity': quantity,
      };
}
DART

# ============================================================
# CART MODEL
# ============================================================
cat > lib/data/models/cart_model.dart << 'DART'
import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends Cart {
  const CartModel({required super.items});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      items: itemsJson
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items
            .map((e) => (e as CartItemModel).toJson())
            .toList(),
      };
}
DART

# ============================================================
# ADDRESS MODEL
# ============================================================
cat > lib/data/models/address_model.dart << 'DART'
import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.label,
    required super.fullAddress,
    required super.zone,
    required super.latitude,
    required super.longitude,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      zone: json['zone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fullAddress': fullAddress,
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
DART

# ============================================================
# DELIVERY MODEL
# ============================================================
cat > lib/data/models/delivery_model.dart << 'DART'
import '../../domain/entities/delivery.dart';
import '../../core/constants/delivery_constants.dart';

class DeliveryModel extends Delivery {
  const DeliveryModel({
    required super.id,
    required super.addressId,
    required super.zone,
    required super.latitude,
    required super.longitude,
    required super.fee,
    required super.timeSlot,
    required super.status,
    super.trackingCode,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      addressId: json['addressId'] as String,
      zone: json['zone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fee: json['fee'] as int? ?? DeliveryConstants.abidjanDeliveryFee,
      timeSlot: json['timeSlot'] as String,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      trackingCode: json['trackingCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'addressId': addressId,
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'fee': fee,
        'timeSlot': timeSlot,
        'status': status.name,
        'trackingCode': trackingCode,
      };
}
DART

# ============================================================
# ORDER ITEM MODEL
# ============================================================
cat > lib/data/models/order_item_model.dart << 'DART'
import '../../domain/entities/order_item.dart';
import 'product_model.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.product,
    required super.quantity,
    required super.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product': (product as ProductModel).toJson(),
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
DART

# ============================================================
# ORDER MODEL
# ============================================================
cat > lib/data/models/order_model.dart << 'DART'
import '../../domain/entities/order.dart';
import 'order_item_model.dart';
import 'delivery_model.dart';
import 'payment_model.dart';
import 'address_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.address,
    required super.delivery,
    required super.payment,
    required super.subtotal,
    required super.total,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: itemsJson
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      delivery: DeliveryModel.fromJson(json['delivery'] as Map<String, dynamic>),
      payment: PaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
        'address': (address as AddressModel).toJson(),
        'delivery': (delivery as DeliveryModel).toJson(),
        'payment': (payment as PaymentModel).toJson(),
        'subtotal': subtotal,
        'total': total,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
DART

# ============================================================
# PAYMENT MODEL
# ============================================================
cat > lib/data/models/payment_model.dart << 'DART'
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.method,
    required super.amount,
    required super.status,
    super.transactionId,
    super.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.orangeMoney,
      ),
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transactionId'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method.name,
        'amount': amount,
        'status': status.name,
        'transactionId': transactionId,
        'paidAt': paidAt?.toIso8601String(),
      };
}
DART

# ============================================================
# REVIEW MODEL
# ============================================================
cat > lib/data/models/review_model.dart << 'DART'
import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.productId,
    required super.userId,
    required super.userName,
    required super.rating,
    required super.comment,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}
DART

# ============================================================
# NOTIFICATION MODEL
# ============================================================
cat > lib/data/models/notification_model.dart << 'DART'
import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.createdAt,
    super.isRead,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'general',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };
}
DART

echo "✅ Tous les modèles ont été créés !"
