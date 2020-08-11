import 'package:flutter_sendbird/flutter_sendbird.dart';
import 'package:json_annotation/json_annotation.dart';

import 'member_res.dart';
import 'message_res.dart';
part 'channel_res.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class BaseChannel {
  String coverUrl;
  String name;
  String url;
  String data;
  bool isOpenChannel; // 世界頻道
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, anyMap: true)
class GroupChannel extends BaseChannel {
  String customType;
  bool isPublic; // 需要密碼加入
  Message _lastMessage;
  int unreadMessageCount;
  List<Member> members;
  Map<String, int> readStatus;

  String _lastMesgCustom;

  Message get lastMessage => _lastMessage;
  set lastMessage(Message msg) {
    _lastMesgCustom = null;
    _lastMessage = msg;
  }

  void markAllRead() {
    if (readStatus != null) {
      readStatus[FlutterSendbird().currentUserId] = lastMessage.createdAt;
    }
  }

  GroupChannel();
  factory GroupChannel.fromJson(Map<String, dynamic> json) => _$GroupChannelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupChannelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, anyMap: true)
class OpenChannel extends BaseChannel {
  String customType;

  OpenChannel();
  factory OpenChannel.fromJson(Map<String, dynamic> json) => _$OpenChannelFromJson(json);
}
