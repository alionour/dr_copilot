import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/bloc/recycle_bin_bloc.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/deleted_calendar_events_widget.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/deleted_evaluations_widget.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/deleted_patients_widget.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/deleted_sessions_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecycleBinBloc>()..add(LoadDeletedItems()),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('recycleBin'.tr()),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(
                  icon: const Icon(Icons.people),
                  text: 'deletedPatients'.tr(),
                ),
                Tab(
                  icon: const Icon(Icons.calendar_today),
                  text: 'deletedSessions'.tr(),
                ),
                Tab(
                  icon: const Icon(Icons.assignment),
                  text: 'deletedEvaluations'.tr(),
                ),
                Tab(
                  icon: const Icon(Icons.event),
                  text: 'deletedCalendarEvents'.tr(),
                ),
              ],
            ),
          ),
          body: BlocConsumer<RecycleBinBloc, RecycleBinState>(
            listener: (context, state) {
              if (state is RecycleBinError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: SelectionArea(child: Text(state.message))),
                );
              }
            },
            builder: (context, state) {
              if (state is RecycleBinLoading) {
                return const ShimmerList();
              } else if (state is RecycleBinLoaded) {
                return TabBarView(
                  children: [
                    DeletedPatientsWidget(patients: state.deletedPatients),
                    DeletedSessionsWidget(sessions: state.deletedSessions),
                    DeletedEvaluationsWidget(
                      evaluations: state.deletedEvaluations,
                    ),
                    DeletedCalendarEventsWidget(
                      calendarEvents: state.deletedCalendarEvents,
                    ),
                  ],
                );
              }
              return Center(child: Text('somethingWentWrong'.tr()));
            },
          ),
        ),
      ),
    );
  }
}
