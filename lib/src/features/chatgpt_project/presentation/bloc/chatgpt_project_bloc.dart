import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/models/chatgpt_project_model.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/usecases/get_or_create_project.dart';
import 'package:equatable/equatable.dart';

part 'chatgpt_project_event.dart';
part 'chatgpt_project_state.dart';

class ChatGptProjectBloc extends Bloc<ChatGptProjectEvent, ChatGptProjectState> {
  final GetOrCreateProject getOrCreateProject;

  ChatGptProjectBloc({required this.getOrCreateProject}) : super(ChatGptProjectInitial()) {
    on<GetProject>((event, emit) async {
      emit(ChatGptProjectLoading());
      try {
        final project = await getOrCreateProject(event.name);
        emit(ChatGptProjectLoaded(project: project));
      } catch (e) {
        emit(ChatGptProjectError(message: e.toString()));
      }
    });
  }
}
