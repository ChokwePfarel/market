import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkState {
  final bool isConnected;
  NetworkState(this.isConnected);
}

class NetworkInitial extends NetworkState {
  NetworkInitial() : super(true);
}

class NetworkStatus extends NetworkState {
  NetworkStatus(bool isConnected) : super(isConnected);
}
