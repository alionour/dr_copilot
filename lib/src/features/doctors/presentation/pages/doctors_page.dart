import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('noDoctorsFound'.tr()),
                    const SizedBox(height: 16.0),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/doctors/new');
                      },
                      icon: const Icon(Icons.add),
                      label: Text('addDoctor'.tr()),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.doctors.length,
              itemBuilder: (context, index) {
                final doctor = state.doctors[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(doctor.name),
                    subtitle: Text(doctor.specialty),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.go('/doctors/${doctor.id}/edit');
                      },
                    ),
                    onTap: () {
                      // Optionally navigate to doctor details page
                    },
                  ),
                );
              },
            );
          } else if (state is DoctorsError) {
            return Center(
                child: Text(state.message ?? 'An error occurred'.tr()));
          }
          return Center(child: Text('noDoctorsFound'.tr()));
        },
      ),
    );
  }
}
