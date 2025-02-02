import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:go_router/go_router.dart' as go_router;

void main() {
  group('RoutingConfig Tests', () {
    test('should return correct route for login', () {
      // Arrange
      final routingConfig = RoutingConfig();

      // Act
      final route = routingConfig.getRoute('/');

      // Assert
      expect(route, isNotNull);
      expect(route?.name, 'login'); // Use null-aware operator
    });

    test('should return correct route for home', () {
      // Arrange
      final routingConfig = RoutingConfig();

      // Act
      final route = routingConfig.getRoute('/home');

      // Assert
      expect(route, isNotNull);
      expect(route?.name, 'home'); // Use null-aware operator
    });

    test('should return null for unknown route', () {
      // Arrange
      final routingConfig = RoutingConfig();

      // Act
      final route = routingConfig.getRoute('/unknown');

      // Assert
      expect(route, isNull);
    });

    // Add more tests as needed
  });
}
