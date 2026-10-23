#!/bin/bash
echo "🧹 Nettoyage des warnings..."
echo ""

# 1. Supprimer les imports inutilisés courants
echo "→ Nettoyage des imports inutilisés..."

# Liste des imports à vérifier
for import_line in \
  "import 'package:go_router/go_router.dart';" \
  "import 'package:flutter_bloc/flutter_bloc.dart';" \
  "import 'package:cloud_firestore/cloud_firestore.dart';" \
  "import 'package:firebase_auth/firebase_auth.dart';" \
  "import 'dart:async';" \
  "import 'dart:io';" \
  "import 'dart:convert';"; do

  find lib -name "*.dart" | while read file; do
    if grep -qF "$import_line" "$file"; then
      # Extraire le nom du package pour vérifier l'usage
      pkg=$(echo "$import_line" | sed "s/import '//" | sed "s/';//")
      
      # Compter les occurrences du package dans le fichier
      count=$(grep -cF "$import_line" "$file")
      
      if [ "$count" -ge 1 ]; then
        # Vérifier si le package est utilisé ailleurs que dans l'import
        body=$(grep -vF "$import_line" "$file")
        
        case "$pkg" in
          "package:go_router/go_router.dart")
            if ! echo "$body" | grep -qE "context\.(push|go|pop|replace)|GoRouter|GoRoute"; then
              sed -i '' "/^${import_line}$/d" "$file" 2>/dev/null || \
              sed -i "/^${import_line}$/d" "$file"
              echo "  ✅ $file (go_router)"
            fi
            ;;
          "package:flutter_bloc/flutter_bloc.dart")
            if ! echo "$body" | grep -qE "BlocBuilder|BlocProvider|BlocConsumer|BlocListener|Bloc<|Cubit<|BlocProvider\.of"; then
              sed -i '' "/^${import_line}$/d" "$file" 2>/dev/null || \
              sed -i "/^${import_line}$/d" "$file"
              echo "  ✅ $file (flutter_bloc)"
            fi
            ;;
          "package:cloud_firestore/cloud_firestore.dart")
            if ! echo "$body" | grep -qE "FirebaseFirestore|Timestamp|FieldValue|DocumentSnapshot|QuerySnapshot"; then
              sed -i '' "/^${import_line}$/d" "$file" 2>/dev/null || \
              sed -i "/^${import_line}$/d" "$file"
              echo "  ✅ $file (cloud_firestore)"
            fi
            ;;
          "package:firebase_auth/firebase_auth.dart")
            if ! echo "$body" | grep -qE "FirebaseAuth|User\."; then
              sed -i '' "/^${import_line}$/d" "$file" 2>/dev/null || \
              sed -i "/^${import_line}$/d" "$file"
              echo "  ✅ $file (firebase_auth)"
            fi
            ;;
        esac
      fi
    fi
  done
done

echo ""
echo "→ Nettoyage des doublons d'imports..."

# Supprimer les imports dupliqués
find lib -name "*.dart" | while read file; do
  # Trouver les imports dupliqués
  duplicates=$(grep "^import " "$file" | sort | uniq -d)
  
  if [ -n "$duplicates" ]; then
    # Pour chaque doublon, ne garder que la 1ère occurrence
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        # Compter le nombre d'occurrences
        count=$(grep -cF "$line" "$file")
        if [ "$count" -gt 1 ]; then
          # Supprimer la dernière occurrence (garder la 1ère)
          awk -v line="$line" '
            $0 == line {
              if (found) { next }
              found = 1
            }
            { print }
          ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
          echo "  ✅ $file (doublon: $line)"
        fi
      fi
    done <<< "$duplicates"
  fi
done

echo ""
echo "🧹 Nettoyage terminé !"
