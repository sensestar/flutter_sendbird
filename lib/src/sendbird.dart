import 'dart:async' as sync;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'channel_res.dart';
import 'message_res.dart';
import 'user_res.dart';
import 'utils/logger.dart';

class FlutterSendbird {
  static Future<String> get platformVersion async {
    final String version = await platform.invokeMethod('getPlatformVersion');
    return version;
  }

  static const platform = MethodChannel('flutter_sendbird');
  static final FlutterSendbird _inst = FlutterSendbird._internal();

  factory FlutterSendbird() {
    return _inst;
  }
  EventChannel _eventChannel;
  bool connected = false;

  String _currentUserId = '';

  String get currentUserId => _currentUserId;

  sync.StreamController<Map<String, dynamic>> eventChannel = sync.StreamController<Map<String, dynamic>>.broadcast();
  sync.StreamController<Message> eventChannelMessage = sync.StreamController<Message>.broadcast();

  FlutterSendbird._internal();

  Future init(String appid) async {
    return platform.invokeMethod('init', appid);
  }

  Future<bool> connect(String userId, String token) async {
    final bool ret = await platform.invokeMethod('connect', [userId, token]);
    connected = ret;
    if (connected) {
      _currentUserId = userId;
    }
    return ret;
  }

  Future disconnect() async {
    connected = false;
    _currentUserId = '';
    return platform.invokeMethod('disconnect');
  }

  Future<BaseChannel> getChannel(bool isOpen, String url) async {
    final data = await platform.invokeMethod('getChannel', [isOpen, url]);

    if (data == null) return null;
    final json = jsonDecode(data);
    if (isOpen) {
      return OpenChannel.fromJson(json);
    } else {
      return GroupChannel.fromJson(json);
    }
  }

  Future<void> updateCurrentUser(String nickname, String profileImg) async {
    platform.invokeMethod('updateCurrentUser', [nickname, profileImg]);
    // nothing .
  }

  Future<List<User>> viewUser(List<String> userIds) async {
    final lists = await platform.invokeMethod('viewUser', userIds);
    final ret = <User>[];
    for (final s in lists) {
      final json = jsonDecode(s);
      final u = User.fromJson(json);
      ret.add(u);
    }
    return ret;
  }

  Future<List<GroupChannel>> fetchChannelList() async {
    final allchannels = await platform.invokeMethod('fetchChannelList');
    final ret = <GroupChannel>[];
    for (var channel in allchannels) {
      final js = jsonDecode(channel);
      final ch = GroupChannel.fromJson(js);
      ret.add(ch);
    }
    return ret;
  }

  Future registerPushTokenToSendBird(String token) async {
    final ret = await platform.invokeMethod('registerPushTokenToSendBird', token);
    return ret;
  }

  Future unregisterPushTokenToSendBird() async {
    final ret = await platform.invokeMethod('unregisterPushTokenToSendBird');
    return ret;
  }

  Future listenChannelMessages() async {
    final eventName = 'handerldid_all';
    final _ = await platform.invokeMethod('listenChannelMessage', eventName);
    _eventChannel = EventChannel(eventName);
    _eventChannel.receiveBroadcastStream().listen((data) {
      final json = jsonDecode(data);
      eventChannel.add(json);
      switch (json['event']) {
        case 'messageUpdated':
        case 'messageReceived':
          final msg = Message.fromJson(json);
          eventChannelMessage.add(msg);
          //pointChat.value = pointChat.value +1;
          break;
      }
    });
  }

  Future<OpenChannel> enterOpenChannel(String channelUrl) async {
    final ret = await platform.invokeMethod('enterOpenChannel', channelUrl);
    if (ret != null) {
      final json = jsonDecode(ret);
      final channel = OpenChannel.fromJson(json);
      return channel;
    }
    return null;
  }

  Future<List<Message>> getLastMessages(bool isOpen, String qid, String groupId, int count) async {
    if (connected == false) {
      logger.e('sendbird getLastMessages before connected');
      return [];
    }
    final msgs = await platform.invokeMethod('getLastMessages', [isOpen, qid, groupId, count]);
    if (msgs != null) {
      final ret = <Message>[];
      for (var s in msgs) {
        final json = jsonDecode(s);
        ret.add(Message.fromJson(json));
      }
      return ret;
    }
    return null;
  }

  Future<List<Message>> getMessagesByMsgId({
    bool isOpen,
    String groupId,
    int msgId,
    bool forward = false,
    int count = 30,
    String customType = '',
  }) async {
    // forward => new messsages, false older message
    if (connected == false) {
      logger.e('sendbird getLastMessages before connected');
      return [];
    }
    final msgs = await platform.invokeMethod('getMessagesByMsgId', [
      isOpen,
      groupId,
      msgId,
      forward,
      count,
      customType,
    ]);
    if (msgs != null) {
      final ret = <Message>[];
      for (var s in msgs) {
        final json = jsonDecode(s);
        ret.add(Message.fromJson(json));
      }
      return ret;
    }
    return null;
  }

  Future<UserMessage> sendUserMessage(
      bool isOpen, String url, String customType, String message, String userData, List<String> mentionUsers) async {
    final msgs = await platform
        .invokeMethod('sendUserMessage', [isOpen, url, customType, message, userData, mentionUsers.join(',')]);
    if (msgs != null) {
      final json = jsonDecode(msgs);
      return Message.fromJson(json) as UserMessage;
    }
    return null;
  }

  Future<UserMessage> updateUserMessage(
      bool isOpen, String url, String customType, int msgId, String message, String userData) async {
    final msgs = await platform.invokeMethod('updateUserMessage', [isOpen, url, customType, msgId, message, userData]);
    if (msgs != null) {
      final json = jsonDecode(msgs);
      return Message.fromJson(json) as UserMessage;
    }
    return null;
  }

  Future sendFileMessage(bool isOpen, String url, String customType, String message, String userData, String filePath,
      String fileType, List<String> mentionUsers) async {
    final _ = await platform.invokeMethod(
        'sendFileMessage', [isOpen, url, customType, message, userData, filePath, fileType, mentionUsers.join(',')]);
  }

  EventChannel listenSendFileProgress(
    String filepath,
  ) {
    final eventName = filepath;
    final progressChannel = EventChannel(eventName);
    return progressChannel;
//    progressChannel.receiveBroadcastStream().listen( (data){
//      final json = jsonDecode(data);
//      eventChannel.add( json );
//    });
  }

  void markAsRead(String url) async {
    if (connected == false) {
      return;
    }
    await platform.invokeMethod('markAsRead', url);
  }

  Future<GroupChannel> createChannelWithUserIds(List<String> userIds, bool isDistinct) async {
    final ret = await platform.invokeMethod('createChannelWithUserIds', [userIds, isDistinct]);
    if (ret != null) {
      final json = jsonDecode(ret);
      final channel = GroupChannel.fromJson(json);
      return channel;
    }
    return null;
  }
}
