import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/pallete.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/confirmation_card.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/feature_box.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/patient_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

class AiVoiceAssistantPage extends StatefulWidget {
  const AiVoiceAssistantPage({super.key});

  @override
  State<AiVoiceAssistantPage> createState() => _AiVoiceAssistantPageState();
}

class _AiVoiceAssistantPageState extends State<AiVoiceAssistantPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AiVoiceAssistantBloc>().add(StartAssistantEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
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
                              Container(
                                height: 123,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/svg/logo.svg', // Using a placeholder image
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // chat bubble
                        FadeInRight(
                          child: Visibility(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(
                                top: 30,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Pallete.borderColor,
                                ),
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  topLeft: Radius.zero,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'Good Morning, what task can I do for you?',
                                  style: TextStyle(
                                    fontFamily: 'Cera Pro',
                                    color: Pallete.mainFontColor,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                    child: BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
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
                    context.read<AiVoiceAssistantBloc>().add(CancelCommandEvent());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
        builder: (context, state) {
          return ZoomIn(
            child: FloatingActionButton(
              backgroundColor: Pallete.firstSuggestionBoxColor,
              onPressed: () async {
                final bloc = context.read<AiVoiceAssistantBloc>();
                if (state is AiVoiceAssistantListening) {
                  bloc.add(StopListeningEvent());
                } else {
                  bloc.add(StartListeningEvent());
                }
              },
              child: Icon(
                state is AiVoiceAssistantListening ? Icons.stop : Icons.mic,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
