// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) {
  return Message(
    createdAt: json['created_at'] as int,
    data: json['data'] as String,
    messageId: json['message_id'] as int,
    type: json['type'] as String,
  )
    ..mentionedUserIds =
        (json['mentioned_user_ids'] as List)?.map((e) => e as String)?.toList()
    ..channelUrl = json['channel_url'] as String;
}

Map<String, dynamic> _$MessageToJson(Message instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('created_at', instance.createdAt);
  writeNotNull('data', instance.data);
  writeNotNull('message_id', instance.messageId);
  writeNotNull('type', instance.type);
  writeNotNull('mentioned_user_ids', instance.mentionedUserIds);
  writeNotNull('channel_url', instance.channelUrl);
  return val;
}

UserMessage _$UserMessageFromJson(Map<String, dynamic> json) {
  return UserMessage(
    json['message'] as String,
    json['sender_id'] as String,
    json['sender_nickname'] as String,
    json['sender_profile_url'] as String,
    json['custom_type'] as String,
  )
    ..createdAt = json['created_at'] as int
    ..data = json['data'] as String
    ..messageId = json['message_id'] as int
    ..type = json['type'] as String
    ..mentionedUserIds =
        (json['mentioned_user_ids'] as List)?.map((e) => e as String)?.toList()
    ..channelUrl = json['channel_url'] as String;
}

Map<String, dynamic> _$UserMessageToJson(UserMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('created_at', instance.createdAt);
  writeNotNull('data', instance.data);
  writeNotNull('message_id', instance.messageId);
  writeNotNull('type', instance.type);
  writeNotNull('mentioned_user_ids', instance.mentionedUserIds);
  writeNotNull('channel_url', instance.channelUrl);
  writeNotNull('message', instance.message);
  writeNotNull('sender_id', instance.senderId);
  writeNotNull('sender_profile_url', instance.senderProfileUrl);
  writeNotNull('sender_nickname', instance.senderNickname);
  writeNotNull('custom_type', instance.customType);
  return val;
}

AdminMessage _$AdminMessageFromJson(Map<String, dynamic> json) {
  return AdminMessage()
    ..createdAt = json['created_at'] as int
    ..data = json['data'] as String
    ..messageId = json['message_id'] as int
    ..type = json['type'] as String
    ..mentionedUserIds =
        (json['mentioned_user_ids'] as List)?.map((e) => e as String)?.toList()
    ..channelUrl = json['channel_url'] as String
    ..message = json['message'] as String;
}

Map<String, dynamic> _$AdminMessageToJson(AdminMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('created_at', instance.createdAt);
  writeNotNull('data', instance.data);
  writeNotNull('message_id', instance.messageId);
  writeNotNull('type', instance.type);
  writeNotNull('mentioned_user_ids', instance.mentionedUserIds);
  writeNotNull('channel_url', instance.channelUrl);
  writeNotNull('message', instance.message);
  return val;
}

FileMessage _$FileMessageFromJson(Map<String, dynamic> json) {
  return FileMessage()
    ..createdAt = json['created_at'] as int
    ..data = json['data'] as String
    ..messageId = json['message_id'] as int
    ..type = json['type'] as String
    ..mentionedUserIds =
        (json['mentioned_user_ids'] as List)?.map((e) => e as String)?.toList()
    ..channelUrl = json['channel_url'] as String
    ..name = json['name'] as String
    ..url = json['url'] as String
    ..size = json['size'] as int
    ..fileType = json['file_type'] as String
    ..requestId = json['request_id'] as String
    ..senderId = json['sender_id'] as String
    ..senderProfileUrl = json['sender_profile_url'] as String
    ..senderNickname = json['sender_nickname'] as String
    ..customType = json['custom_type'] as String;
}

Map<String, dynamic> _$FileMessageToJson(FileMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('created_at', instance.createdAt);
  writeNotNull('data', instance.data);
  writeNotNull('message_id', instance.messageId);
  writeNotNull('type', instance.type);
  writeNotNull('mentioned_user_ids', instance.mentionedUserIds);
  writeNotNull('channel_url', instance.channelUrl);
  writeNotNull('name', instance.name);
  writeNotNull('url', instance.url);
  writeNotNull('size', instance.size);
  writeNotNull('file_type', instance.fileType);
  writeNotNull('request_id', instance.requestId);
  writeNotNull('sender_id', instance.senderId);
  writeNotNull('sender_profile_url', instance.senderProfileUrl);
  writeNotNull('sender_nickname', instance.senderNickname);
  writeNotNull('custom_type', instance.customType);
  return val;
}

MessageChangeLog _$MessageChangeLogFromJson(Map json) {
  return MessageChangeLog()
    ..updated = (json['updated'] as List)
        ?.map((e) => e == null
            ? null
            : Message.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList()
    ..delete = (json['delete'] as List)?.map((e) => e as int)?.toList()
    ..hasMore = json['has_more'] as bool
    ..queryToken = json['query_token'] as String;
}
