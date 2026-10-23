import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/delivery_pricing_service.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  DeliveryBloc() : super(const DeliveryState()) {
    on<SetDeliveryMode>(_onSetMode);
    on<SetDeliveryZone>(_onSetZone);
    on<RecalculateDelivery>(_onRecalculate);
  }

  void _onSetMode(SetDeliveryMode event, Emitter<DeliveryState> emit) {
    emit(state.copyWith(mode: event.mode, clearError: true));
  }

  void _onSetZone(SetDeliveryZone event, Emitter<DeliveryState> emit) {
    final newState = state.copyWith(zone: event.zone, clearError: true);
    try {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        totalWeightKg: state.totalWeightKg,
        zone: event.zone,
      );
      emit(newState.copyWith(deliveryFee: fee));
    } catch (e) {
      emit(newState.copyWith(error: e.toString()));
    }
  }

  void _onRecalculate(
    RecalculateDelivery event,
    Emitter<DeliveryState> emit,
  ) {
    try {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        totalWeightKg: event.totalWeightKg,
        zone: state.zone,
      );
      emit(state.copyWith(
        totalWeightKg: event.totalWeightKg,
        deliveryFee: fee,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        totalWeightKg: event.totalWeightKg,
        error: e.toString(),
      ));
    }
  }
}
