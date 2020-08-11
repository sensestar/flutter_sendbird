// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User()
    ..userId = json['user_id'] as String
    ..nickname = json['nickname'] as String
    ..profileUrl = json['profile_url'] as String
    ..isActive = json['is_active'] as bool
    ..isOnline = json['is_online'] as bool
    ..lastSeenAt = json['last_seen_at'] as int
    ..lastSeenTime = json['last_seen_time'] == null
        ? null
        : DateTime.parse(json['last_seen_time'] as String)
    ..sessionTokens =
        (json['session_tokens'] as List)?.map((e) => e as String)?.toList()
    ..accessToken = json['access_token'] as String
    ..metadata = json['metadata'] as Map<String, dynamic>
    ..discoveryKeys =
        (json['discovery_keys'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$UserToJson(User instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('user_id', instance.userId);
  writeNotNull('nickname', instance.nickname);
  writeNotNull('profile_url', instance.profileUrl);
  writeNotNull('is_active', instance.isActive);
  writeNotNull('is_online', instance.isOnline);
  writeNotNull('last_seen_at', instance.lastSeenAt);
  writeNotNull('last_seen_time', instance.lastSeenTime?.toIso8601String());
  writeNotNull('session_tokens', instance.sessionTokens);
  writeNotNull('access_token', instance.accessToken);
  writeNotNull('metadata', instance.metadata);
  writeNotNull('discovery_keys', instance.discoveryKeys);
  return val;
}

Map<String, dynamic> _$UpdateUserReqToJson(UpdateUserReq instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('nickname', instance.nickname);
  writeNotNull('profile_url', instance.profileUrl);
  writeNotNull('issue_access_token', instance.issueAccessToken);
  writeNotNull('issue_session_token', instance.issueSessionToken);
  writeNotNull('session_token_expires_at', instance.sessionTokenExpiresAt);
  writeNotNull('is_active', instance.isActive);
  writeNotNull('discovery_keys', instance.discoveryKeys);
  return val;
}

RegistrationDeviceTokenResp _$RegistrationDeviceTokenRespFromJson(
    Map<String, dynamic> json) {
  return RegistrationDeviceTokenResp()
    ..token = json['token'] as String
    ..type = json['type'] as String
    ..user = json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>);
}
