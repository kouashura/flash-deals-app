#!/bin/bash
echo "🧹 Nettoyage des warnings..."
echo ""

echo "→ Suppression des imports 'go_router' inutilisés..."
find lib -name "*.dart" -exec grep -l "import 'package:go_router/go_router.dart';" {} \; | while read file; do
  if ! grep -qE "context\.(push|go|pop)|GoRouter|GoRoute|state\.uri" "$file"; then
    sed -i '' "/^import 'package:go_router\/go_router.dart';$/d" "$file"
    echo "  ✅ $file"
  fi
done

echo "→ Suppression des imports 'flutter_bloc' inutilisés..."
find lib -name "*.dart" -exec grep -l "import 'package:flutter_bloc/flutter_bloc.dart';" {} \; | while read file; do
  if ! grep -qE "BlocBuilder|BlocProvider|BlocConsumer|BlocListener|Bloc|Cubit" "$file"; then
    sed -i '' "/^import 'package:flutter_bloc\/flutter_bloc.dart';$/d" "$file"
    echo "  ✅ $file"
  fi
done

echo "→ Suppression des imports 'cloud_firestore' inutilisés..."
find lib -name "*.dart" -exec grep -l "import 'package:cloud_firestore/cloud_firestore.dart';" {} \; | while read file; do
  if ! grep -qE "FirebaseFirestore|Timestamp|FieldValue|DocumentSnapshot|QuerySnapshot" "$file"; then
    sed -i '' "/^import 'package:cloud_firestore\/cloud_firestore.dart';$/d" "$file"
    echo "  ✅ $file"
  fi
done

echo ""
echo "🧹 Nettoyage terminé !"
