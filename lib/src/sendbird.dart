import 'dart:async' as sync;
import 'package:flutter/services.dart';
import 'channel_res.dart';
import 'message_res.dart';
import 'user_res.dart';
import 'utils/logger.dart';

Map<String, dynamic> _castJsonMap(Map map) {
  return Map<String, dynamic>.from(map);
}

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
    final json = await platform.invokeMethod('getChannel', [isOpen, url]);

    if (json == null) return null;

    if (isOpen) {
      return OpenChannel.fromJson(_castJsonMap(json));
    } else {
      return GroupChannel.fromJson(_castJsonMap(json));
    }
  }

  Future<void> updateCurrentUser(String nickname, String profileImg) async {
    platform.invokeMethod('updateCurrentUser', [nickname, profileImg]);
    // nothing .
  }

  Future<List<User>> viewUser(List<String> userIds) async {
    final lists = await platform.invokeMethod('viewUser', userIds);
    final ret = <User>[];
    for (final json in lists) {
      final u = User.fromJson(_castJsonMap(json));
      ret.add(u);
    }
    return ret;
  }

  Future<List<GroupChannel>> fetchChannelList() async {
    final allchannels = await platform.invokeMethod('fetchChannelList');
    final ret = <GroupChannel>[];
    for (var channel in allchannels) {
      final ch = GroupChannel.fromJson(_castJsonMap(channel));
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
    _eventChannel.receiveBroadcastStream().listen((json) {
      eventChannel.add(_castJsonMap(json));
      switch (json['event']) {
        case 'messageUpdated':
        case 'messageReceived':
          final msg = Message.fromJson(_castJsonMap(json));
          eventChannelMessage.add(msg);
          //pointChat.value = pointChat.value +1;
          break;
      }
    });
  }

  Future<OpenChannel> enterOpenChannel(String channelUrl) async {
    final json = await platform.invokeMethod('enterOpenChannel', channelUrl);
    if (json != null) {
      final channel = OpenChannel.fromJson(_castJsonMap(json));
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
      for (var json in msgs) {
        ret.add(Message.fromJson(_castJsonMap(json)));
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
      for (var json in msgs) {
        ret.add(Message.fromJson(_castJsonMap(json)));
      }
      return ret;
    }
    return null;
  }

  Future<MessageChangeLog> getMessageChangeLogsByTimestamp(
    bool isOpen,
    String url,
    int timestamp,
  ) async {
    if (connected == false) {
      logger.e('sendbird getLastMessages before connected');
      return null;
    }
    final msgs = await platform.invokeMethod('getMessageChangeLogsByTimestamp', [
      isOpen,
      url,
      timestamp,
    ]);
    if (msgs != null) {
      final json = Map<String, dynamic>.from(msgs);
      return MessageChangeLog.fromJson(_castJsonMap(json));
    }
    return null;
  }

  Future<MessageChangeLog> getMessageChangeLogsByToken(
    bool isOpen,
    String url,
    String queryToken,
  ) async {
    if (connected == false) {
      logger.e('sendbird getLastMessages before connected');
      return null;
    }
    final msgs = await platform.invokeMethod('getMessageChangeLogsByToken', [
      isOpen,
      url,
      queryToken,
    ]);
    if (msgs != null) {
      final json = Map<String, dynamic>.from(msgs);
      return MessageChangeLog.fromJson(_castJsonMap(json));
    }
    return null;
  }

  Future<UserMessage> sendUserMessage(
      bool isOpen, String url, String customType, String message, String userData, List<String> mentionUsers) async {
    final json = await platform
        .invokeMethod('sendUserMessage', [isOpen, url, customType, message, userData, mentionUsers.join(',')]);
    if (json != null) {
      return Message.fromJson(_castJsonMap(json)) as UserMessage;
    }
    return null;
  }

  Future<UserMessage> updateUserMessage(
      bool isOpen, String url, String customType, int msgId, String message, String userData) async {
    final json = await platform.invokeMethod('updateUserMessage', [isOpen, url, customType, msgId, message, userData]);
    if (json != null) {
      return Message.fromJson(_castJsonMap(json)) as UserMessage;
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
    final json = await platform.invokeMethod('createChannelWithUserIds', [userIds, isDistinct]);
    if (json != null) {
      final channel = GroupChannel.fromJson(_castJsonMap(json));
      return channel;
    }
    return null;
  }
}
