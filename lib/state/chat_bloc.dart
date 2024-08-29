import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/models/chat_entry.dart';
import 'package:uplink/services/db_service.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  static final ChatBloc _instance = ChatBloc._internal();
  factory ChatBloc() {
    return _instance;
  }

  ChatBloc._internal() : super(ChatState(chats: [], selectedChat: null, isLoading: true)) {
    on<InitializeEvent>(_onInitialize);
    on<SelectChatEvent>(_onSelectChat);
    on<CreateChatEvent>(_onCreateChat);
    on<RemoveChatEvent>(_onRemoveChat);
    on<AddChatEntry>(_onAddChatEntry);
    add(InitializeEvent());
  }

  List<Chat> chats = [];
  Chat? selectedChat;


  Future<void> _onInitialize(InitializeEvent event, Emitter<ChatState> emit) async {
    chats = await DbService.getAllChats();
    emit(ChatState(chats: chats, selectedChat: null, isLoading: false));
  }

  void _onSelectChat(SelectChatEvent event, Emitter<ChatState> emit) {
    selectedChat = event.chat;
    emit(ChatState(chats: chats, selectedChat: selectedChat, isLoading: false));
  }

  void _onCreateChat(CreateChatEvent event, Emitter<ChatState> emit) {
    chats.add(Chat(
      id: const Uuid().v4(),
      modelApiId: event.modelApiId,
      entries: [],
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    DbService.addChat(chats.last);
    emit(ChatState(chats: chats, selectedChat: selectedChat, isLoading: false));
  }

  void _onRemoveChat(RemoveChatEvent event, Emitter<ChatState> emit) {
    DbService.deleteChat(event.id);
    chats.removeWhere((element) => element.id == event.id);
    emit(ChatState(chats: chats, selectedChat: selectedChat, isLoading: false));
  }

  void _onAddChatEntry(AddChatEntry event, Emitter<ChatState> emit) async {
    if (selectedChat != null) {
      var newChatEntry = ChatEntry(
        chatId: selectedChat!.id,
        type: event.type,
        content: event.content,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      selectedChat!.entries.add(newChatEntry);
      var index = chats.indexWhere((element) => element.id == selectedChat!.id);
      chats[index] = selectedChat!;
      await DbService.updateChat(selectedChat!);
      emit(ChatState(chats: chats, selectedChat: selectedChat, isLoading: false));
    } else {
      throw Exception('No chat selected');
    }
  }
}

abstract class ChatEvent {}

class InitializeEvent extends ChatEvent {}
class CreateChatEvent extends ChatEvent {
  final String modelApiId;

  CreateChatEvent(
      {required this.modelApiId});
}

class RemoveChatEvent extends ChatEvent {
  final String id;

  RemoveChatEvent({required this.id});
}

class SelectChatEvent extends ChatEvent {
  final Chat chat;

  SelectChatEvent({required this.chat});
}

class AddChatEntry extends ChatEvent {
  final ChatEntryType type;
  final String content;

  AddChatEntry({required this.type, required this.content});
}

class ChatState {
  final List<Chat> chats;
  final Chat? selectedChat;
  final bool isLoading;

  ChatState({required this.chats, this.selectedChat, this.isLoading = false});
}
