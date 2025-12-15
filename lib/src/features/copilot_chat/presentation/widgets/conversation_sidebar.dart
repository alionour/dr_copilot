import 'package:dr_copilot/src/features/copilot_chat/data/models/conversation_model.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/conversation_list_item.dart';
import 'package:flutter/material.dart';

class ConversationSidebar extends StatelessWidget {
  final ConversationRepository repository;
  final String? currentConversationId;
  final Function(String) onConversationSelected;
  final VoidCallback onNewChat;
  final Function(String) onDeleteConversation;
  final Function(String, String) onRenameConversation;

  const ConversationSidebar({
    super.key,
    required this.repository,
    required this.currentConversationId,
    required this.onConversationSelected,
    required this.onNewChat,
    required this.onDeleteConversation,
    required this.onRenameConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: _buildConversationList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    return StreamBuilder<List<ConversationModel>>(
      stream: repository.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final conversations = snapshot.data!;
        return ListView.separated(
          itemCount: conversations.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
          ),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return ConversationListItem(
              conversation: conversation,
              isSelected: conversation.id == currentConversationId,
              onTap: () => onConversationSelected(conversation.id),
              onDelete: () => onDeleteConversation(conversation.id),
              onRename: () => onRenameConversation(conversation.id, conversation.title),
            );
          },
        );
      },
    );
  }
}

