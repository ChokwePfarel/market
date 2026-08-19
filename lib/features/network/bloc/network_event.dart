import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkEvent {}

class NetworkChanged extends NetworkEvent {
  final List<ConnectivityResult> results;
  NetworkChanged(this.results);
}
