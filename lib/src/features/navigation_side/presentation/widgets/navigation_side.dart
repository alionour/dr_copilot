import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/evaluations_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/sessions_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/financials_page.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart'; // Import PatientsPage
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/charts/presentation/pages/charts_page.dart';
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
  final FocusNode _contentFocusNode = FocusNode();
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
      debugPrint('Navigation focus node requested focus');
    });
  }

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
                      child: _buildContent(context, bloc),
                    ),
                  ),
                  // Menu icon button (only when nav is closed)

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
                          color: Colors.black.withOpacity(0.2),
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
                  Expanded(child: _buildContent(context, bloc)),
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
                _contentFocusNode.requestFocus();
                bloc.add(const ChangeFocusEvent(false));
                debugPrint('Content focus node requested focus');
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
                        ...[
                          Destination.calendar,
                          Destination.chat,
                          Destination.copilot,
                          Destination.patients,
                          Destination.settings,
                          Destination.notifications,
                          Destination.charts,
                          Destination.financials,
                        ].map((e) => SideMenuItemDataTile(
                              isSelected: state.destination == e,
                              onTap: () {
                                context
                                    .read<NavigationBloc>()
                                    .add(NavigateToEvent(e));
                                if (onItemTap != null) onItemTap();
                              },
                              title: tr(e.model.title),
                              tooltip: e.message,
                              icon: Icon(e.model.icon,
                                  color: const Color(0xff0055c3)),
                            )),
                        if (data.isOpen)
                          SideMenuItemDataTitle(
                              title: 'appointments'.tr(),
                              padding: const EdgeInsetsDirectional.all(8)),
                        ...[Destination.sessions, Destination.evaluations]
                            .map((e) => SideMenuItemDataTile(
                                  isSelected: state.destination == e,
                                  onTap: () {
                                    context
                                        .read<NavigationBloc>()
                                        .add(NavigateToEvent(e));
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

  Widget _buildContent(BuildContext context, NavigationBloc bloc) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Focus(
          focusNode: _contentFocusNode,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _navigationFocusNode.requestFocus();
                bloc.add(const ChangeFocusEvent(true));
                debugPrint('Navigation focus node requested focus');
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            color: !bloc.state.isNavigationFocused
                ? Colors.blue.withAlpha((0.2 * 255).toInt())
                : Colors.transparent,
            padding: const EdgeInsets.all(8),
            child: Builder(builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return NavMenuButtonProvider(
                  navMenuButton: NavMenuButton(
                    showMobileNav: _showMobileNav,
                    tooltip: 'Open navigation',
                    onTap: _toggleMobileNav,
                  ),
                  child: BlocBuilder<NavigationBloc, NavigationState>(
                    builder: (context, state) {
                      if (state.destination == Destination.copilot) {
                        return const Center(
                            child: CopilotPage(title: 'Dr Copilot'));
                      } else if (state.destination == Destination.calendar) {
                        return const Center(child: CalendarPage());
                      } else if (state.destination == Destination.settings) {
                        return const Center(child: SettingsPage());
                      } else if (state.destination ==
                          Destination.notifications) {
                        return const Center(child: NotificationsPage());
                      } else if (state.destination == Destination.patients) {
                        return const PatientsPage();
                      } else if (state.destination == Destination.sessions) {
                        return const Center(child: SessionsPage());
                      } else if (state.destination == Destination.evaluations) {
                        return const Center(child: EvaluationsPage());
                      } else if (state.destination == Destination.charts) {
                        return const Center(child: ChartsPage());
                      } else if (state.destination == Destination.financials) {
                        return const Center(child: FinancialsPage());
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                );
              } else {
                return BlocBuilder<NavigationBloc, NavigationState>(
                  builder: (context, state) {
                    if (state.destination == Destination.copilot) {
                      return const Center(
                          child: CopilotPage(title: 'Dr Copilot'));
                    } else if (state.destination == Destination.calendar) {
                      return const Center(child: CalendarPage());
                    } else if (state.destination == Destination.settings) {
                      return const Center(child: SettingsPage());
                    } else if (state.destination == Destination.notifications) {
                      return const Center(child: NotificationsPage());
                    } else if (state.destination == Destination.patients) {
                      return const PatientsPage();
                    } else if (state.destination == Destination.sessions) {
                      return const Center(child: SessionsPage());
                    } else if (state.destination == Destination.evaluations) {
                      return const Center(child: EvaluationsPage());
                    } else if (state.destination == Destination.charts) {
                      return const Center(child: ChartsPage());
                    } else if (state.destination == Destination.financials) {
                      return const Center(child: FinancialsPage());
                    } else {
                      return const SizedBox();
                    }
                  },
                );
              }
            }),
          ),
        );
      },
    );
  }
}
