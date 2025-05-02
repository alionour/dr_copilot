import 'package:flutter/material.dart';

/// A reusable widget for the navigation menu icon button (hamburger menu).
class NavMenuButton extends StatelessWidget {
  final bool showMobileNav;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  const NavMenuButton({
    super.key,
    this.showMobileNav = false,
    this.onTap,
    this.tooltip,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(showMobileNav ? Icons.close : Icons.menu, size: size),
      onPressed: onTap,
      tooltip: tooltip ?? 'Open navigation',
    );
  }
}




/// An [InheritedWidget] that provides access to the navigation menu button state
/// and functionality to its descendants in the widget tree.
///
/// This provider allows widgets lower in the tree to access and interact with
/// the navigation menu button, enabling state sharing and updates without the
/// need to pass data down manually through constructors.
///
/// Typically used to manage the state of a navigation menu button across
/// multiple widgets within the patients feature.
class NavMenuButtonProvider extends InheritedWidget {
  final Widget navMenuButton;
  const NavMenuButtonProvider({
    super.key,
    required this.navMenuButton,
    required super.child,
  });

  static Widget? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<NavMenuButtonProvider>();
    return provider?.navMenuButton;
  }

  @override
  bool updateShouldNotify(NavMenuButtonProvider oldWidget) =>
      navMenuButton != oldWidget.navMenuButton;
}