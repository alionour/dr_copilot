import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// An abstract class that defines a contract for checking network connectivity.
abstract class NetworkInfo {
  /// Returns a [Future] that completes with `true` if the device is connected to the internet,
  /// otherwise `false`.
  Future<bool> get isConnected;
}

/// An implementation of [NetworkInfo] that uses an [InternetConnection] checker
/// to determine the network connectivity status.
class NetworkInfoImpl implements NetworkInfo {
  /// The [InternetConnection] instance used to check for internet access.
  final InternetConnection connectionChecker;

  /// Creates a [NetworkInfoImpl] with the given [connectionChecker].
  NetworkInfoImpl(this.connectionChecker);

  @override

  /// Returns a [Future] that completes with `true` if the device has internet access,
  /// otherwise `false`, as determined by [connectionChecker].
  Future<bool> get isConnected => connectionChecker.hasInternetAccess;
}

