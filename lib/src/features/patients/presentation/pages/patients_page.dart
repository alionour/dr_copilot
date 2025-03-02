import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// A page that displays a list of patients and allows searching through them.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String query = '';
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      print('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
    context
        .read<PatientsBloc>()
        .add(GetPatients(query)); // Fetch patients on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Focus(
          focusNode: _searchFocusNode,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Patients',
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
                  .read<PatientsBloc>()
                  .add(SearchPatients(query)); // Trigger search event
            },
            onSubmitted: (_) {
              _listFocusNode.requestFocus();
            },
          ),
        ),
      ),
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          if (!navState.isNavigationFocused) {
            _listFocusNode.requestFocus();
          }
          return BlocBuilder<PatientsBloc, PatientsState>(
            builder: (context, state) {
              if (state is PatientsLoading) {
                print('PatientsLoading state');
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
              } else if (state is PatientsLoaded) {
                print(
                    'PatientsLoaded state with ${state.patients.length} patients');
                final filteredPatients = state.patients.where((patient) {
                  return patient.name
                      .toLowerCase()
                      .contains(query.toLowerCase());
                }).toList();
                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surface, // Use a solid color background
                  child: Focus(
                    focusNode: _listFocusNode,
                    autofocus: true,
                    onKeyEvent: (FocusNode node, KeyEvent event) {
                      if (!navState.isNavigationFocused) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            moveSelectionDown(filteredPatients.length);
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowUp) {
                            moveSelectionUp(filteredPatients.length);
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowLeft) {
                            _searchFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: !navState.isNavigationFocused &&
                                  _selectedIndex == index
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2)
                              : Colors.transparent,
                          child: PatientListItem(
                            name: filteredPatients[index].name,
                            details:
                                'Details for ${filteredPatients[index].name}',
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              } else if (state is PatientsError) {
                print('PatientsError state: ${state.message}');
                return Center(child: Text('Error: ${state.message}'));
              }
              print('No patients found state');
              return const Center(child: Text('No patients found.'));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/patients/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Moves the selection down in the list.
  ///
  /// This method updates the selected index and scrolls the list to the new position.
  /// @param length The length of the list.
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

  /// Moves the selection up in the list.
  ///
  /// This method updates the selected index and scrolls the list to the new position.
  /// @param length The length of the list.
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

  /// Normalizes Arabic text for better search matching.
  ///
  /// This method replaces certain Arabic characters with their normalized forms.
  /// @param input The input string to normalize.
  /// @return The normalized string.
  String _normalize(String input) {
    return input
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و');
  }
}
