import 'package:json_annotation/json_annotation.dart';

part 'user_res.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class User {
  User();

  String userId;
  String nickname;
  String profileUrl;
  bool isActive;
  bool isOnline;
  int lastSeenAt;
  DateTime lastSeenTime;
  List<String> sessionTokens;
  String accessToken;
  Map<String, dynamic> metadata;
  List<String> discoveryKeys; // 搜尋使用者的關鍵字

  factory User.fromJson(Map<String, dynamic> map) {
    var u = _$UserFromJson(map);
    u.lastSeenTime = DateTime.fromMillisecondsSinceEpoch(u.lastSeenAt);
    return u;
  }
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, createFactory: false)
class UpdateUserReq {
  String nickname;
  String profileUrl;
  bool issueAccessToken;
  bool issueSessionToken;
  int sessionTokenExpiresAt;
  bool isActive;
  List<String> discoveryKeys; // 搜尋使用者的關鍵字

  UpdateUserReq();

  Map<String, dynamic> toJson() => _$UpdateUserReqToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, createToJson: false)
class RegistrationDeviceTokenResp {
  String token;
  String type;
  User user;

  RegistrationDeviceTokenResp();

  factory RegistrationDeviceTokenResp.fromJson(Map<String, dynamic> json) =>
      _$RegistrationDeviceTokenRespFromJson(json);
}
