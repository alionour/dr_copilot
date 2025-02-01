import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/copilot/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationSide extends StatelessWidget {
  final Widget child;
  const NavigationSide({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return SideMenu(
                  mode: SideMenuMode.open,
                  hasResizer: false,
                  hasResizerToggle: true,
                  resizerToggleData: const ResizerToggleData(),
                  builder: (data) {
                    return SideMenuData(
                      header: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.crop_5_4_outlined),
                            title: const Text(
                              'Dr Copilot',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).showOrNull(data.isOpen),
                            trailing: const Icon(Icons.search)
                                .showOrNull(data.isOpen),
                          ),
                          // if (data.isOpen) const ChipTabBar()
                        ],
                      ),
                      items: [
                        ...Destination.values.map(
                          (e) => SideMenuItemDataTile(
                            isSelected: state.destination == e,
                            onTap: () {
                              context
                                  .read<NavigationBloc>()
                                  .add(NavigateToEvent(e));
                            },
                            title: e.model.title,
                            icon: Icon(
                              e.model.icon,
                              color: const Color(0xff0055c3),
                            ),
                          ),
                        ),
                      ],
                      footer: data.isOpen
                          ? BlocBuilder<NavigationBloc, NavigationState>(
                              builder: (context, NavigationState state) {
                              final String profileImageUrl =
                                  state.user?.userMetadata?['picture'] ?? '';
                              return ListTile(
                                title: Text(state
                                            .user?.userMetadata?['full_name'] ??
                                        '')
                                    .showOrNull(data.isOpen),
                                trailing: IconButton(
                                    onPressed: () {
                                      Supabase.instance.client.auth.signOut();
                                      context.go('/');
                                    },
                                    icon: const Icon(Icons.logout_outlined)),
                                leading: profileImageUrl.isNotEmpty
                                    ? Container(
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle),
                                        child: CachedNetworkImage(
                                          imageUrl: profileImageUrl,
                                          placeholder: (ctx, url) =>
                                              const Icon(Icons.person_pin),
                                          errorWidget: (context, url, error) {
                                            debugPrint(
                                                'Failed to load image: $error');
                                            return const SizedBox();
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.person_3_outlined),
                              );
                            })
                          : const SizedBox(),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                if (state.destination == Destination.copilot) {
                  return const Center(child: CopilotPage(title: 'Dr Copilot'));
                } else if (state.destination == Destination.calendar) {
                  return const Center(
                    child: CalendarPage(),
                  );
                } else if (state.destination == Destination.settings) {
                  return const Center(
                    child: SettingsPage(),
                  );
                } else if (state.destination == Destination.notifications) {
                  return const Center(
                    child: NotificationsPage(),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget? showOrNull(bool isShow) => isShow ? this : null;
}
