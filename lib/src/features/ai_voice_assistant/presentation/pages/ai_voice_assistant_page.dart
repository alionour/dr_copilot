import 'dart:async';
import 'dart:math';

import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/pallete.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/confirmation_card.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/feature_box.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/patient_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AiVoiceAssistantPage extends StatefulWidget {
  const AiVoiceAssistantPage({super.key});

  @override
  State<AiVoiceAssistantPage> createState() => _AiVoiceAssistantPageState();
}

class _AiVoiceAssistantPageState extends State<AiVoiceAssistantPage> {
  final TextEditingController _textController = TextEditingController();
  Timer? _animationTimer;
  List<ChartData> _chartData = [];

  @override
  void initState() {
    super.initState();
    context.read<AiVoiceAssistantBloc>().add(StartAssistantEvent());
    _chartData = _getInitialChartData();
  }

  List<ChartData> _getInitialChartData() {
    return <ChartData>[
      ChartData('1', 5),
      ChartData('2', 5),
      ChartData('3', 5),
      ChartData('4', 5),
      ChartData('5', 5),
    ];
  }

  void _startAnimation() {
    _animationTimer?.cancel(); // Cancel any existing timer
    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _chartData = _getUpdatedChartData();
        });
      }
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    if (mounted) {
      setState(() {
        _chartData = _getInitialChartData();
      });
    }
  }

  List<ChartData> _getUpdatedChartData() {
    final random = Random();
    return <ChartData>[
      ChartData('1', random.nextDouble() * 20 + 5),
      ChartData('2', random.nextDouble() * 30 + 5),
      ChartData('3', random.nextDouble() * 40 + 5),
      ChartData('4', random.nextDouble() * 30 + 5),
      ChartData('5', random.nextDouble() * 20 + 5),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
        actions: [
          BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
            buildWhen: (previous, current) =>
                previous.isTranscriptVisible != current.isTranscriptVisible,
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  context
                      .read<AiVoiceAssistantBloc>()
                      .add(ToggleTranscriptVisibilityEvent());
                },
                icon: Icon(
                  state.isTranscriptVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Section (Jarvis UI)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Pallete.whiteColor,
                    child: Column(
                      children: [
                        ZoomIn(
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: Pallete.assistantCircleColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.mic,
                                  size: 60,
                                  color: Pallete.mainFontColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // chat bubble
                        BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
                          buildWhen: (previous, current) =>
                              previous.recognizedText !=
                                  current.recognizedText ||
                              previous.isTranscriptVisible !=
                                  current.isTranscriptVisible,
                          builder: (context, state) {
                            return Visibility(
                              visible: state.isTranscriptVisible,
                              child: FadeInRight(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                          horizontal: 40)
                                      .copyWith(
                                    top: 30,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Pallete.borderColor,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(20).copyWith(
                                      topLeft: Radius.zero,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Text(
                                      state.recognizedText.isEmpty
                                          ? 'Listening...'
                                          : state.recognizedText,
                                      style: const TextStyle(
                                        fontFamily: 'Cera Pro',
                                        color: Pallete.mainFontColor,
                                        fontSize: 25,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        FadeInLeft(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.only(top: 10, left: 22),
                            child: const Text(
                              'Here are a few features',
                              style: TextStyle(
                                fontFamily: 'Cera Pro',
                                color: Pallete.mainFontColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // features list
                        const Column(
                          children: [
                            FeatureBox(
                              color: Pallete.firstSuggestionBoxColor,
                              headerText: 'Add Patient',
                              descriptionText:
                                  'Add a new patient to your records.',
                            ),
                            FeatureBox(
                              color: Pallete.secondSuggestionBoxColor,
                              headerText: 'Schedule Session',
                              descriptionText:
                                  'Schedule a new session for a patient.',
                            ),
                            FeatureBox(
                              color: Pallete.thirdSuggestionBoxColor,
                              headerText: 'Record Evaluation',
                              descriptionText:
                                  'Record a new evaluation for a patient.',
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                // Right Section (Dynamic Content)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.white,
                    child:
                        BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
                      builder: (context, state) {
                        if (state is AiVoiceAssistantPatientSelection) {
                          return PatientSelectionCard(
                            patients: state.patients,
                            onPatientSelected: (patient) {
                              context
                                  .read<AiVoiceAssistantBloc>()
                                  .add(SelectPatientEvent(patient));
                            },
                          );
                        }
                        return const Center(
                          child: Text('Placeholder for dynamic content'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Section (Confirmation Card)
          BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
            builder: (context, state) {
              if (state is AiVoiceAssistantCommandConfirmation) {
                return ConfirmationCard(
                  command: state.command,
                  onConfirm: (updatedCommand) {
                    context
                        .read<AiVoiceAssistantBloc>()
                        .add(ConfirmCommandEvent(updatedCommand));
                  },
                  onCancel: () {
                    context
                        .read<AiVoiceAssistantBloc>()
                        .add(CancelCommandEvent());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton:
          BlocListener<AiVoiceAssistantBloc, AiVoiceAssistantState>(
        listener: (context, state) {
          if (state is AiVoiceAssistantListening) {
            _startAnimation();
          } else {
            _stopAnimation();
          }
        },
        child: GestureDetector(
          onTap: () {
            final bloc = context.read<AiVoiceAssistantBloc>();
            if (bloc.state is AiVoiceAssistantListening) {
              bloc.add(StopListeningEvent());
            } else {
              bloc.add(StartListeningEvent());
            }
          },
          child: SizedBox(
            height: 120,
            width: 120,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(isVisible: false),
              primaryYAxis: NumericAxis(isVisible: false, maximum: 50),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries<ChartData, String>>[
                ColumnSeries<ChartData, String>(
                  dataSource: _chartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  color: Pallete.firstSuggestionBoxColor,
                  animationDuration: 200,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}
