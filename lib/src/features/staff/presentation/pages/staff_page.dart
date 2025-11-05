
import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId;
    if (clinicId != null) {
      _currentClinicId = clinicId;
      context.read<StaffBloc>().add(const GetStaff());
    }
    ownerNotifier.addListener(_onClinicChanged);
  }

  void _onClinicChanged() {
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId != null && clinicId != _currentClinicId) {
      setState(() {
        _currentClinicId = clinicId;
      });
      context.read<StaffBloc>().add(const GetStaff());
    }
  }

  @override
  void dispose() {
    context.read<OwnerNotifier>().removeListener(_onClinicChanged);
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
              context.go('/staff/new');
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
                      print('StaffPage BlocBuilder - StaffLoaded state received');
                      final filteredStaff = state.staff.where((staff) => staff.clinicId == _currentClinicId).toList();
                      print('StaffPage BlocBuilder - Filtered staff: $filteredStaff');
                      if (filteredStaff.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('noStaffFound'.tr()),
                              const SizedBox(height: 16.0),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.go('/staff/new');
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
                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text(staff.name),
                                    subtitle: Text(staff.role),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        context.go('/staff/${staff.id}/edit');
                                      },
                                    ),
                                    onTap: () {
                                      // Optionally navigate to staff details page
                                    },
                                  ),
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
