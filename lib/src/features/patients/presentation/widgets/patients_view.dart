import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';

/// A pure UI widget that displays a list of patients.
/// Decoupled from BLoC and State management for easier testing/screenshots.
class PatientsView extends StatefulWidget {
  final List<PatientModel> patients;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final Function(String query)? onSearch;
  final Function()? onRefresh;
  final Function()? onLoadMore;
  final Function()? onAddPatient;
  // Filter callbacks
  final Function(DateTime date)? onFilterDate;
  final Function(String gender)? onFilterGender;
  final Function(int min, int max)? onFilterAge;
  final Function(String address)? onFilterAddress;

  const PatientsView({
    super.key,
    required this.patients,
    required this.totalCount,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.onSearch,
    this.onRefresh,
    this.onLoadMore,
    this.onAddPatient,
    this.onFilterDate,
    this.onFilterGender,
    this.onFilterAge,
    this.onFilterAddress,
  });

  @override
  State<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<PatientsView> {
  String query = '';
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = false;

  // Filter state for UI display only

  bool _canLoadMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    // Simple load more trigger
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore && widget.onLoadMore != null && _canLoadMore) {
        _canLoadMore = false;
        widget.onLoadMore!();
        Future.delayed(const Duration(seconds: 1), () => _canLoadMore = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mocking NavMenuButtonProvider dependent behavior or removing it for 'dumb' view.
    // Assuming this widget is wrapped by something that might provide it, or we make it optional.
    // For screenshot purposes, we might not need the menu button inside the view if it comes from the layout.

    final screenSize = ScreenSizeHelper.getScreenSize(context);
    final isMobile = screenSize == ScreenSize.small;

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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (val) {
                    setState(() => query = val);
                    widget.onSearch?.call(val);
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showfilterSheet, // Extracted method
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRefresh,
            ),
            // Desktop filters
            if (!isMobile) _buildDesktopFilterBar(),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddPatient ?? () => context.push('/patients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const ShimmerList(itemCount: 8);
    }
    if (widget.errorMessage != null) {
      return Center(child: Text('Error: ${widget.errorMessage}'));
    }

    if (widget.patients.isEmpty) {
      return EmptyStateWidget(
        message: 'noPatientsMatchsMatch'.tr(), // Typo in original key preserved
        title: 'noResultsFound'.tr(),
        actionLabel: 'addPatient'.tr(),
        onActionPressed: widget.onAddPatient,
      );
    }

    // Grouping Logic (Preserved)
    final groupedPatients = <String, List<PatientModel>>{};
    for (var patient in widget.patients) {
      if (patient.createdAt != null) {
        final creationDate =
            DateFormat('yyyy-MM-dd').format(patient.createdAt!.toDate());
        groupedPatients.putIfAbsent(creationDate, () => []).add(patient);
      } else {
        groupedPatients.putIfAbsent('Unknown', () => []).add(patient);
      }
    }
    final sortedGroupedPatients = groupedPatients.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        _buildCountHeader(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: sortedGroupedPatients.length,
            itemBuilder: (context, index) {
              final dateKey = sortedGroupedPatients[index].key;
              final patientsForDate = sortedGroupedPatients[index].value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text(_getDateLabel(dateKey),
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  ...patientsForDate
                      .map((patient) => _buildPatientListItem(patient)),
                ],
              );
            },
          ),
        ),
        if (widget.isLoadingMore) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildCountHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.blue),
          Text(' ${widget.patients.length} ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          Text('loaded'.tr()),
          const Spacer(),
          const Icon(Icons.cloud, color: Colors.deepPurple),
          Text(' ${widget.totalCount} ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          Text('stored'.tr()),
        ],
      ),
    );
  }

  Widget _buildPatientListItem(PatientModel patient) {
    return PatientListItem(
      patientModel: patient,
      onTap: () {
        setState(() {
          // Simple index tracking for selection visualization
          // Just toggling selection style if needed
        });
      },
    );
  }

  String _getDateLabel(String date) {
    if (date == 'Unknown') return 'Unknown';
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
    }
    return DateFormat('MMMM dd, yyyy', context.locale.toString())
        .format(parsedDate);
  }

  void _showfilterSheet() {
    // Implementation of filter sheet...
    // For screenshot purposes, we might not trigger this.
    // Leaving empty or simplified for now as strictly UI testing doesn't need interactive filters usually.
  }

  Widget _buildDesktopFilterBar() {
    // Simplified desktop filter bar
    return Row(children: [
      IconButton(
        icon: const Icon(Icons.filter_alt),
        onPressed: () => setState(() => _showFilters = !_showFilters),
      ),
      if (_showFilters) ...[
        // Filter icons...
      ]
    ]);
  }
}
