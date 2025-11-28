import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_chat_message.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_state.dart';

class AIChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  final bool hasSelection;
  final Function(String) onApply;
  final Function(String, String) onSaveInstruction;

  const AIChatPanel({
    super.key,
    required this.onClose,
    required this.hasSelection,
    required this.onApply,
    required this.onSaveInstruction,
  });

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _instructionController = TextEditingController();

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    hoverColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                BlocBuilder<
                  AddEditClinicalReportBloc,
                  AddEditClinicalReportState
                >(
                  builder: (context, state) {
                    if (state is AddEditClinicalReportLoaded) {
                      if (state.isAILoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.isReviewingAIChanges) {
                        return _buildReviewUI(context);
                      }

                      return DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Edit'),
                                Tab(text: 'Chat'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildEditTab(context, state),
                                  _buildChatTab(context, state),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Changes Applied',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review the changes in the editor and accept or reject them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AddEditClinicalReportBloc>().add(
                      AIEditRejected(),
                    );
                  },
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AddEditClinicalReportBloc>().add(
                      AIEditAccepted(),
                    );
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditTab(
    BuildContext context,
    AddEditClinicalReportLoaded state,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        if (state.instructions.isNotEmpty) ...[
          Text(
            'Saved Instructions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.instructions.map((instruction) {
              return ActionChip(
                label: Text(instruction.label),
                onPressed: () {
                  _instructionController.text = instruction.instruction;
                },
                avatar: const Icon(Icons.description, size: 16),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Instruction',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            if (_instructionController.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _showSaveInstructionDialog(context);
                },
                icon: const Icon(Icons.save_alt, size: 16),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _instructionController,
            maxLines: 4,
            onChanged: (value) {
              setState(() {}); // Rebuild to show/hide Save button
            },
            decoration: const InputDecoration(
              hintText: 'e.g., "Make it more concise", "Fix grammar"',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (_instructionController.text.isNotEmpty) {
                widget.onApply(_instructionController.text);
                _instructionController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.hasSelection ? 'Apply Edit' : 'Generate & Insert',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab(
    BuildContext context,
    AddEditClinicalReportLoaded state,
  ) {
    final TextEditingController chatController = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: state.chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start a conversation',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = state.chatMessages[index];
                    final isUser = message.sender == ChatMessageSender.user;
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                            bottomRight: isUser
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                          ),
                          boxShadow: [
                            if (!isUser)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: chatController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && state.report != null) {
                        context.read<AddEditClinicalReportBloc>().add(
                          SendChatMessage(state.report!.id, value),
                        );
                        chatController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, size: 20, color: Colors.white),
                  onPressed: () {
                    if (chatController.text.isNotEmpty &&
                        state.report != null) {
                      context.read<AddEditClinicalReportBloc>().add(
                        SendChatMessage(state.report!.id, chatController.text),
                      );
                      chatController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSaveInstructionDialog(BuildContext context) {
    final labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Instruction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., Summarize',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instruction:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_instructionController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                widget.onSaveInstruction(
                  labelController.text,
                  _instructionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
