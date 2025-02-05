import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A page that displays a list of patients and allows searching through them.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final List<String> patients = [
    'أحمد',
    'محمد',
    'علي',
    'يوسف',
    'إبراهيم',
    'خالد',
    'سعيد',
    'عبدالله',
    'حسن',
    'عمر'
  ]; // Example list of Arabic names

  String query = '';
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _listFocusNode.addListener(() {
      print('List focus node has focus: ${_listFocusNode.hasFocus}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients = patients
        .where((patient) => _normalize(patient).contains(_normalize(query)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Focus(
          focusNode: _searchFocusNode,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search Patients',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
            onChanged: (newQuery) {
              setState(() {
                query = newQuery;
                _selectedIndex = 0; // Reset selection on new query
              });
            },
            onSubmitted: (_) {
              _listFocusNode.requestFocus();
            },
          ),
        ),
      ),
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (!state.isNavigationFocused) {
            _listFocusNode.requestFocus();
          }
          return Container(
            color: Colors.white, // Use a solid color background
            child: Focus(
              focusNode: _listFocusNode,
              autofocus: true,
              onKeyEvent: (FocusNode node, KeyEvent event) {
                print('Key event detected: ${event.logicalKey.keyLabel}'); // Debug print statement
                if (!state.isNavigationFocused) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      print('Arrow Down pressed');
                      moveSelectionDown();
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      print('Arrow Up pressed');
                      moveSelectionUp();
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      _searchFocusNode.requestFocus();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredPatients.length,
                itemBuilder: (context, index) {
                  return Container(
                    color: !state.isNavigationFocused && _selectedIndex == index
                        ? Colors.blue.withAlpha((0.2 * 255).toInt())
                        : Colors.transparent,
                    child: PatientListItem(
                      name: filteredPatients[index], // Use filtered patient names
                      details: 'Details for ${filteredPatients[index]}', // Replace with actual patient data
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void moveSelectionDown() {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % patients.length;
      print('Selected index: $_selectedIndex');
    });
    _scrollController.animateTo(
      _selectedIndex * 50.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void moveSelectionUp() {
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + patients.length) % patients.length;
      print('Selected index: $_selectedIndex');
    });
    _scrollController.animateTo(
      _selectedIndex * 50.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Normalizes Arabic text for better search matching.
  String _normalize(String input) {
    return input
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و');
  }
}
