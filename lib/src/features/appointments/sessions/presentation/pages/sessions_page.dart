import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/widgets/session_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context
        .read<SessionsBloc>()
        .add( GetSessions(query)); // Fetch sessions on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Focus(
                focusNode: _searchFocusNode,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Sessions',
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.onSurface),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  onChanged: (newQuery) {
                    setState(() {
                      query = newQuery;
                      _selectedIndex = 0; // Reset selection on new query
                    });
                    context
                        .read<SessionsBloc>()
                        .add(SearchSessions(query)); // Trigger search event
                  },
                  onSubmitted: (_) {
                    _listFocusNode.requestFocus();
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<SessionsBloc>().add(const GetSessions(''));
              },
            ),
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
            } else if (state is SessionsLoaded) {
              final filteredSessions = state.sessions.where((session) {
                return session.patientName
                    .toLowerCase()
                    .contains(query.toLowerCase());
              }).toList();
              if (filteredSessions.isEmpty) {
                return const Center(child: Text('No sessions found.'));
              }
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Focus(
                  focusNode: _listFocusNode,
                  autofocus: true,
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        moveSelectionDown(filteredSessions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        moveSelectionUp(filteredSessions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowLeft) {
                        _searchFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final sessionModel = filteredSessions[index];
                      return SessionListItem(
                        sessionModel: sessionModel,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              );
            } else if (state is SessionsError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No sessions found.'));
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
}
