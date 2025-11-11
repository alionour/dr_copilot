import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/navigation_side/domain/entities/destination.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';

/// A widget that provides a side navigation menu and displays the selected page.
class NavigationSide extends StatefulWidget {
  final Widget child;
  const NavigationSide({super.key, required this.child});

  @override
  State<NavigationSide> createState() => _NavigationSideState();
}

class _NavigationSideState extends State<NavigationSide> {
  final FocusNode _navigationFocusNode = FocusNode();
  bool _showMobileNav = false;

  void _toggleMobileNav() {
    setState(() {
      _showMobileNav = !_showMobileNav;
    });
  }

  void _closeMobileNav() {
    setState(() {
      _showMobileNav = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationFocusNode.requestFocus();
    });

    // Add listener to GoRouter for route changes
    GoRouter.of(context).routerDelegate.addListener(_handleRouteChange);
  }

  @override
  void dispose() {
    GoRouter.of(context).routerDelegate.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    final currentRoute =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    Destination? newDestination;

    for (var entry in destinationToRoute.entries) {
      if (entry.value == currentRoute) {
        newDestination = entry.key;
        break;
      }
    }

    if (newDestination != null &&
        newDestination != context.read<NavigationBloc>().state.destination) {
      context.read<NavigationBloc>().add(NavigateToEvent(newDestination));
    }
  }

  static const Map<Destination, String> destinationToRoute = {
    Destination.copilot: '/home',
    Destination.calendar: '/calendar',
    Destination.settings: '/settings',
    Destination.notifications: '/notifications',
    Destination.chat: '/chat',
    Destination.liveAssistant: '/live_assistant',
    Destination.patients: '/patients',
    Destination.doctors: '/doctors',
    Destination.staff: '/staff',
    Destination.sessions: '/sessions',
    Destination.evaluations: '/evaluations',
    Destination.charts: '/charts',
    Destination.financials: '/financials',
    Destination.clinicalReports: '/clinical_reports',
    Destination.chatGptProject: '/chatgpt_project',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NavigationBloc>();
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSignedOut) {
          debugPrint('User signed out');
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            // MOBILE: Stack with menu button and overlay nav
            return Scaffold(
              body: Stack(
                children: [
                  // Main content
                  Positioned.fill(
                    child: Container(
                      color: Colors.transparent,
                      child: widget.child,
                    ),
                  ),
                  // Menu icon button (only when nav is closed)
                  if (!_showMobileNav)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: NavMenuButton(
                        showMobileNav: _showMobileNav,
                        tooltip: 'Open navigation',
                        onTap: _toggleMobileNav,
                      ),
                    ),

                  // Sidebar overlay
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    left: _showMobileNav ? 0 : -240,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 240,
                      child: Material(
                        elevation: 16,
                        child: GestureDetector(
                          onTap: () {},
                          child: _buildSideMenu(context, bloc,
                              onItemTap: _closeMobileNav),
                        ),
                      ),
                    ),
                  ),
                  // Fade overlay when nav is open
                  if (_showMobileNav)
                    Positioned(
                      left: 240,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _closeMobileNav,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            // DESKTOP/TABLET: Always show sidebar
            return Scaffold(
              body: Row(
                children: [
                  _buildSideMenu(context, bloc),
                  Expanded(child: widget.child),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context, NavigationBloc bloc,
      {VoidCallback? onItemTap}) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Focus(
          focusNode: _navigationFocusNode,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                bloc.add(const ChangeFocusEvent(false));
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                context.read<NavigationBloc>().add(NavigateDownEvent());
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                context.read<NavigationBloc>().add(NavigateUpEvent());
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            color: bloc.state.isNavigationFocused
                ? Colors.blue.withAlpha((0.2 * 255).toInt())
                : Colors.transparent,
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return SideMenu(
                  mode: SideMenuMode.open,
                  hasResizer: false,
                  hasResizerToggle: MediaQuery.of(context).size.width >=
                      600, // false on mobile, true otherwise
                  builder: (data) {
                    return SideMenuData(
                      header: data.isOpen
                          ? Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    'drCopilot'.tr(),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            )
                          : null,
                      items: [
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                            title: 'coreOperations'.tr(),
                            titleStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        ...[
                          Destination.copilot,
                          Destination.calendar,
                          Destination.liveAssistant,
                        ].map((e) => SideMenuItemDataTile(
                              isSelected: state.destination == e,
                              onTap: () {
                                context.go(destinationToRoute[e]!);
                                if (onItemTap != null) onItemTap();
                              },
                              title: tr(e.model.title),
                              tooltip: e.message,
                              icon: Icon(e.model.icon,
                                  color: const Color(0xff0055c3)),
                            )),
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                            title: tr('management'),
                            titleStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        ...[
                          Destination.patients,
                          Destination.doctors,
                          Destination.staff,
                          Destination.clinicalReports,
                        ].map((e) => SideMenuItemDataTile(
                              isSelected: state.destination == e,
                              onTap: () {
                                context.go(destinationToRoute[e]!);
                                if (onItemTap != null) onItemTap();
                              },
                              title: tr(e.model.title),
                              tooltip: e.message,
                              icon: Icon(e.model.icon,
                                  color: const Color(0xff0055c3)),
                            )),
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                            title: tr('appointments'),
                            titleStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        ...[Destination.sessions, Destination.evaluations]
                            .map((e) => SideMenuItemDataTile(
                                  isSelected: state.destination == e,
                                  onTap: () {
                                    context.go(destinationToRoute[e]!);
                                    if (onItemTap != null) onItemTap();
                                  },
                                  title: tr(e.model.title),
                                  tooltip: e.message,
                                  icon: Icon(e.model.icon,
                                      color: const Color(0xff0055c3)),
                                )),
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                            title: tr('business'),
                            titleStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        ...[
                          Destination.financials,
                          // Destination.charts,
                        ].map((e) => SideMenuItemDataTile(
                              isSelected: state.destination == e,
                              onTap: () {
                                context.go(destinationToRoute[e]!);
                                if (onItemTap != null) onItemTap();
                              },
                              title: tr(e.model.title),
                              tooltip: e.message,
                              icon: Icon(e.model.icon,
                                  color: const Color(0xff0055c3)),
                            )),
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                            title: tr('utilities'),
                            titleStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        ...[
                          Destination.notifications,
                          Destination.settings,
                          Destination.chatGptProject,
                        ].map((e) => SideMenuItemDataTile(
                              isSelected: state.destination == e,
                              onTap: () {
                                context.go(destinationToRoute[e]!);
                                if (onItemTap != null) onItemTap();
                              },
                              title: tr(e.model.title),
                              tooltip: e.message,
                              icon: Icon(e.model.icon,
                                  color: const Color(0xff0055c3)),
                            )),
                      ],
                      footer: data.isOpen
                          ? BlocBuilder<NavigationBloc, NavigationState>(
                              builder: (context, NavigationState state) {
                              final String profileImageUrl =
                                  state.user?.photoURL ?? '';
                              return ListTile(
                                title: Text(state.user?.displayName ?? ''),
                                leading: profileImageUrl.isNotEmpty
                                    ? InkWell(
                                        onTap: () {
                                          context.go('/account');
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle),
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: profileImageUrl,
                                              cacheKey: state.user?.uid,
                                              placeholder: (ctx, url) =>
                                                  const Icon(Icons.person_pin),
                                              errorWidget:
                                                  (context, url, error) {
                                                debugPrint(
                                                    'Failed to load image: $error');
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.person_3_outlined),
                              );
                            })
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
