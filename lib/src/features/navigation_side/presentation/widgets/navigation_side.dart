import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/navigation_side/domain/entities/destination.dart';
// import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart'; // Removed
import 'package:dr_copilot/src/features/navigation_side/presentation/helpers/navigation_helper.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:dr_copilot/src/core/services/feature_discovery_service.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/calendar_events/presentation/bloc/calendar_events_bloc.dart';

import 'package:dr_copilot/src/features/presentation/domain/services/presentation_service.dart';

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
  bool _showSwipeHint = false;
  GoRouterDelegate? _routerDelegate;
  final SideMenuController _sideMenuController = SideMenuController();
  OwnerNotifier? _ownerNotifier;

  // Feature discovery showcase keys - Core Operations
  final GlobalKey _copilotKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();

  // Management
  final GlobalKey _patientsKey = GlobalKey();
  final GlobalKey _doctorsKey = GlobalKey();
  final GlobalKey _departmentsKey = GlobalKey();
  final GlobalKey _clinicalReportsKey = GlobalKey();

  // Business
  final GlobalKey _financialsKey = GlobalKey();

  // Utilities
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  // Team Collaboration
  final GlobalKey _teamsKey = GlobalKey();

  final PresentationService _presentationService = PresentationService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to OwnerNotifier for safe disposal
    final newOwnerNotifier = context.read<OwnerNotifier>();
    if (_ownerNotifier != newOwnerNotifier) {
      _ownerNotifier?.removeListener(_updateDestinations);
      _ownerNotifier = newOwnerNotifier;
      _ownerNotifier?.addListener(_updateDestinations);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSwipeHint();

    // Start streaming calendar events for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigationFocusNode.requestFocus();
      _routerDelegate = GoRouter.of(context).routerDelegate;
      _routerDelegate?.addListener(_handleRouteChange);

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSignedIn) {
        context.read<NavigationBloc>().add(UserChanged(authState.user));
      }

      // Dispatch stream event for today's schedule
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      context.read<CalendarEventsBloc>().add(
            StreamEventsByDateRange(startOfDay, endOfDay),
          );

      _updateDestinations();
      _checkAndShowFeatureDiscovery();
    });
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_handleRouteChange);
    _ownerNotifier?.removeListener(_updateDestinations);
    _navigationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_swipe_hint') ?? false;
    if (!hasSeen && mounted) {
      setState(() {
        _showSwipeHint = true;
      });
    }
  }

  Future<void> _dismissSwipeHint() async {
    if (!_showSwipeHint) return;
    setState(() {
      _showSwipeHint = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_swipe_hint', true);
  }

  Future<void> _checkAndShowFeatureDiscovery() async {
    if (!mounted) return;

    final featureDiscoveryService =
        await sl.getAsync<FeatureDiscoveryService>();
    final shouldShow = await featureDiscoveryService.shouldShowDiscovery();

    if (shouldShow && mounted) {
      // Wait a bit for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final showcaseKeys = [
        _copilotKey,
        _calendarKey,
        _patientsKey,
        _doctorsKey,
        _departmentsKey,
        _clinicalReportsKey,
        _financialsKey,
        _notificationsKey,
        _settingsKey,
        _teamsKey,
      ].where((key) => key.currentContext != null).toList();

      if (showcaseKeys.isNotEmpty) {
        ShowCaseWidget.of(context).startShowCase(showcaseKeys);
        await featureDiscoveryService.markDiscoveryAsSeen();
      }
    }
  }

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

  void _updateDestinations() async {
    if (!mounted) return;
    final navBloc = context.read<NavigationBloc>();
    final ownerNotifier = context.read<OwnerNotifier>();
    final destinations = await NavigationHelper.getAllowedDestinations(
      navBloc.state.user,
      ownerNotifier.clinicId,
    );

    if (!mounted) return;
    navBloc.add(DestinationsUpdated(destinations));
  }

  void _handleRouteChange() {
    final currentRoute = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
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
    Destination.teamChat: '/team_chat',
    Destination.teams: '/teams',
    Destination.liveAssistant: '/live_assistant',
    Destination.patients: '/patients',
    Destination.doctors: '/doctors',
    Destination.departments: '/departments',
    Destination.staff: '/staff',
    Destination.invitations: '/invitations',
    Destination.sessions: '/sessions',
    Destination.evaluations: '/evaluations',
    Destination.charts: '/charts',
    Destination.financials: '/financials',
    Destination.clinicalReports: '/clinical_reports',
    Destination.chatGptProject: '/chatgpt_project',
    Destination.recycleBin: '/recycle_bin',
    Destination.tasks: '/tasks',
    Destination.inventory: '/inventory',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NavigationBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSignedIn) {
              context.read<NavigationBloc>().add(UserChanged(state.user));
            } else if (state is AuthSignedOut) {
              context.read<NavigationBloc>().add(const UserChanged(null));
            }
          },
        ),
        BlocListener<NavigationBloc, NavigationState>(
          listenWhen: (previous, current) => previous.user != current.user,
          listener: (context, state) {
            _updateDestinations();
          },
        ),
        BlocListener<CalendarEventsBloc, CalendarEventsState>(
          listener: (context, state) {
            if (state is CalendarEventsLoaded) {
              _presentationService.updateSchedule(state.events);
            }
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                _dismissSwipeHint();
                if (details.primaryVelocity! > 0) {
                  if (!_showMobileNav) _toggleMobileNav();
                } else if (details.primaryVelocity! < 0) {
                  if (_showMobileNav) _closeMobileNav();
                }
              },
              child: Material(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.transparent,
                        child: SafeArea(
                          child: SelectionArea(child: widget.child),
                        ),
                      ),
                    ),
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
                            child: _buildSideMenu(
                              context,
                              bloc,
                              isMobile: true,
                              onItemTap: _closeMobileNav,
                              avoidSystemBottomInset: true,
                            ),
                          ),
                        ),
                      ),
                    ),
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
                    if (_showSwipeHint &&
                        !_showMobileNav &&
                        !const bool.fromEnvironment('SCREENSHOT_MODE'))
                      Positioned(
                        bottom: 100,
                        left: 20,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Swipe right to navigate',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _dismissSwipeHint,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Row(
                children: [
                  _buildSideMenu(context, bloc, isMobile: false),
                  Expanded(child: SelectionArea(child: widget.child)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSideMenu(
    BuildContext context,
    NavigationBloc bloc, {
    VoidCallback? onItemTap,
    bool avoidSystemBottomInset = false,
    bool isMobile = false,
  }) {
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
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return SideMenu(
                  controller: _sideMenuController,
                  mode: SideMenuMode.open,
                  hasResizer: false,
                  hasResizerToggle: false,
                  builder: (data) {
                    return SideMenuData(
                      header: data.isOpen
                          ? InkWell(
                              onTap: isMobile
                                  ? null
                                  : () {
                                      _sideMenuController.toggle();
                                    },
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icon.svg',
                                        width: 32,
                                        height: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'drCopilot'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.orange, width: 1),
                                        ),
                                        child: Text(
                                          'BETA',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : null,
                      items: state.allowedDestinations.entries
                          .map((entry) {
                            final category = entry.key;
                            final destinations = entry.value;
                            return [
                              if (data.isOpen && category != 'business')
                                SideMenuItemDataTitle(
                                  title: category.tr(),
                                  titleStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                ),
                              ...destinations.map(
                                (e) {
                                  GlobalKey? showcaseKey;
                                  String? description;

                                  // Assign showcase keys to features
                                  if (e == Destination.copilot) {
                                    showcaseKey = _copilotKey;
                                    description =
                                        'Your AI medical assistant - get help with diagnoses, treatment plans, and medical questions.';
                                  } else if (e == Destination.calendar) {
                                    showcaseKey = _calendarKey;
                                    description =
                                        'View and manage your appointments and schedule.';
                                  } else if (e == Destination.patients) {
                                    showcaseKey = _patientsKey;
                                    description =
                                        'Access and manage patient records, medical history, and contact information.';
                                  } else if (e == Destination.doctors) {
                                    showcaseKey = _doctorsKey;
                                    description =
                                        'Manage doctor profiles, specializations, and assignments.';
                                  } else if (e == Destination.departments) {
                                    showcaseKey = _departmentsKey;
                                    description =
                                        'Manage clinical departments and staff organization.';
                                  } else if (e == Destination.clinicalReports) {
                                    showcaseKey = _clinicalReportsKey;
                                    description =
                                        'Create and manage clinical reports, medical documentation, and patient evaluations.';
                                  } else if (e == Destination.financials) {
                                    showcaseKey = _financialsKey;
                                    description =
                                        'Track income, expenses, transactions, and financial analytics.';
                                  } else if (e == Destination.notifications) {
                                    showcaseKey = _notificationsKey;
                                    description =
                                        'Stay updated with important alerts, reminders, and system notifications.';
                                  } else if (e == Destination.settings) {
                                    showcaseKey = _settingsKey;
                                    description =
                                        'Customize app preferences, theme, notifications, and account settings.';
                                  } else if (e == Destination.teams) {
                                    showcaseKey = _teamsKey;
                                    description =
                                        'Collaborate with your team, manage roles, and coordinate patient care.';
                                  }

                                  final icon = Icon(
                                    e.model.icon,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  );

                                  return SideMenuItemDataTile(
                                    isSelected: state.destination == e,
                                    onTap: () {
                                      final route = destinationToRoute[e];
                                      if (route != null) {
                                        context.go(route);
                                      }
                                      if (onItemTap != null) onItemTap();
                                    },
                                    title: tr(e.model.title),
                                    tooltip: e.message,
                                    icon: showcaseKey != null &&
                                            description != null
                                        ? Showcase(
                                            key: showcaseKey,
                                            description: description,
                                            targetPadding:
                                                const EdgeInsets.only(
                                              top: 8,
                                              bottom: 8,
                                              left: 8,
                                              right:
                                                  180, // Extend to cover label
                                            ),
                                            targetBorderRadius:
                                                BorderRadius.circular(12),
                                            tooltipBorderRadius:
                                                BorderRadius.circular(12),
                                            child: icon,
                                          )
                                        : icon,
                                  );
                                },
                              ),
                            ];
                          })
                          .expand((element) => element)
                          .toList(),
                      footer: data.isOpen
                          ? BlocBuilder<NavigationBloc, NavigationState>(
                              builder: (context, NavigationState state) {
                                final String profileImageUrl =
                                    state.user?.photoURL ?? '';
                                final bottomInset = avoidSystemBottomInset
                                    ? MediaQuery.viewPaddingOf(context).bottom
                                    : 0.0;

                                return InkWell(
                                  onTap: () {
                                    context.push('/account');
                                    if (onItemTap != null) onItemTap();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      16.0,
                                      8.0,
                                      16.0,
                                      8.0 + bottomInset,
                                    ),
                                    child: Row(
                                      children: [
                                        if (profileImageUrl.isNotEmpty)
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: profileImageUrl,
                                                cacheKey: state.user?.uid,
                                                placeholder: (
                                                  ctx,
                                                  url,
                                                ) =>
                                                    const Icon(
                                                  Icons.account_circle_outlined,
                                                ),
                                                errorWidget: (
                                                  context,
                                                  url,
                                                  error,
                                                ) {
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.person_3_outlined,
                                            size: 40,
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            state.user?.displayName ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
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
