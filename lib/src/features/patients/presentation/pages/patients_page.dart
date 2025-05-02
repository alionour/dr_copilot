import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';

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
  bool _canLoadMore = true; // Add a flag to control loading more patients
  int? _firestorePatientsCount;

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      debugPrint('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
    _scrollController.addListener(_onScroll);
    context.read<PatientsBloc>().add(const GetPatients());
    context.read<PatientsBloc>().add(GetPatientsCount());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _listFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<PatientsBloc>().state;
      if (state is PatientsLoaded && !state.isLoadingMore) {
        if (_canLoadMore) {
          _canLoadMore = false;
          context.read<PatientsBloc>().add(LoadMorePatients(
                lastDocumentId: state.patients.last.id,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
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
                    context.read<PatientsBloc>().add(
                        SearchPatients(name: query)); // Trigger search event
                  },
                  onSubmitted: (_) {
                    _listFocusNode.requestFocus();
                  },
                ),
              ),
            ),
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
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
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
                                  _selectedDate!
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
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
                              if (!context.mounted) return;
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
                                .add(SearchPatients(gender: 'Male'));
                          },
                        ),
                        IconButton(
                          icon: Row(
                            children: [
                              const Icon(Icons.female),
                              if (_selectedGender == 'Female')
                                Text(
                                  'female'.tr(),
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
                                .add(SearchPatients(gender: 'Female'));
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
                                                  minAge: minAge,
                                                  maxAge: maxAge));
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
            if (navMenuButton != null) navMenuButton,
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<NavigationBloc, NavigationState>(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                    if (state is PatientsCountLoaded) {
                      setState(() {
                        _firestorePatientsCount = state.count;
                      });
                    }
                  },
                  child: BlocBuilder<PatientsBloc, PatientsState>(
                    builder: (context, state) {
                      if (state is PatientsLoading) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ListView.builder(
                            itemCount:
                                10, // Placeholder count for shimmer effect
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Container(
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else if (state is PatientsLoaded ||
                          state is PatientsLoadingMore ||
                          state is PatientsCountLoaded) {
                        final patients = (state is PatientsLoaded)
                            ? state.patients
                            : (state is PatientsLoadingMore)
                                ? state.patients
                                : (state as PatientsCountLoaded).patients;

                        if (patients.isEmpty) {
                          return Center(
                            child: Text('noPatientsMatchsMatch'.tr()),
                          );
                        }

                        // Group patients by creation date
                        final groupedPatients = <String, List<PatientModel>>{};
                        for (var patient in patients) {
                          if (patient.createdAt != null) {
                            final creationDate = DateFormat('yyyy-MM-dd')
                                .format(patient.createdAt!.toDate());
                            groupedPatients
                                .putIfAbsent(creationDate, () => [])
                                .add(patient);
                          } else {
                            groupedPatients
                                .putIfAbsent('Unknown', () => [])
                                .add(patient);
                          }
                        }

                        // Sort grouped sessions by date in descending order
                        final sortedGroupedPatients = groupedPatients.entries
                            .toList()
                          ..sort((a, b) => b.key.compareTo(a.key));

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.people,
                                      size: 20, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${patients.length} ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                  ),
                                  Text(
                                    'patientsLoaded'.tr(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  if (_firestorePatientsCount != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(Icons.cloud,
                                        size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$_firestorePatientsCount',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                    ),
                                    Text(
                                      ' ${'storedPatients'.tr()} ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: sortedGroupedPatients.length,
                                itemBuilder: (context, index) {
                                  final dateKey =
                                      sortedGroupedPatients[index].key;
                                  final patientsForDate =
                                      sortedGroupedPatients[index].value;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Text(
                                          _getDateLabel(dateKey),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ),
                                      ...patientsForDate.map((patient) {
                                        return Container(
                                          color: !navState
                                                      .isNavigationFocused &&
                                                  _selectedIndex ==
                                                      patients.indexOf(patient)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.2)
                                              : Colors.transparent,
                                          child: PatientListItem(
                                            patientModel: patient,
                                            onTap: () {
                                              setState(() {
                                                _selectedIndex =
                                                    patients.indexOf(patient);
                                              });
                                            },
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                              ),
                            ),
                            if ((state is PatientsLoaded &&
                                    state.isLoadingMore) ||
                                state is PatientsLoadingMore)
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: 50.0,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else if (state is PatientsError) {
                        return Center(child: Text('Error: ${state.message}'));
                      }
                      return Center(child: Text('noPatients'.tr()));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/patients/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Returns a human-readable label for a given date string.
  String _getDateLabel(String date) {
    final today = DateTime.now();
    final parsedDate = DateTime.parse(date);
    if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day) {
      return 'today'.tr(); // Use translation for 'Today'
    } else if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day - 1) {
      return 'yesterday'.tr(); // Use translation for 'Yesterday'
    } else {
      return DateFormat('MMMM dd, yyyy', context.locale.toString())
          .format(parsedDate);
    }
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
}
