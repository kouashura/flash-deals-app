import 'package:flutter/material.dart';
import 'admin_section.dart';

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: adminBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;

              // Padding adaptatif
              final pad = (h * 0.10).clamp(6.0, 12.0);

              // Icône : plus petite pour libérer de la place
              final iconBox = (h * 0.28).clamp(20.0, 32.0);
              final iconSize = iconBox * 0.55;

              // Texte
              final valueSize = (h * 0.24).clamp(15.0, 22.0);
              final labelSize = (h * 0.13).clamp(9.0, 11.5);

              return Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === ICÔNE ===
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: iconSize),
                    ),

                    // === VALEUR + LABEL (prend l'espace restant) ===
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: valueSize,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                color: adminInk,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: labelSize,
                              color: adminMuted,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
