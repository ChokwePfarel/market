import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'network_event.dart';
import 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  NetworkBloc() : super(NetworkInitial()) {
    on<NetworkChanged>((event, emit) {
      final isConnected = event.results.isNotEmpty && event.results.first != ConnectivityResult.none;
      emit(NetworkStatus(isConnected));
    });

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      add(NetworkChanged(results));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

