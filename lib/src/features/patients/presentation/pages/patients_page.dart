import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
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
  bool _showFilters = false; // State to toggle filter icons
  DateTime? _selectedDate;
  String? _selectedGender;
  int? _minAge;
  int? _maxAge;
  String? _selectedAddress; // Add a variable to store the selected address

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      debugPrint('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
    context
        .read<PatientsBloc>()
        .add(const GetPatients()); // Fetch patients on init
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
                    hintText: 'searchPatients'.tr(),
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
                    context.read<PatientsBloc>().add(
                        SearchPatients(name: query)); // Trigger search event
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
                  _selectedGender = null;
                  _minAge = null;
                  _maxAge = null;
                  _selectedAddress = null;
                });
                context.read<PatientsBloc>().add(const GetPatients());
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
                          if (!mounted) return;
                          setState(() {
                            _selectedDate = selectedDate;
                            _selectedGender = null;
                            _minAge = null;
                            _maxAge = null;
                            _selectedAddress = null; // Clear address value
                          });
                          if (!mounted) return;
                          context
                              .read<PatientsBloc>()
                              .add(GetPatientsByDate(date: selectedDate));
                        }
                      },
                    ),
                    IconButton(
                      icon: Row(
                        children: [
                          const Icon(Icons.male),
                          if (_selectedGender == 'Male')
                            Text(
                              'male'.tr(),
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      tooltip: 'filterByMale'.tr(),
                      onPressed: () {
                        setState(() {
                          _selectedGender = 'Male';
                          _selectedDate = null;
                          _minAge = null;
                          _maxAge = null;
                          _selectedAddress = null; // Clear address value
                        });
                        context
                            .read<PatientsBloc>()
                            .add(SearchPatients(gender: 'male'.tr()));
                      },
                    ),
                    IconButton(
                      icon: Row(
                        children: [
                          const Icon(Icons.female),
                          if (_selectedGender == 'Female')
                            const Text(
                              'Female',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      tooltip: 'filterByFemale'.tr(),
                      onPressed: () {
                        setState(() {
                          _selectedGender = 'Female';
                          _selectedDate = null;
                          _minAge = null;
                          _maxAge = null;
                          _selectedAddress = null; // Clear address value
                        });
                        context
                            .read<PatientsBloc>()
                            .add(SearchPatients(gender: 'female'.tr()));
                      },
                    ),
                    IconButton(
                      icon: Row(
                        children: [
                          const Icon(Icons.numbers),
                          if (_minAge != null || _maxAge != null)
                            Text(
                              '${_minAge ?? ''}-${_maxAge ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      tooltip: 'filterByAge'.tr(),
                      onPressed: () async {
                        final minAgeController = TextEditingController();
                        final maxAgeController = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('filterByAge'.tr()),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: minAgeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)')),
                                    ],
                                    decoration: InputDecoration(
                                        hintText: 'minAge'.tr()),
                                  ),
                                  TextField(
                                    controller: maxAgeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)')),
                                    ],
                                    decoration: InputDecoration(
                                        hintText: 'maxAge'.tr()),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('cancel'.tr()),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final minAge =
                                        int.tryParse(minAgeController.text);
                                    final maxAge =
                                        int.tryParse(maxAgeController.text);
                                    if ((minAge != null && minAge >= 0) ||
                                        (maxAge != null && maxAge <= 130)) {
                                      setState(() {
                                        _minAge = minAge;
                                        _maxAge = maxAge;
                                        _selectedDate = null;
                                        _selectedGender = null;
                                        _selectedAddress =
                                            null; // Clear address value
                                      });
                                      context.read<PatientsBloc>().add(
                                          SearchPatients(
                                              minAge: minAge, maxAge: maxAge));
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('apply'.tr()),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Row(
                        children: [
                          const Icon(Icons.location_on),
                          if (_selectedAddress != null)
                            Text(
                              _selectedAddress!,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      tooltip: 'filterByAddress'.tr(),
                      onPressed: () async {
                        final addressController = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('filterByAddress'.tr()),
                              content: TextField(
                                controller: addressController,
                                decoration: InputDecoration(
                                    hintText: 'enterAddress'.tr()),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('cancel'.tr()),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final address = addressController.text;
                                    if (address.isNotEmpty) {
                                      setState(() {
                                        _selectedAddress = address;
                                        _selectedDate = null;
                                        _selectedGender = null;
                                        _minAge = null;
                                        _maxAge = null;
                                      });
                                      context.read<PatientsBloc>().add(
                                          SearchPatients(address: address));
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('apply'.tr()),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          if (!navState.isNavigationFocused) {
            _listFocusNode.requestFocus();
          }
          return BlocListener<PatientsBloc, PatientsState>(
            listener: (context, state) {
              if (state is PatientsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              } else if (state is PatientsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
            child: BlocBuilder<PatientsBloc, PatientsState>(
              builder: (context, state) {
                if (state is PatientsLoading) {
                  debugPrint('PatientsLoading state');
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
                } else if (state is PatientsLoaded && state.patients.isEmpty) {
                  return Center(child: Text('noPatients'.tr()));
                } else if (state is PatientsLoaded) {
                  debugPrint(
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
                                    .withValues(alpha: 0.2)
                                : Colors.transparent,
                            child: PatientListItem(
                              id: filteredPatients[index].id,
                              name: filteredPatients[index].name,
                              age: filteredPatients[index].age, // Add age
                              address: filteredPatients[index]
                                  .address, // Add address
                              gender:
                                  filteredPatients[index].gender, // Add gender
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
                  debugPrint('PatientsError state: ${state.message}');
                  return Center(child: Text('Error: ${state.message}'));
                }
                debugPrint('No patients found state');
                return Center(child: Text('noPatients'.tr()));
              },
            ),
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
