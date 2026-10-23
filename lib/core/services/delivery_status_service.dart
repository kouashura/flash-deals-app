import 'dart:async';
import '../../domain/entities/delivery.dart';

class OrderStatusSnapshot {
  final String orderId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String? note;

  OrderStatusSnapshot({
    required this.orderId,
    required this.status,
    required this.timestamp,
    this.note,
  });
}

class DeliveryStatusService {
  static final DeliveryStatusService _instance =
      DeliveryStatusService._internal();
  factory DeliveryStatusService() => _instance;
  DeliveryStatusService._internal();

  final Map<String, DeliveryStatus> _statuses = {};
  final Map<String, List<OrderStatusSnapshot>> _history = {};
  final _updatesController =
      StreamController<OrderStatusSnapshot>.broadcast();

  Stream<OrderStatusSnapshot> get updates => _updatesController.stream;

  void updateStatus({
    required String orderId,
    required DeliveryStatus newStatus,
    String? note,
  }) {
    final snapshot = OrderStatusSnapshot(
      orderId: orderId,
      status: newStatus,
      timestamp: DateTime.now(),
      note: note,
    );
    _statuses[orderId] = newStatus;
    _history.putIfAbsent(orderId, () => []).add(snapshot);
    _updatesController.add(snapshot);
  }

  DeliveryStatus getStatus(String orderId) =>
      _statuses[orderId] ?? DeliveryStatus.pending;

  List<OrderStatusSnapshot> getHistory(String orderId) =>
      _history[orderId] ?? [];

  Stream<OrderStatusSnapshot> streamFor(String orderId) {
    return updates.where((s) => s.orderId == orderId);
  }

  List<String> get activeOrderIds => _statuses.keys.toList();

  DeliveryStatus? nextStep(DeliveryStatus current) {
    switch (current) {
      case DeliveryStatus.pending:
        return DeliveryStatus.confirmed;
      case DeliveryStatus.confirmed:
        return DeliveryStatus.preparing;
      case DeliveryStatus.preparing:
        return DeliveryStatus.onTheWay;
      case DeliveryStatus.onTheWay:
        return DeliveryStatus.delivered;
      case DeliveryStatus.delivered:
      case DeliveryStatus.cancelled:
        return null;
    }
  }

  static String labelFor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.confirmed:
        return 'Confirmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.onTheWay:
        return 'En cours de livraison';
      case DeliveryStatus.delivered:
        return 'Livré';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }
}
