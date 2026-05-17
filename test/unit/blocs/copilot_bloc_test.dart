import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/ai_router_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/vertex_ai_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'copilot_bloc_test.mocks.dart';

class MockConversationRepository extends Mock implements ConversationRepository {}

@GenerateMocks([
  VertexAIService,
  GPTService,
  GeminiService,
  DeepSeekService,
  QwenService,
  ClaudeService,
  AIRouterService,
  FlutterSecureStorage,
])
void main() {
  late CopilotBloc copilotBloc;
  late MockVertexAIService mockVertexAIService;
  late MockGPTService mockGPTService;
  late MockGeminiService mockGeminiService;
  late MockDeepSeekService mockDeepSeekService;
  late MockQwenService mockQwenService;
  late MockClaudeService mockClaudeService;
  late MockAIRouterService mockRouterService;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockConversationRepository mockConversationRepo;

  setUp(() {
    mockVertexAIService = MockVertexAIService();
    mockGPTService = MockGPTService();
    mockGeminiService = MockGeminiService();
    mockDeepSeekService = MockDeepSeekService();
    mockQwenService = MockQwenService();
    mockClaudeService = MockClaudeService();
    mockRouterService = MockAIRouterService();
    mockSecureStorage = MockFlutterSecureStorage();
    mockConversationRepo = MockConversationRepository();

    copilotBloc = CopilotBloc(
      vertexAIService: mockVertexAIService,
      gptService: mockGPTService,
      geminiService: mockGeminiService,
      deepSeekService: mockDeepSeekService,
      qwenService: mockQwenService,
      claudeService: mockClaudeService,
      routerService: mockRouterService,
      secureStorage: mockSecureStorage,
      conversationRepo: mockConversationRepo,
    );
  });

  tearDown(() {
    copilotBloc.close();
  });

  test('initial state is CopilotInitial', () {
    expect(copilotBloc.state, CopilotInitial());
  });

  blocTest<CopilotBloc, CopilotState>(
    'emits [CopilotLoading, CopilotResponseGenerated] when GenerateResponseEvent is added and succeeds',
    build: () {
      when(mockRouterService.getServiceForQuery(
        query: anyNamed('query'),
        clinicId: anyNamed('clinicId'),
        forcePremium: anyNamed('forcePremium'),
      )).thenAnswer((_) async => mockGPTService);

      when(mockGPTService.generateResponse(
        any,
        messageHistory: anyNamed('messageHistory'),
        clinicId: anyNamed('clinicId'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => 'Test response');

      return copilotBloc;
    },
    act: (bloc) => bloc.add(const GenerateResponseEvent(
      query: 'Hello',
      messageHistory: [],
      clinicId: 'clinic123',
      userId: 'user123',
    )),
    expect: () => [
      CopilotLoading(),
      const CopilotResponseGenerated('Test response'),
    ],
  );

  blocTest<CopilotBloc, CopilotState>(
    'emits [CopilotLoading, CopilotError] when GenerateResponseEvent fails',
    build: () {
      when(mockRouterService.getServiceForQuery(
        query: anyNamed('query'),
        clinicId: anyNamed('clinicId'),
        forcePremium: anyNamed('forcePremium'),
      )).thenAnswer((_) async => mockGPTService);

      when(mockGPTService.generateResponse(
        any,
        messageHistory: anyNamed('messageHistory'),
        clinicId: anyNamed('clinicId'),
        userId: anyNamed('userId'),
      )).thenThrow(Exception('API Error'));

      return copilotBloc;
    },
    act: (bloc) => bloc.add(const GenerateResponseEvent(
      query: 'Hello',
      messageHistory: [],
      clinicId: 'clinic123',
      userId: 'user123',
    )),
    expect: () => [
      CopilotLoading(),
      const CopilotError('Exception: API Error'),
    ],
  );
}
