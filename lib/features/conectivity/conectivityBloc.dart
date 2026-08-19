import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


/// Events
abstract class ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isOffline;
  ConnectivityChanged(this.isOffline);
}

/// States
class ConnectivityState {
  final bool isOffline;
  const ConnectivityState({required this.isOffline});
}

/// Bloc
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription? _subscription;

  ConnectivityBloc({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityState(isOffline: false)) {
    // Start listening immediately
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final offline = result == ConnectivityResult.none;
      add(ConnectivityChanged(offline));
    });

    on<ConnectivityChanged>((event, emit) {
      emit(ConnectivityState(isOffline: event.isOffline));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
