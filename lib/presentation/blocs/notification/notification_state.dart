import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart';

class NotificationState extends Equatable {
  final List<AppNotification> notifications;

  const NotificationState({this.notifications = const []});

  /// Nombre de notifications non lues
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({List<AppNotification>? notifications}) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [notifications];
}
