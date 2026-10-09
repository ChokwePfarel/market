
abstract class NetworkState {
  final bool isConnected;
  NetworkState(this.isConnected);
}

class NetworkInitial extends NetworkState {
  NetworkInitial() : super(true);
}

class NetworkStatus extends NetworkState {
  NetworkStatus(super.isConnected);
}

