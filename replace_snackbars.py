import os
import re

files = [
    'lib/presentation/pages/products/product_details_page.dart',
    'lib/presentation/pages/auth/register_page.dart',
    'lib/presentation/pages/auth/login_page.dart',
    'lib/presentation/pages/payment/mobile_money_page.dart',
    'lib/presentation/pages/admin/admin_orders_page.dart',
    'lib/presentation/pages/admin/test_upload_page.dart',
    'lib/presentation/pages/admin/admin_products_page.dart',
    'lib/presentation/pages/admin/admin_notifications_page.dart',
    'lib/presentation/pages/checkout/address_input_page.dart',
    'lib/presentation/pages/profile/profile_page.dart',
]

def detect_type(message):
    msg = message.lower()
    if any(w in msg for w in ['ajouté', 'succès', 'mis à jour', 'bienvenue', 'envoyée', 'confirmée', 'validée', 'réussie', 'sauvegardé']):
        return 'success'
    if any(w in msg for w in ['erreur', 'échec', 'invalide', 'impossible', 'incorrect', 'échoué', 'introuvable']):
        return 'error'
    if any(w in msg for w in ['connectez', 'attention', 'vérifiez', 'remplissez', 'remplir']):
        return 'warning'
    return 'info'

def get_import_path(filepath):
    if 'presentation/pages/' in filepath:
        depth = filepath.split('presentation/pages/')[1].count('/')
        prefix = '../' * (depth + 1)
        return f"{prefix}widgets/snackbars/app_snackbar.dart"
    return '../../widgets/snackbars/app_snackbar.dart'

pattern = re.compile(
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*"
    r"(?:const\s+)?SnackBar\("
    r"[\s\S]{0,500}?"
    r"Text\(\s*"
    r"(['\"])((?:[^'\"\\]|\\.)+)\1"
    r"[\s\S]{0,500}?"
    r"\)\s*,?\s*\)\s*,?\s*\)",
    re.MULTILINE
)

total_replaced = 0

for filepath in files:
    if not os.path.exists(filepath):
        continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    counter = {'n': 0}  # ← utilisation d'un dict pour contourner la closure
    
    def make_replacer(counter_ref):
        def replacer(match):
            quote = match.group(1)
            message = match.group(2)
            snack_type = detect_type(message)
            counter_ref['n'] += 1
            
            safe_message = message.replace("\\'", "'").replace('\\"', '"')
            if "'" in safe_message:
                return f"AppSnackbar.{snack_type}(context, \"{safe_message}\")"
            return f"AppSnackbar.{snack_type}(context, '{safe_message}')"
        return replacer
    
    new_content = pattern.sub(make_replacer(counter), content)
    
    if new_content != original:
        if 'app_snackbar.dart' not in new_content:
            import_path = get_import_path(filepath)
            lines = new_content.split('\n')
            last_import_idx = 0
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import_idx = i
            lines.insert(last_import_idx + 1, f"import '{import_path}';")
            new_content = '\n'.join(lines)
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        total_replaced += counter['n']
        print(f"✅ {filepath} ({counter['n']} remplacements)")

print(f"\n🎉 Total : {total_replaced} snackbars remplacés")
