import 'package:json_annotation/json_annotation.dart';

part 'member_res.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Member {
  Member();
  factory Member.fromJson(Map<String, dynamic> map) => _$MemberFromJson(map);
  Map<String, dynamic> toJson() => _$MemberToJson(this);

  String userId;
  String nickname;
  String profileUrl;
}
