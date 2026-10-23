import 'package:flutter/material.dart';

/// Widget texte sécurisé qui ne déborde JAMAIS
/// - Limite à 2 lignes par défaut
/// - Ellipsis automatique
/// - Taille adaptative avec FittedBox
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final bool fit;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.fit = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: true,
    );

    if (fit) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
