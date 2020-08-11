import 'dart:convert';
import 'package:flutter_sendbird/flutter_sendbird.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

import 'utils/logger.dart';

part 'message_res.g.dart';

// notification: sendbird.go / updateSbMsgData()

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, explicitToJson: true)
class Message {
  Message({this.createdAt, this.data, this.messageId, this.type, int numberOfLikes = 0});
  int createdAt;
  String data;
  int messageId;
  String type;
  List<String> mentionedUserIds;
  String channelUrl;

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return Message();
    }

    logger.v('sb message data: $json');

    final dataJson = json['data'] as String;

    final int t = json['created_at'] as int;
    json['short_create_time'] =
        t != null ? DateFormat('H:mm').format(DateTime.fromMillisecondsSinceEpoch(t, isUtc: true).toLocal()) : '0:00';
    switch (json['type']) {
      case 'MESG':
      case 'USER':
        return UserMessage.fromJson(json);
        break;
      case 'ADMIN':
        return AdminMessage.fromJson(json);
        break;
      case 'image/jpeg':
      case 'FILE':
        return FileMessage.fromJson(json);
      default:
        return _$MessageFromJson(json);
    }
  }

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class UserMessage extends Message {
  UserMessage(
    this.message,
    this.senderId,
    this.senderNickname,
    this.senderProfileUrl,
    this.customType,
  );

  factory UserMessage.fromJson(Map<String, dynamic> json) => _$UserMessageFromJson(json);
  Map<String, dynamic> toJson() => _$UserMessageToJson(this);

  String message;
  String senderId;
  String senderProfileUrl;
  String senderNickname;
  String customType;

  bool isFromOtherUser() => senderId != FlutterSendbird().currentUserId;
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class AdminMessage extends Message {
  AdminMessage();

  factory AdminMessage.fromJson(Map<String, dynamic> json) => _$AdminMessageFromJson(json);
  Map<String, dynamic> toJson() => _$AdminMessageToJson(this);
  String message;
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class FileMessage extends Message {
  FileMessage();
  factory FileMessage.fromJson(Map<String, dynamic> json) => _$FileMessageFromJson(json);
  Map<String, dynamic> toJson() => _$FileMessageToJson(this);

  String name;
  String url;
  int size;
  String fileType;
  String requestId;
  String senderId;
  String senderProfileUrl;
  String senderNickname;
  String customType;

  bool isFromOtherUser() => senderId != FlutterSendbird().currentUserId;
}
