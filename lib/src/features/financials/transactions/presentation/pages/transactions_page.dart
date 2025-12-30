import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  bool _canLoadMore = true; // Add a flag to control loading more sessions
  int? _firestoreTransactionsCount;

  void _dispatchGetTransactionsCount() {
    final clinicId = OwnerNotifier().clinicId;
    if (clinicId != null) {
      context.read<TransactionsBloc>().add(GetTransactionsCount(clinicId));
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('TransactionsPage: initState called');
    _scrollController.addListener(_onScroll);
    debugPrint('TransactionsPage: Scroll listener added');
    final clinicId = OwnerNotifier().clinicId;
    if (clinicId != null) {
      context.read<TransactionsBloc>().add(GetTransactions(clinicId: clinicId));
    }
    _dispatchGetTransactionsCount();
  }

  @override
  void dispose() {
    debugPrint('TransactionsPage: dispose called');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only trigger when scrolling down and near the end
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<TransactionsBloc>().state;
      debugPrint(
        'TransactionsPage: _onScroll triggered. State: ${state.runtimeType}',
      );
      if (state is TransactionsLoaded || state is TransactionsCountLoaded) {
        // Only TransactionsLoaded has isLoadingMore
        final isLoadingMore =
            state is TransactionsLoaded ? state.isLoadingMore : false;
        debugPrint(
          'TransactionsPage: State is ${state.runtimeType}, isLoadingMore: $isLoadingMore',
        );
        if (!isLoadingMore) {
          debugPrint('TransactionsPage: _canLoadMore is $_canLoadMore');
          if (_canLoadMore) {
            _canLoadMore = false;
            final transactions = state is TransactionsLoaded
                ? state.transactions
                : (state as TransactionsCountLoaded).transactions;
            debugPrint(
              'TransactionsPage: Dispatching LoadMoreTransactions event',
            );
            final clinicId = OwnerNotifier().clinicId;
            if (clinicId != null) {
              context.read<TransactionsBloc>().add(
                    LoadMoreTransactions(
                      clinicId: clinicId,
                      lastDocumentId: transactions.last.id,
                      limit: 20,
                    ),
                  );
            }
            Future.delayed(const Duration(seconds: 1), () {
              _canLoadMore = true;
            });
          }
        } else {
          debugPrint(
            'TransactionsPage: isLoadingMore is true, not dispatching',
          );
        }
      } else {
        debugPrint(
          'TransactionsPage: State is not TransactionsLoaded/TransactionsCountLoaded, not dispatching',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final navMenuButton = NavMenuButtonProvider.of(context); // removed unused
    // final isMobile = ScreenSizeHelper.isSmall(context); // removed unused logic derived from isMobile
    return Scaffold(
      // Removed AppBar
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Filter Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                // border: Border(
                //   bottom: BorderSide(
                //     color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                //   ),
                // ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Focus(
                        focusNode: _searchFocusNode,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'searchTransactions'.tr(),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).hintColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                          onChanged: (newQuery) {
                            setState(() {
                              query = newQuery;
                              _selectedIndex =
                                  0; // Reset selection on new query
                            });
                            final clinicId = OwnerNotifier().clinicId;
                            if (clinicId != null) {
                              context.read<TransactionsBloc>().add(
                                    SearchTransactions(
                                        description: query, clinicId: clinicId),
                                  );
                            }
                          },
                          onSubmitted: (_) {
                            _listFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_alt_off
                              : Icons.filter_alt,
                          color: _showFilters
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).iconTheme.color,
                        ),
                        tooltip: 'toggleFilters'.tr(),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'refresh'.tr(),
                      onPressed: () {
                        setState(() {
                          query = '';
                          _selectedDate = null;
                        });
                        final clinicId = OwnerNotifier().clinicId;
                        if (clinicId != null) {
                          context.read<TransactionsBloc>().add(
                                GetTransactions(clinicId: clinicId),
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Filter Options (Date Picker)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _selectedDate != null
                                  ? _selectedDate!.toLocal().toString().split(
                                        ' ',
                                      )[0]
                                  : 'filterByDate'.tr(),
                            ),
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
                                final clinicId = OwnerNotifier().clinicId;
                                if (clinicId != null) {
                                  context.read<TransactionsBloc>().add(
                                        GetTransactionsByDate(
                                            date: selectedDate,
                                            clinicId: clinicId),
                                      );
                                }
                              }
                            },
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                                final clinicId = OwnerNotifier().clinicId;
                                if (clinicId != null) {
                                  context.read<TransactionsBloc>().add(
                                        GetTransactions(clinicId: clinicId),
                                      );
                                }
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Transactions List
            Expanded(
              child: BlocListener<TransactionsBloc, TransactionsState>(
                listener: (context, state) {
                  if (state is TransactionsSuccess) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  } else if (state is TransactionsError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
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
                        baseColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        highlightColor: Theme.of(context).colorScheme.surface,
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Container(
                              height: 80.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'noTransactionsMatch'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group transactions
                      final groupedTransactions =
                          <String, List<TransactionModel>>{};
                      for (var transaction in transactions) {
                        final creationDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(transaction.transactionDate.toDate());
                        groupedTransactions
                            .putIfAbsent(creationDate, () => [])
                            .add(transaction);
                      }

                      final sortedGroupedTransactions =
                          groupedTransactions.entries.toList()
                            ..sort((a, b) => b.key.compareTo(a.key));

                      return Column(
                        children: [
                          // Count Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${transactions.length} ${'loaded'.tr()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                                if (_firestoreTransactionsCount != null)
                                  Text(
                                    '$_firestoreTransactionsCount ${'stored'.tr()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: sortedGroupedTransactions.length,
                              itemBuilder: (context, index) {
                                final dateKey =
                                    sortedGroupedTransactions[index].key;
                                final transactionsForDate =
                                    sortedGroupedTransactions[index].value;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        16,
                                        24,
                                        8,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _getDateLabel(dateKey),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Divider(
                                              color: Theme.of(context)
                                                  .dividerColor
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...transactionsForDate.map((transaction) {
                                      return TransactionListItem(
                                        transaction: transaction,
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex = transactions
                                                .indexOf(transaction);
                                          });
                                          // TODO: Add proper deletion confirmation or edit
                                          // context.read<TransactionsBloc>().add(
                                          //   DeleteTransactionEvent(
                                          //     transaction.id,
                                          //   ),
                                          // );
                                        },
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (state is TransactionsLoaded &&
                                  state.isLoadingMore ||
                              state is TransactionsLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      );
                    } else if (state is TransactionsError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    return Center(child: Text('TransactionsFound'.tr()));
                  },
                ),
              ),
            ),
          ],
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
    return DateFormat(
      'EEEE, MMMM dd, yyyy',
      context.locale.toString(),
    ).format(parsedDate ?? DateTime.now());
  }
}
