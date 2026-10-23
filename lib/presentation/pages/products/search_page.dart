import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../core/utils/formatters.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<ProductModel> get _allProducts => [
        ProductModel(
          id: '1', name: 'Lait Candia 1L', description: '',
          imageUrl: '', categoryId: '1', storeId: 's1',
          storeName: 'Carrefour Cocody',
          normalPrice: 1200, promoPrice: 600, stock: 3,
          expiryDate: DateTime.now().add(const Duration(days: 3)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '2', name: 'Yaourt Activia x4', description: '',
          imageUrl: '', categoryId: '1', storeId: 's2',
          storeName: 'Prosuma Plateau',
          normalPrice: 2500, promoPrice: 1500, stock: 8,
          expiryDate: DateTime.now().add(const Duration(days: 5)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '3', name: 'Steak haché 500g', description: '',
          imageUrl: '', categoryId: '2', storeId: 's1',
          storeName: 'Carrefour Cocody',
          normalPrice: 3500, promoPrice: 2000, stock: 2,
          expiryDate: DateTime.now().add(const Duration(days: 1)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '4', name: 'Pain complet', description: '',
          imageUrl: '', categoryId: '3', storeId: 's3',
          storeName: 'Sococié Marcory',
          normalPrice: 800, promoPrice: 400, stock: 15,
          expiryDate: DateTime.now().add(const Duration(days: 2)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '5', name: 'Jus d\'orange 1L', description: '',
          imageUrl: '', categoryId: '4', storeId: 's2',
          storeName: 'Prosuma Plateau',
          normalPrice: 1800, promoPrice: 1000, stock: 10,
          expiryDate: DateTime.now().add(const Duration(days: 6)),
          isFlashDeal: true,
        ),
      ];

  List<ProductModel> get _filtered {
    if (_query.isEmpty) return [];
    return _allProducts
        .where((p) =>
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.storeName.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Rechercher un produit...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Recherchez un produit ou un magasin',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : results.isEmpty
              ? const Center(child: Text('Aucun résultat'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final p = results[i];
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.push('/product/${p.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(p.storeName,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(Formatters.price(p.promoPrice),
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
