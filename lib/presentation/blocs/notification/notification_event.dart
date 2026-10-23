import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class MarkAsRead extends NotificationEvent {
  final String id;
  const MarkAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}

class AddNotification extends NotificationEvent {
  final AppNotification notification;
  const AddNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}

/// Événement envoyé quand l'utilisateur se connecte/déconnecte
class UserChanged extends NotificationEvent {
  const UserChanged();
}
