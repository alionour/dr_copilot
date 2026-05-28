import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:dr_copilot/src/features/doctors/presentation/widgets/doctor_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  String? _currentClinicId;
  late final OwnerNotifier _ownerNotifier;

  @override
  void initState() {
    super.initState();
    _ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = _ownerNotifier.clinicId;
    if (clinicId != null) {
      _currentClinicId = clinicId;
      context.read<DoctorsBloc>().add(GetDoctors(clinicId: clinicId));
    }
    _ownerNotifier.addListener(_onClinicChanged);
  }

  void _onClinicChanged() {
    final clinicId = _ownerNotifier.clinicId;
    if (clinicId != null && clinicId != _currentClinicId) {
      setState(() {
        _currentClinicId = clinicId;
      });
      context.read<DoctorsBloc>().add(GetDoctors(clinicId: clinicId));
    }
  }

  @override
  void dispose() {
    _ownerNotifier.removeListener(_onClinicChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _ownerNotifier.hasPermission(AppPermission.manageDoctors);
    return Scaffold(
      appBar: AppBar(
        title: Text('doctors'.tr()),
        actions: [
          if (canManage)
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
                actionLabel: canManage ? 'addDoctor'.tr() : null,
                onActionPressed: canManage ? () {
                  context.go('/doctors/new');
                } : null,
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
              child: Text(state.message ?? 'anErrorOccurred'.tr()),
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
