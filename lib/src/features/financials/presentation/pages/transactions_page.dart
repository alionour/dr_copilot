import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/transaction_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      debugPrint('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
    context
        .read<FinancialsBloc>()
        .add(GetTransactionsEvent()); // Fetch sessions on init
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
                    context.read<FinancialsBloc>().add(
                        SearchTransactionsEvent(query)); // Trigger search event
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
                context
                    .read<FinancialsBloc>()
                    .add(const GetTransactionsEvent());
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
                              .read<FinancialsBloc>()
                              .add(GetTransactionsByDate(date: selectedDate));
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
      body: BlocListener<FinancialsBloc, FinancialsState>(
        listener: (context, state) {
          if (state is FinancialsSuccess) {
            final message = state.message;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          } else if (state is FinancialsError) {
            final message = state.message;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        child: BlocBuilder<FinancialsBloc, FinancialsState>(
          builder: (context, state) {
            if (state is FinancialsLoading) {
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
                state is TransactionsLoadingMore) {
              final transactions = state is TransactionsLoaded
                  ? state.transactions
                  : (state as TransactionsLoadingMore).transactions;

              if (transactions.isEmpty) {
                return Center(
                  child: Text('noTransactionsMatch'.tr()),
                );
              }

              // Group transactions by creation date
              final groupedTransactions = <String, List<TransactionModel>>{};
              for (var transaction in transactions) {
                
                  final creationDate = DateFormat('yyyy-MM-dd')
                      .format(transaction.createdAt.toDate());
                  groupedTransactions
                      .putIfAbsent(creationDate, () => [])
                      .add(transaction);
                
              }

              // Sort grouped transactions by date in descending order
              final sortedGroupedTransactions = groupedTransactions.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key));

              return ListView.builder(
                controller: _scrollController,
                itemCount: sortedGroupedTransactions.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedGroupedTransactions[index].key;
                  final transactionsForDate = sortedGroupedTransactions[index].value;

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
                      ...transactionsForDate.map((transaction) {
                        return TransactionListItem(
                          transaction: transaction,
                          onTap: () {
                            setState(() {
                              _selectedIndex = transactions.indexOf(transaction);
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              );
            } else if (state is FinancialsError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('noTransactionsFound'.tr()));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add_transaction');
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
        return 'Today';
      } else if (parsedDate.year == yesterday.year &&
          parsedDate.month == yesterday.month &&
          parsedDate.day == yesterday.day) {
        return 'Yesterday';
      }
    }
    return dateKey;
  }
}
