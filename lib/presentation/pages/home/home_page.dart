import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import '../../widgets/skeletons/product_grid_skeleton.dart';
import '../../widgets/empty_states/empty_state.dart';
import 'widgets/category_chips.dart';
import 'widgets/flash_deals_banner.dart';
import 'widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirestoreService();
  late Stream<List<ProductModel>> _productsStream;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _productsStream = _firestore.streamProducts();
  }

  Future<void> _refresh() async {
    setState(() => _productsStream = _firestore.streamProducts());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// 2 colonnes sur téléphone, plus sur tablette / grand écran.
  int _columnsFor(double width) {
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: 120,
          child: StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              final isLoading = !snapshot.hasData && !snapshot.hasError;
              final allProducts = snapshot.data ?? const <ProductModel>[];
              final products = _selectedCategory == 'all'
                  ? allProducts
                  : allProducts
                      .where((p) => p.categoryId == _selectedCategory)
                      .toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: FlashDealsBanner(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Catégories'),
                  ),
                  SliverToBoxAdapter(
                    child: CategoryChips(
                      onSelected: (catId) =>
                          setState(() => _selectedCategory = catId),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Deals du moment',
                      leading: const _TitleIcon(
                        icon: Icons.local_fire_department_rounded,
                      ),
                      trailing: (isLoading || snapshot.hasError)
                          ? null
                          : _CountLabel(count: products.length),
                    ),
                  ),
                  if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(onRetry: _refresh),
                    )
                  else if (isLoading)
                    const SliverToBoxAdapter(
                      child: ProductGridSkeleton(count: 6),
                    )
                  else if (products.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aucun produit',
                        subtitle:
                            'Cette catégorie ne contient aucun produit pour le moment.\nEssayez une autre catégorie.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columnsFor(width),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ProductCard(
                            product: products[i],
                            onTap: () =>
                                context.push('/product/${products[i].id}'),
                          ),
                          childCount: products.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.12),
      elevation: 0,
      scrolledUnderElevation: 1.5,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 16,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 40, maxHeight: 30),
              child: Image.asset(
                'assets/images/logo/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Flash Deals',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) => _AppBarAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            count: state.unreadCount,
            onPressed: () => context.push('/notifications'),
          ),
        ),
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) => _AppBarAction(
            icon: Icons.shopping_bag_outlined,
            tooltip: 'Panier',
            count: state.cart.totalItems,
            onPressed: () => context.push('/cart'),
          ),
        ),
        _AppBarAction(
          icon: Icons.person_outline_rounded,
          tooltip: 'Profil',
          onPressed: () => context.push('/profile'),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _SearchField(onTap: () => context.push('/search')),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade600;

    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: muted, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rechercher un produit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 14.5),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFFD1D5DB),
              ),
              const SizedBox(width: 12),
              Icon(Icons.tune_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 24),
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          padding: EdgeInsets.zero,
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 5,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TitleIcon extends StatelessWidget {
  const _TitleIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count produit${count > 1 ? "s" : ""}',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Impossible de charger les produits',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Vérifiez votre connexion internet, puis réessayez.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Réessayer'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}