import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:dr_copilot/src/features/staff/presentation/widgets/staff_list_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  String? _currentClinicId;
  late final OwnerNotifier _ownerNotifier;

  @override
  void initState() {
    super.initState();
    _ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = _ownerNotifier.clinicId;
    if (clinicId != null) {
      _currentClinicId = clinicId;
      context.read<StaffBloc>().add(GetStaff(clinicId: clinicId));
    }
    _ownerNotifier.addListener(_onClinicChanged);
  }

  void _onClinicChanged() {
    final clinicId = _ownerNotifier.clinicId;
    if (clinicId != null && clinicId != _currentClinicId) {
      setState(() {
        _currentClinicId = clinicId;
      });
      context.read<StaffBloc>().add(GetStaff(clinicId: clinicId));
    }
  }

  @override
  void dispose() {
    _ownerNotifier.removeListener(_onClinicChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('staff'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/staff/add');
            },
          ),
        ],
      ),
      body: BlocBuilder<StaffBloc, StaffState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is StaffLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is StaffLoaded) {
                      final filteredStaff = state.staff
                          .where((staff) => staff.clinicId == _currentClinicId)
                          .toList();

                      if (filteredStaff.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('noStaffFound'.tr()),
                              const SizedBox(height: 16.0),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.go('/staff/add');
                                },
                                icon: const Icon(Icons.add),
                                label: Text('addStaff'.tr()),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return StaffListItem(
                                  staffModel: staff,
                                  onTap: () {
                                    // Optionally navigate to staff details page
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else if (state is StaffError) {
                      return Center(child: Text('An error occurred'.tr()));
                    } else {
                      return Center(child: Text('noStaffFound'.tr()));
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
