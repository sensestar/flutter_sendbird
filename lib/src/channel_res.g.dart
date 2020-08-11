// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseChannel _$BaseChannelFromJson(Map<String, dynamic> json) {
  return BaseChannel()
    ..coverUrl = json['cover_url'] as String
    ..name = json['name'] as String
    ..url = json['url'] as String
    ..data = json['data'] as String
    ..isOpenChannel = json['is_open_channel'] as bool;
}

Map<String, dynamic> _$BaseChannelToJson(BaseChannel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cover_url', instance.coverUrl);
  writeNotNull('name', instance.name);
  writeNotNull('url', instance.url);
  writeNotNull('data', instance.data);
  writeNotNull('is_open_channel', instance.isOpenChannel);
  return val;
}

GroupChannel _$GroupChannelFromJson(Map json) {
  return GroupChannel()
    ..coverUrl = json['cover_url'] as String
    ..name = json['name'] as String
    ..url = json['url'] as String
    ..data = json['data'] as String
    ..isOpenChannel = json['is_open_channel'] as bool
    ..customType = json['custom_type'] as String
    ..isPublic = json['is_public'] as bool
    ..unreadMessageCount = json['unread_message_count'] as int
    ..members = (json['members'] as List)
        ?.map((e) => e == null
            ? null
            : Member.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList()
    ..readStatus = (json['read_status'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as int),
    )
    ..lastMessage = json['last_message'] == null
        ? null
        : Message.fromJson((json['last_message'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ));
}

Map<String, dynamic> _$GroupChannelToJson(GroupChannel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cover_url', instance.coverUrl);
  writeNotNull('name', instance.name);
  writeNotNull('url', instance.url);
  writeNotNull('data', instance.data);
  writeNotNull('is_open_channel', instance.isOpenChannel);
  writeNotNull('custom_type', instance.customType);
  writeNotNull('is_public', instance.isPublic);
  writeNotNull('unread_message_count', instance.unreadMessageCount);
  writeNotNull('members', instance.members);
  writeNotNull('read_status', instance.readStatus);
  writeNotNull('last_message', instance.lastMessage);
  return val;
}

OpenChannel _$OpenChannelFromJson(Map<String, dynamic> json) {
  return OpenChannel()
    ..coverUrl = json['cover_url'] as String
    ..name = json['name'] as String
    ..url = json['url'] as String
    ..data = json['data'] as String
    ..isOpenChannel = json['is_open_channel'] as bool
    ..customType = json['custom_type'] as String;
}

Map<String, dynamic> _$OpenChannelToJson(OpenChannel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cover_url', instance.coverUrl);
  writeNotNull('name', instance.name);
  writeNotNull('url', instance.url);
  writeNotNull('data', instance.data);
  writeNotNull('is_open_channel', instance.isOpenChannel);
  writeNotNull('custom_type', instance.customType);
  return val;
}
