import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/flash_deals_service.dart';
import 'countdown_timer.dart';

class FlashDealsBanner extends StatelessWidget {
  const FlashDealsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FlashDealsService();

    return StreamBuilder<FlashDealsConfig>(
      stream: service.streamConfig(),
      builder: (context, snapshot) {
        // Valeurs par défaut pendant le chargement
        final config = snapshot.data ?? FlashDealsConfig.defaultConfig();

        // Bannière désactivée
        if (!config.isActive) return const SizedBox.shrink();

        // Compte à rebours terminé
        if (config.endTime.isBefore(DateTime.now())) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF9800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CountdownTimer(endTime: config.endTime),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
