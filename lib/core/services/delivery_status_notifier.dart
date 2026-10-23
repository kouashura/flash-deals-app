import 'dart:async';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/notification.dart';

/// Événement de mise à jour de statut de livraison
class DeliveryStatusUpdate {
  final String orderId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String message;
  final Duration? eta;

  DeliveryStatusUpdate({
    required this.orderId,
    required this.status,
    required this.timestamp,
    required this.message,
    this.eta,
  });
}

/// Service qui simule la progression de la livraison
/// et émet des événements de mise à jour
class DeliveryStatusNotifier {
  static final DeliveryStatusNotifier _instance =
      DeliveryStatusNotifier._internal();
  factory DeliveryStatusNotifier() => _instance;
  DeliveryStatusNotifier._internal();

  final _controller = StreamController<DeliveryStatusUpdate>.broadcast();
  Stream<DeliveryStatusUpdate> get stream => _controller.stream;

  Timer? _timer;
  int _stepIndex = 0;

  /// Démarre une livraison simulée
  /// Chaque étape arrive après `stepDuration` secondes
  void startDelivery({
    required String orderId,
    Duration stepDuration = const Duration(seconds: 15),
  }) {
    _stepIndex = 0;
    _timer?.cancel();

    // Étape 1 : Confirmation immédiate
    _emit(
      orderId: orderId,
      status: DeliveryStatus.confirmed,
      message: 'Votre commande a été confirmée ✅',
      eta: const Duration(minutes: 45),
    );

    // Étapes suivantes toutes les X secondes
    _timer = Timer.periodic(stepDuration, (timer) {
      _stepIndex++;

      switch (_stepIndex) {
        case 1:
          _emit(
            orderId: orderId,
            status: DeliveryStatus.preparing,
            message:
                'Votre commande est en préparation dans notre entrepôt 📦',
            eta: const Duration(minutes: 40),
          );
          break;
        case 2:
          _emit(
            orderId: orderId,
            status: DeliveryStatus.onTheWay,
            message:
                'Votre colis est en route vers vous ! 🚚',
            eta: const Duration(minutes: 20),
          );
          break;
        case 3:
          _emit(
            orderId: orderId,
            status: DeliveryStatus.delivered,
            message:
                'Votre colis a été livré. Merci ! 🎉',
          );
          timer.cancel();
          break;
      }
    });
  }

  void _emit({
    required String orderId,
    required DeliveryStatus status,
    required String message,
    Duration? eta,
  }) {
    _controller.add(DeliveryStatusUpdate(
      orderId: orderId,
      status: status,
      timestamp: DateTime.now(),
      message: message,
      eta: eta,
    ));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Convertit un DeliveryStatus en AppNotification
extension DeliveryStatusToNotification on DeliveryStatusUpdate {
  AppNotification toNotification() {
    return AppNotification(
      id: 'delivery_${orderId}_${status.name}',
      title: _titleForStatus(status),
      body: message,
      type: 'delivery',
      createdAt: timestamp,
    );
  }

  String _titleForStatus(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return '⏳ Commande en attente';
      case DeliveryStatus.confirmed:
        return '✅ Commande confirmée';
      case DeliveryStatus.preparing:
        return '📦 En préparation';
      case DeliveryStatus.onTheWay:
        return '🚚 En cours de livraison';
      case DeliveryStatus.delivered:
        return '🎉 Colis livré !';
      case DeliveryStatus.cancelled:
        return '❌ Commande annulée';
    }
  }
}
