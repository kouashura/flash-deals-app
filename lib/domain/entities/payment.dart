import 'package:equatable/equatable.dart';

enum PaymentMethod {
  orangeMoney,
  mtnMomo,
  moovMoney,
  wave,
  card,
  wallet,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN Mobile Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.wallet:
        return 'Wallet Flash Deals';
    }
  }
}

enum PaymentStatus { pending, processing, success, failed, refunded }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En cours';
      case PaymentStatus.success:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
    }
  }
}

class Payment extends Equatable {
  final String id;
  final PaymentMethod method;
  final double amount;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  @override
  List<Object?> get props => [id, method, amount, status];
}
