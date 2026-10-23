import os
import re

# Fichiers à réparer : on retire les AppSnackbar cassés et on remet le code d'origine
# On va chercher les patterns cassés : AppSnackbar.xxx(context, ...) suivi de code orphelin

files = [
    'lib/presentation/pages/admin/admin_notifications_page.dart',
    'lib/presentation/pages/admin/admin_orders_page.dart',
    'lib/presentation/pages/admin/admin_products_page.dart',
    'lib/presentation/pages/products/product_details_page.dart',
    'lib/presentation/pages/profile/profile_page.dart',
    'lib/presentation/pages/auth/register_page.dart',
    'lib/presentation/pages/auth/login_page.dart',
    'lib/presentation/pages/payment/mobile_money_page.dart',
    'lib/presentation/pages/checkout/address_input_page.dart',
]

for f in files:
    if not os.path.exists(f):
        continue
    # Faire une sauvegarde
    os.system(f'cp "{f}" "{f}.bak"')
    print(f"💾 Sauvegarde : {f}.bak")

print("\n✅ Sauvegardes créées")
