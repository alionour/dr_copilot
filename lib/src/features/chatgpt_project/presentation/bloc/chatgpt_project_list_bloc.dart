import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/usecases/get_chatgpt_project_list.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_event.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatGptProjectListBloc
    extends Bloc<ChatGptProjectListEvent, ChatGptProjectListState> {
  final GetChatGptProjectList getChatGptProjectList;
  final FlutterSecureStorage secureStorage;

  ChatGptProjectListBloc(this.getChatGptProjectList, this.secureStorage)
      : super(ChatGptProjectListInitial()) {
    on<LoadChatGptProjectList>(_onLoadChatGptProjectList);
  }

  Future<void> _onLoadChatGptProjectList(
    LoadChatGptProjectList event,
    Emitter<ChatGptProjectListState> emit,
  ) async {
    emit(ChatGptProjectListLoading());
    try {
      final apiKey = await secureStorage.read(key: 'chatGptApiKey');
      if (apiKey == null || apiKey.isEmpty) {
        emit(ChatGptProjectListApiKeyMissing());
        return;
      }
      final projects = await getChatGptProjectList();
      emit(ChatGptProjectListLoaded(projects));
    } catch (e) {
      emit(ChatGptProjectListError(e.toString()));
    }
  }
}
