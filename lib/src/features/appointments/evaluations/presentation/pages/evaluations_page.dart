import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/widgets/evaluation_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class EvaluationsPage extends StatefulWidget {
  const EvaluationsPage({super.key});

  @override
  State<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends State<EvaluationsPage> {
  String query = '';
  DateTime? selectedDate; // Add selectedDate variable
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  bool _showFilters = false; // State to toggle filter icons
  DateTime? _selectedDate;
  bool _canLoadMore = true; // Add a flag to control loading more evaluations

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context
        .read<EvaluationsBloc>()
        .add(const GetEvaluations()); // Fetch evaluations on init
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
      final state = context.read<EvaluationsBloc>().state;
      if (state is EvaluationsLoaded && !state.isLoadingMore) {
        if (_canLoadMore) {
          _canLoadMore = false;
          context.read<EvaluationsBloc>().add(LoadMoreEvaluations(
                lastDocumentId: state.evaluations.last.id,
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Focus(
                focusNode: _searchFocusNode,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchEvaluations'.tr(),
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
                    context.read<EvaluationsBloc>().add(
                        SearchEvaluations(name: query)); // Trigger search event
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
                context.read<EvaluationsBloc>().add(const GetEvaluations());
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
                              .read<EvaluationsBloc>()
                              .add(GetEvaluationsByDate(date: selectedDate));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<EvaluationsBloc, EvaluationsState>(
        listener: (context, state) {
          if (state is EvaluationsSuccess) {
            final message = state.message;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                ),
              );
            }
          } else if (state is EvaluationsError) {
            final message = state.message;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          }
        },
        child: BlocBuilder<EvaluationsBloc, EvaluationsState>(
          builder: (context, state) {
            if (state is EvaluationsLoading) {
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
            } else if (state is EvaluationsLoaded ||
                state is EvaluationsLoadingMore) {
              final evaluations = state is EvaluationsLoaded
                  ? state.evaluations
                  : (state as EvaluationsLoadingMore).evaluations;

              if (evaluations.isEmpty) {
                return Center(
                  child: Text('noEvaluationsMatch'.tr()),
                );
              }

              // Group evaluations by creation date
              final groupedEvaluations = <String, List<EvaluationModel>>{};
              for (var evaluation in evaluations) {
                  final creationDate = DateFormat('yyyy-MM-dd')
                      .format(evaluation.startDateTime.toDate());
                  groupedEvaluations
                      .putIfAbsent(creationDate, () => [])
                      .add(evaluation);
            
              }

              // Sort grouped evaluations by date in descending order
              final sortedGroupedEvaluations = groupedEvaluations.entries
                  .toList()
                ..sort((a, b) => b.key.compareTo(a.key));

              return ListView.builder(
                controller: _scrollController,
                itemCount: sortedGroupedEvaluations.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedGroupedEvaluations[index].key;
                  final evaluationsForDate =
                      sortedGroupedEvaluations[index].value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          _getDateLabel(dateKey),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      ...evaluationsForDate.map((evaluation) {
                        return EvaluationListItem(
                          evaluationModel: evaluation,
                          onTap: () {
                            setState(() {
                              _selectedIndex = evaluations.indexOf(evaluation);
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              );
            } else if (state is EvaluationsError) {
              debugPrint('Error: ${state.message}');
              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('noEvaluations'.tr()));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/evaluations/new');
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
    final parsedDate = DateTime.parse(dateKey);

    if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day) {
      return 'Today';
    } else if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(parsedDate);
    }
  }
}
