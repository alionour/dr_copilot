import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/widgets/session_list_item.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  String query = '';
  DateTime? selectedDate; // Add selectedDate variable
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  bool _showFilters = false; // State to toggle filter icons
  DateTime? _selectedDate;
  bool _canLoadMore = true; // Add a flag to control loading more sessions
  int? _firestoreSessionsCount;

  void _dispatchGetSessionsCount() {
    context.read<SessionsBloc>().add(const GetSessionsCount());
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<SessionsBloc>().add(const GetSessions());
    _dispatchGetSessionsCount();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<SessionsBloc>().state;
      if (state is SessionsLoaded && !state.isLoadingMore) {
        if (_canLoadMore) {
          _canLoadMore = false;
          context.read<SessionsBloc>().add(LoadMoreSessions(
                lastDocumentId: state.sessions.last.id,
                limit: 20,
              ));
          Future.delayed(const Duration(seconds: 1), () {
            _canLoadMore = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Focus(
                focusNode: _searchFocusNode,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchSessions'.tr(),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.onSurface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 0.3),
                    ),
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  onChanged: (newQuery) {
                    setState(() {
                      query = newQuery;
                      _selectedIndex = 0; // Reset selection on new query
                    });
                    context.read<SessionsBloc>().add(
                        SearchSessions(name: query)); // Trigger search event
                  },
                  onSubmitted: (_) {
                    _listFocusNode.requestFocus();
                  },
                ),
              ),
            ),
            // Update the refresh button to clear all filters
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'refresh'.tr(),
              onPressed: () {
                setState(() {
                  query = '';
                  _selectedDate = null;
                });
                context.read<SessionsBloc>().add(const GetSessions());
              },
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                // border: Border.all(
                //   color: Theme.of(context)
                //       .colorScheme
                //       .primary
                //       .withOpacity(0.3), // Adjusted color to be less intense
                //   width: 0.3, // Made the border thinner
                // ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.2),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    tooltip: 'toggleFilters'.tr(),
                    onPressed: () {
                      setState(() {
                        _showFilters =
                            !_showFilters; // Toggle filter visibility
                      });
                    },
                  ),
                  if (_showFilters) ...[
                    // Update the filter logic to clear previous filter values when a new filter is selected, unless mixed filters are allowed.
                    IconButton(
                      icon: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          if (_selectedDate != null)
                            Text(
                              _selectedDate!.toLocal().toString().split(' ')[0],
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      tooltip: 'filterByDate'.tr(),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _selectedDate = selectedDate;
                          });
                          if (!context.mounted) return;

                          context
                              .read<SessionsBloc>()
                              .add(GetSessionsByDate(date: selectedDate));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (navMenuButton != null) navMenuButton,
          
          ],
        ),
      ),
      body: BlocListener<SessionsBloc, SessionsState>(
        listener: (context, state) {
          if (state is SessionsSuccess) {
            final message = state.message;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                ),
              );
            }
          } else if (state is SessionsError) {
            final message = state.message;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          }
        },
        child: BlocBuilder<SessionsBloc, SessionsState>(
          builder: (context, state) {
            if (state is SessionsLoading) {
              return Shimmer.fromColors(
                baseColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                highlightColor: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      height: 50.0,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              );
            } else if (state is SessionsLoaded ||
                state is SessionsLoadingMore) {
              final sessions = state is SessionsLoaded
                  ? state.sessions
                  : (state as SessionsLoadingMore).sessions;

              if (sessions.isEmpty) {
                return Center(
                  child: Text('noSessionsMatch'.tr()),
                );
              }

              // Group sessions by creation date
              final groupedSessions = <String, List<SessionModel>>{};
              for (var session in sessions) {
                final creationDate = DateFormat('yyyy-MM-dd')
                    .format(session.startDateTime.toDate());
                groupedSessions
                    .putIfAbsent(creationDate, () => [])
                    .add(session);
              }

              // Sort grouped sessions by date in descending order
              final sortedGroupedSessions = groupedSessions.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key));

              return Column(
                children: [
                  // Add a label to show the total number of sessions (like patients_page)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment, size: 20, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${sessions.length} ',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                        ),
                        Text(
                          'sessionsLoaded'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_firestoreSessionsCount != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.cloud, size: 18, color: Colors.deepPurple),
                          const SizedBox(width: 2),
                          Text(
                            '$_firestoreSessionsCount',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                          ),
                          Text(
                            ' ${'storedSessions'.tr()} ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ]
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: sortedGroupedSessions.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedGroupedSessions[index].key;
                        final sessionsForDate =
                            sortedGroupedSessions[index].value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Text(
                                _getDateLabel(dateKey),
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            ...sessionsForDate.map((session) {
                              return SessionListItem(
                                sessionModel: session,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = sessions.indexOf(session);
                                  });
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                  if (state is SessionsLoaded && state.isLoadingMore ||
                      state is SessionsLoadingMore)
                    Shimmer.fromColors(
                      baseColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      highlightColor: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else if (state is SessionsError) {
              debugPrint('Error: ${state.message}');

              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('noSessionsFound'.tr()));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sessions/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void moveSelectionDown(int length) {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % length;
    });
    _scrollController.animateTo(
      _selectedIndex * 50.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void moveSelectionUp(int length) {
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + length) % length;
    });
    _scrollController.animateTo(
      _selectedIndex * 50.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  String _getDateLabel(String dateKey) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final parsedDate = DateTime.tryParse(dateKey);

    if (parsedDate != null) {
      if (parsedDate.year == today.year &&
          parsedDate.month == today.month &&
          parsedDate.day == today.day) {
        return 'today'.tr();
      } else if (parsedDate.year == yesterday.year &&
          parsedDate.month == yesterday.month &&
          parsedDate.day == yesterday.day) {
        return 'yesterday'.tr();
      }
    }
    return DateFormat('EEEE, MMMM dd, yyyy', context.locale.toString())
        .format(parsedDate ?? DateTime.now());
  }
}
