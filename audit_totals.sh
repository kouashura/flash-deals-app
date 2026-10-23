#!/bin/bash
echo "═══════════════════════════════════════════════════"
echo "🔍 AUDIT DES CALCULS DE TOTAUX"
echo "═══════════════════════════════════════════════════"
echo ""

FILES=(
  "lib/domain/entities/cart.dart"
  "lib/domain/entities/cart_item.dart"
  "lib/presentation/blocs/cart/cart_bloc.dart"
  "lib/presentation/pages/cart/cart_page.dart"
  "lib/presentation/pages/cart/widgets/cart_item_tile.dart"
  "lib/presentation/pages/checkout/checkout_page.dart"
  "lib/presentation/pages/payment/paiement_pro_page.dart"
  "lib/presentation/pages/payment/mobile_money_page.dart"
  "lib/presentation/pages/payment/payment_methods_page.dart"
  "lib/core/constants/delivery_constants.dart"
  "lib/core/services/delivery_pricing_service.dart"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "─────────────────────────────────────────────────"
    echo "📄 $file"
    echo "─────────────────────────────────────────────────"
    grep -nE "subtotal|total|deliveryFee|800|1000|1500|abidjanDeliveryFee|currentFee|pickupFee" "$file" | head -15
    echo ""
  else
    echo "❌ MANQUANT : $file"
    echo ""
  fi
done

echo "═══════════════════════════════════════════════════"
echo "✅ FIN DE L'AUDIT"
echo "═══════════════════════════════════════════════════"
