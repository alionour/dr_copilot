import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String query = '';
  DateTime? selectedDate; // Add selectedDate variable
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  bool _showFilters = false; // State to toggle filter icons
  DateTime? _selectedDate;
  bool _canLoadMore = true; // Add a flag to control loading more sessions
  int? _firestoreTransactionsCount;

  void _dispatchGetSessionsCount() {
    context.read<TransactionsBloc>().add(const GetTransactionsCount());
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TransactionsBloc>().add(const GetTransactions());
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
      final state = context.read<TransactionsBloc>().state;
      if (state is TransactionsLoaded && !state.isLoadingMore) {
        if (_canLoadMore) {
          _canLoadMore = false;
          context.read<TransactionsBloc>().add(LoadMoreTransactions(
                lastDocumentId: state.transactions.last.id,
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
    final isMobile = ScreenSizeHelper.isSmall(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (!(isMobile && _showFilters))
              Expanded(
                child: Focus(
                  focusNode: _searchFocusNode,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'searchTransactions'.tr(),
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.onSurface),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 0.3),
                      ),
                      hintStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    onChanged: (newQuery) {
                      setState(() {
                        query = newQuery;
                        _selectedIndex = 0; // Reset selection on new query
                      });
                      context.read<TransactionsBloc>().add(
                          SearchTransactions(query)); // Trigger search event
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
                context.read<TransactionsBloc>().add(const GetTransactions());
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
                              .read<TransactionsBloc>()
                              .add(GetTransactionsByDate(date: selectedDate));
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
      body: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionsSuccess) {
            final message = state.message;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          } else if (state is TransactionsError) {
            final message = state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          } else if (state is TransactionsCountLoaded) {
            setState(() {
              _firestoreTransactionsCount = state.count;
            });
          }
        },
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            if (state is TransactionsLoading) {
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
            } else if (state is TransactionsLoaded ||
                state is TransactionsLoadingMore ||
                state is TransactionsCountLoaded) {
              final transactions = (state is TransactionsLoaded)
                  ? state.transactions
                  : (state is TransactionsLoadingMore)
                      ? state.transactions
                      : (state as TransactionsCountLoaded).transactions;

              if (transactions.isEmpty) {
                return Center(
                  child: Text('noTransactionsMatch'.tr()),
                );
              }

              // Group transactions by creation date
              final groupedTransactions = <String, List<TransactionModel>>{};
              for (var session in transactions) {
                final creationDate = DateFormat('yyyy-MM-dd')
                    .format(session.transactionDate.toDate());
                groupedTransactions
                    .putIfAbsent(creationDate, () => [])
                    .add(session);
              }

              // Sort grouped transactions by date in descending order
              final sortedGroupedTransactions = groupedTransactions.entries
                  .toList()
                ..sort((a, b) => b.key.compareTo(a.key));

              return Column(
                children: [
                  // Add a label to show the total number of transactions (like patients_page)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment, size: 20, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${transactions.length} ',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                        ),
                        Text(
                          'loaded'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_firestoreTransactionsCount != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.cloud, size: 18, color: Colors.deepPurple),
                          const SizedBox(width: 2),
                          Text(
                            '$_firestoreTransactionsCount',
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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ]
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: sortedGroupedTransactions.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedGroupedTransactions[index].key;
                        final transactionsForDate =
                            sortedGroupedTransactions[index].value;

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
                            ...transactionsForDate.map((session) {
                              return TransactionListItem(
                                transaction: session,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex =
                                        transactions.indexOf(session);
                                  });
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                  if (state is TransactionsLoaded && state.isLoadingMore ||
                      state is TransactionsLoadingMore)
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
            } else if (state is TransactionsError) {
              debugPrint('Error: ${state.message}');

              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('TransactionsFound'.tr()));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/transactions/new');
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
