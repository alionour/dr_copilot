import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class NoInternetBanner extends StatelessWidget {
  final Widget child;

  const NoInternetBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<ConnectivityService>(
          builder: (context, service, _) {
            if (service.hasInternet) {
              return const SizedBox.shrink();
            }
            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.red,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'No internet. App features may not work.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
