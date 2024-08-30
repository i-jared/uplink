import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/models/chat_entry.dart';
import 'dart:convert';

import 'package:uplink/models/model_api.dart';

class DbService {
  static const String _apiStorageKey = 'apiStorage';
  static const String _chatStorageKey = 'chatStorage';
  static const _storage = FlutterSecureStorage();

  // static Future<void> _nuke() async {
  //   await _storage.deleteAll();
  // }

  static Future<void> addApi(ModelApi api) async {
    List<ModelApi> apis = await getAllApis();
    apis.add(api);
    await _saveApis(apis);
  }

  static Future<List<ModelApi>> getAllApis() async {
    // await _nuke();
    String? jsonString = await _storage.read(key: _apiStorageKey);
    if (jsonString == null) return [];
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ModelApi.fromMap(json)).toList();
  }

  static Future<void> updateApi(ModelApi api) async {
    List<ModelApi> apis = await getAllApis();
    int index = apis.indexWhere((element) => element.id == api.id);
    apis[index] = api;
    await _saveApis(apis);
  }

  static Future<void> deleteApi(String id) async {
    List<ModelApi> apis = await getAllApis();
    apis.removeWhere((element) => element.id == id);
    await _saveApis(apis);
  }

  static Future<void> _saveApis(List<ModelApi> apis) async {
    String jsonString = jsonEncode(apis.map((api) => api.toMap()).toList());
    await _storage.write(key: _apiStorageKey, value: jsonString);
  }

  static Future<void> saveChat(
      String callerName, List<ChatEntry> chatEntries) async {
    String? existingChats = await _storage.read(key: 'chats');
    Map<String, dynamic> chatsMap =
        existingChats != null ? jsonDecode(existingChats) : {};

    chatsMap[callerName] = chatEntries
        .map((entry) => {
              'type': entry.type.toString(),
              'content': entry.content,
            })
        .toList();

    await _storage.write(key: 'chats', value: jsonEncode(chatsMap));
  }




  static Future<void> addChat(Chat chat) async {
    List<Chat> chats = await getAllChats();
    chats.add(chat);
    await _saveChats(chats);
  }

  static Future<List<Chat>> getAllChats() async {
    String? jsonString = await _storage.read(key: _chatStorageKey);
    if (jsonString == null) return [];
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Chat.fromMap(json)).toList();
  }

  static Future<void> updateChat(Chat chat) async {
    List<Chat> chats = await getAllChats();
    var index = chats.indexWhere((element) => element.id == chat.id);
    chats[index] = chat;
    await _saveChats(chats);
  }

  static Future<void> deleteChat(String id) async {
    List<Chat> chats = await getAllChats();
    chats.removeWhere((element) => element.id == id);
    await _saveChats(chats);
  }

  static Future<void> _saveChats(List<Chat> chats) async {
    String jsonString = jsonEncode(chats.map((chat) => chat.toMap()).toList());
    await _storage.write(key: _chatStorageKey, value: jsonString);
  }
}
