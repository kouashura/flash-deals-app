import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';

class ProductService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      if (data['expiryDate'] is Timestamp) {
        data['expiryDate'] =
            (data['expiryDate'] as Timestamp).toDate().toIso8601String();
      }
      return ProductModel.fromJson(data);
    }).toList();
  }
}
