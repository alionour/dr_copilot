import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';

/// A page that displays a list of patients and allows searching through them.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  /// The current search query.
  String query = '';
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;
  bool _showFilters = false;

  // Filter states
  DateTime? _selectedDate;
  String? _selectedGender;
  int? _minAge;
  int? _maxAge;
  String? _selectedAddress;

  /// Whether more patients can be loaded (pagination).
  bool _canLoadMore = true;

  /// The total count of patients fetched from Firestore.
  int? _firestorePatientsCount;

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      debugPrint('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
    _scrollController.addListener(_onScroll);

    context.read<OwnerNotifier>().addListener(_onOwnerNotifierChanged);

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

  void _onOwnerNotifierChanged() {
    if (mounted) {
      context.read<PatientsBloc>().add(const GetPatients());
      context.read<PatientsBloc>().add(GetPatientsCount());
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<PatientsBloc>().state;
      if (state is PatientsLoaded && !state.isLoadingMore) {
        if (_canLoadMore) {
          _canLoadMore = false;
          context.read<PatientsBloc>().add(
                LoadMorePatients(
                    lastDocumentId: state.patients.last.id, limit: 20),
              );
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
    final screenSize = ScreenSizeHelper.getScreenSize(context);
    final isMobile = screenSize == ScreenSize.small;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (!isMobile)
              Expanded(
                child: Focus(
                  focusNode: _searchFocusNode,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'searchPatients'.tr(),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 0.3,
                        ),
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (newQuery) {
                      setState(() {
                        query = newQuery;
                        _selectedIndex = 0;
                      });
                      context.read<PatientsBloc>().add(
                            SearchPatients(name: query),
                          );
                    },
                    onSubmitted: (_) {
                      _listFocusNode.requestFocus();
                    },
                  ),
                ),
              ),
            if (isMobile) ...[
              Expanded(
                child: Focus(
                  focusNode: _searchFocusNode,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'searchPatients'.tr(),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 0.3,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (newQuery) {
                      setState(() {
                        query = newQuery;
                        _selectedIndex = 0;
                      });
                      context.read<PatientsBloc>().add(
                            SearchPatients(name: query),
                          );
                    },
                    onSubmitted: (_) {
                      _listFocusNode.requestFocus();
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'filters'.tr(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedDate != null
                                      ? _selectedDate!
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0]
                                      : 'filterByDate'.tr(),
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
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
                                      _selectedAddress = null;
                                    });
                                    if (!context.mounted) return;
                                    context.read<PatientsBloc>().add(
                                          GetPatientsByDate(
                                            year: selectedDate.year,
                                            month: selectedDate.month,
                                          ),
                                        );
                                  }
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.male, size: 18),
                                label: Text('male'.tr()),
                                backgroundColor: _selectedGender == 'Male'
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedGender = 'Male';
                                    _selectedDate = null;
                                    _minAge = null;
                                    _maxAge = null;
                                    _selectedAddress = null;
                                  });
                                  context.read<PatientsBloc>().add(
                                        SearchPatients(gender: 'Male'),
                                      );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.female, size: 18),
                                label: Text('female'.tr()),
                                backgroundColor: _selectedGender == 'Female'
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedGender = 'Female';
                                    _selectedDate = null;
                                    _minAge = null;
                                    _maxAge = null;
                                    _selectedAddress = null;
                                  });
                                  context.read<PatientsBloc>().add(
                                        SearchPatients(gender: 'Female'),
                                      );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.numbers, size: 18),
                                label: Text(
                                  (_minAge != null || _maxAge != null)
                                      ? '${_minAge ?? ''}-${_maxAge ?? ''}'
                                      : 'filterByAge'.tr(),
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // Re-use the existing dialog logic, but we need to duplicate it or extract it.
                                  // For now, I'll just copy the dialog logic here for simplicity in this replacement.
                                  final minAgeController =
                                      TextEditingController();
                                  final maxAgeController =
                                      TextEditingController();
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
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(
                                                    r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)',
                                                  ),
                                                ),
                                              ],
                                              decoration: InputDecoration(
                                                hintText: 'minAge'.tr(),
                                              ),
                                            ),
                                            TextField(
                                              controller: maxAgeController,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(
                                                    r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)',
                                                  ),
                                                ),
                                              ],
                                              decoration: InputDecoration(
                                                hintText: 'maxAge'.tr(),
                                              ),
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
                                              final minAge = int.tryParse(
                                                minAgeController.text,
                                              );
                                              final maxAge = int.tryParse(
                                                maxAgeController.text,
                                              );
                                              if ((minAge != null &&
                                                      minAge >= 0) ||
                                                  (maxAge != null &&
                                                      maxAge <= 130)) {
                                                setState(() {
                                                  _minAge = minAge;
                                                  _maxAge = maxAge;
                                                  _selectedDate = null;
                                                  _selectedGender = null;
                                                  _selectedAddress = null;
                                                });
                                                context
                                                    .read<PatientsBloc>()
                                                    .add(
                                                      SearchPatients(
                                                        minAge: minAge,
                                                        maxAge: maxAge,
                                                      ),
                                                    );
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
                              ActionChip(
                                avatar: const Icon(Icons.location_on, size: 18),
                                label: Text(
                                  _selectedAddress ?? 'filterByAddress'.tr(),
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final addressController =
                                      TextEditingController();
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('filterByAddress'.tr()),
                                        content: TextField(
                                          controller: addressController,
                                          decoration: InputDecoration(
                                            hintText: 'enterAddress'.tr(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text('cancel'.tr()),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              final address =
                                                  addressController.text;
                                              if (address.isNotEmpty) {
                                                setState(() {
                                                  _selectedAddress = address;
                                                  _selectedDate = null;
                                                  _selectedGender = null;
                                                  _minAge = null;
                                                  _maxAge = null;
                                                });
                                                context
                                                    .read<PatientsBloc>()
                                                    .add(
                                                      SearchPatients(
                                                        address: address,
                                                      ),
                                                    );
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
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
            if (!isMobile)
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_alt),
                          tooltip: 'toggleFilters'.tr(),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                        if (_showFilters) ...[
                          IconButton(
                            icon: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined),
                                if (_selectedDate != null)
                                  Text(
                                    _selectedDate!.toLocal().toString().split(
                                          ' ',
                                        )[0],
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
                                  _selectedAddress = null;
                                });
                                if (!context.mounted) return;
                                context.read<PatientsBloc>().add(
                                      GetPatientsByDate(
                                        year: selectedDate.year,
                                        month: selectedDate.month,
                                      ),
                                    );
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
                                _selectedAddress = null;
                              });
                              context.read<PatientsBloc>().add(
                                    SearchPatients(gender: 'Male'),
                                  );
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
                                _selectedAddress = null;
                              });
                              context.read<PatientsBloc>().add(
                                    SearchPatients(gender: 'Female'),
                                  );
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
                                            FilteringTextInputFormatter.allow(
                                              RegExp(
                                                r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)',
                                              ),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: 'minAge'.tr(),
                                          ),
                                        ),
                                        TextField(
                                          controller: maxAgeController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            FilteringTextInputFormatter.allow(
                                              RegExp(
                                                r'^(?:1[0-2][0-9]|1[0-2][0]|[1-9]?[0-9]|130)',
                                              ),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: 'maxAge'.tr(),
                                          ),
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
                                          final minAge = int.tryParse(
                                            minAgeController.text,
                                          );
                                          final maxAge = int.tryParse(
                                            maxAgeController.text,
                                          );
                                          if ((minAge != null && minAge >= 0) ||
                                              (maxAge != null &&
                                                  maxAge <= 130)) {
                                            setState(() {
                                              _minAge = minAge;
                                              _maxAge = maxAge;
                                              _selectedDate = null;
                                              _selectedGender = null;
                                              _selectedAddress = null;
                                            });
                                            context.read<PatientsBloc>().add(
                                                  SearchPatients(
                                                    minAge: minAge,
                                                    maxAge: maxAge,
                                                  ),
                                                );
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
                                        hintText: 'enterAddress'.tr(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text('cancel'.tr()),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final address =
                                              addressController.text;
                                          if (address.isNotEmpty) {
                                            setState(() {
                                              _selectedAddress = address;
                                              _selectedDate = null;
                                              _selectedGender = null;
                                              _minAge = null;
                                              _maxAge = null;
                                            });
                                            context.read<PatientsBloc>().add(
                                                  SearchPatients(
                                                      address: address),
                                                );
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    } else if (state is PatientsError) {
                      final message = state.message;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
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
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
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
                          return EmptyStateWidget(
                            message: 'noPatientsMatchsMatch'.tr(),
                            title: 'noResultsFound'.tr(),
                          );
                        }

                        final groupedPatients = <String, List<PatientModel>>{};
                        for (var patient in patients) {
                          if (patient.createdAt != null) {
                            final creationDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(patient.createdAt!.toDate());
                            groupedPatients
                                .putIfAbsent(creationDate, () => [])
                                .add(patient);
                          } else {
                            groupedPatients
                                .putIfAbsent('Unknown', () => [])
                                .add(patient);
                          }
                        }

                        final sortedGroupedPatients = groupedPatients.entries
                            .toList()
                          ..sort((a, b) => b.key.compareTo(a.key));

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
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
                                    'loaded'.tr(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  if (_firestorePatientsCount != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.cloud,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),
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
                                      ' ${'stored'.tr()} ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
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
                                          vertical: 8.0,
                                          horizontal: 16.0,
                                        ),
                                        child: Text(
                                          _getDateLabel(dateKey),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
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
                                          child: _buildPatientListItem(patient),
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
                      return EmptyStateWidget(
                        message: 'noPatients'.tr(),
                        title: 'noPatientsFound'.tr(),
                        actionLabel: 'addPatient'.tr(),
                        onActionPressed: () {
                          context.push('/patients/new');
                        },
                      );
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

  String _getDateLabel(String date) {
    final today = DateTime.now();
    final parsedDate = DateTime.parse(date);
    if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day) {
      return 'today'.tr();
    } else if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day - 1) {
      return 'yesterday'.tr();
    } else {
      return DateFormat(
        'MMMM dd, yyyy',
        context.locale.toString(),
      ).format(parsedDate);
    }
  }

  Widget _buildPatientListItem(PatientModel patient) {
    return PatientListItem(
      patientModel: patient,
      onTap: () {
        setState(() {
          _selectedIndex =
              (context.read<PatientsBloc>().state as PatientsLoaded)
                  .patients
                  .indexOf(patient);
        });
      },
    );
  }
}
