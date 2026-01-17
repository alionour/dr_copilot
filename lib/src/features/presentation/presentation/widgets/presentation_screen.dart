import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/presentation/presentation/widgets/video_player_widget.dart';
import 'package:dr_copilot/src/features/presentation/presentation/widgets/waiting_list_widget.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

class PresentationScreen extends StatefulWidget {
  final String windowId;
  final Map<String, dynamic>? arguments;

  const PresentationScreen({
    super.key,
    required this.windowId,
    this.arguments,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  List<dynamic> _scheduleItems = [];

  @override
  void initState() {
    super.initState();
    _initWindow();
  }

  Future<void> _initWindow() async {
    // Set window title and size
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Dr. Copilot - Patient Calling Screen');
    await windowManager.setSize(const Size(1280, 720));
    await windowManager.center();

    final controller = await WindowController.fromCurrentEngine();
    controller.setWindowMethodHandler((call) async {
      if (call.method == 'update_schedule') {
        if (call.arguments is List) {
          setState(() {
            _scheduleItems = call.arguments as List<dynamic>;
          });
        }
        debugPrint('Schedule update received: ${call.arguments}');
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Left Side: Video Player (Entertainment)
          Expanded(
            flex: 7,
            child: VideoPlayerWidget(),
          ),
          // Right Side: Waiting List (Queue Info)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: WaitingListWidget(scheduleItems: _scheduleItems),
            ),
          ),
        ],
      ),
    );
  }
}
