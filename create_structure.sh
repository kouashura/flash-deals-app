#!/bin/bash
echo "📁 Création de l'arborescence..."

mkdir -p assets/images/logo assets/images/banners assets/images/placeholders assets/images/icons assets/images/categories assets/images/stores
mkdir -p assets/fonts assets/animations/lottie

mkdir -p lib/core/config lib/core/constants lib/core/errors lib/core/network lib/core/services lib/core/theme lib/core/utils lib/core/di lib/core/l10n lib/core/mixins

mkdir -p lib/data/models lib/data/datasources/remote lib/data/datasources/local lib/data/repositories

mkdir -p lib/domain/entities lib/domain/repositories
mkdir -p lib/domain/usecases/auth lib/domain/usecases/product lib/domain/usecases/cart lib/domain/usecases/order lib/domain/usecases/delivery lib/domain/usecases/payment lib/domain/usecases/store lib/domain/usecases/user

mkdir -p lib/presentation/blocs/auth lib/presentation/blocs/product lib/presentation/blocs/cart lib/presentation/blocs/order lib/presentation/blocs/delivery lib/presentation/blocs/payment lib/presentation/blocs/favorites lib/presentation/blocs/notification lib/presentation/blocs/store lib/presentation/blocs/profile

mkdir -p lib/presentation/pages/splash lib/presentation/pages/onboarding lib/presentation/pages/auth
mkdir -p lib/presentation/pages/home/widgets lib/presentation/pages/categories
mkdir -p lib/presentation/pages/products/widgets lib/presentation/pages/stores/widgets
mkdir -p lib/presentation/pages/cart/widgets lib/presentation/pages/checkout/widgets
mkdir -p lib/presentation/pages/delivery/widgets lib/presentation/pages/payment/widgets
mkdir -p lib/presentation/pages/orders/widgets lib/presentation/pages/favorites
mkdir -p lib/presentation/pages/notifications lib/presentation/pages/profile
mkdir -p lib/presentation/pages/reviews lib/presentation/pages/legal

mkdir -p lib/presentation/widgets/common lib/presentation/widgets/cards lib/presentation/widgets/inputs lib/presentation/widgets/navigation lib/presentation/widgets/badges

mkdir -p lib/routes

mkdir -p test/unit/blocs test/unit/usecases test/unit/repositories test/unit/utils
mkdir -p test/widget/pages test/widget/widgets test/integration test/helpers

touch .env .env.example

echo "✅ Arborescence créée avec succès !"
