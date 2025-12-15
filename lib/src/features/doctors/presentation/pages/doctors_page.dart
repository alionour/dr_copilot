import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:dr_copilot/src/features/doctors/presentation/widgets/doctor_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorsBloc>().add(const GetDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('doctors'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/doctors/new');
            },
          ),
        ],
      ),
      body: BlocBuilder<DoctorsBloc, DoctorsState>(
        builder: (context, state) {
          if (state is DoctorsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DoctorsLoaded) {
            if (state.doctors.isEmpty) {
              return EmptyStateWidget(
                message: 'noDoctorsFound'.tr(),
                title: 'noDoctors'.tr(),
                actionLabel: 'addDoctor'.tr(),
                onActionPressed: () {
                  context.go('/doctors/new');
                },
              );
            }
            return ListView.builder(
              itemCount: state.doctors.length,
              itemBuilder: (context, index) {
                final doctor = state.doctors[index];
                return DoctorListItem(
                  doctorModel: doctor,
                  onTap: () {
                    // Optionally navigate to doctor details page
                  },
                );
              },
            );
          } else if (state is DoctorsError) {
            return Center(
              child: Text(state.message ?? 'An error occurred'.tr()),
            );
          }
          return EmptyStateWidget(
            message: 'noDoctorsFound'.tr(),
            title: 'noDoctors'.tr(),
          );
        },
      ),
    );
  }
}

