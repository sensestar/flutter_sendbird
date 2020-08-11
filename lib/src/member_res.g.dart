// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) {
  return Member()
    ..userId = json['user_id'] as String
    ..nickname = json['nickname'] as String
    ..profileUrl = json['profile_url'] as String;
}

Map<String, dynamic> _$MemberToJson(Member instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('user_id', instance.userId);
  writeNotNull('nickname', instance.nickname);
  writeNotNull('profile_url', instance.profileUrl);
  return val;
}
