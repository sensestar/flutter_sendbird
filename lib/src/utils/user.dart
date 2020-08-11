import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_sendbird/flutter_sendbird.dart';

import 'utils.dart' as http;
import '../user_res.dart';

export '../user_res.dart';

Future<User> viewUser(String uuid, {bool includeUnreadCount, List<String> customType, String superMode}) async {
  final Map<String, dynamic> param = {};
  if (includeUnreadCount ?? false) {
    param['include_unread_count'] = 'true';
  }
  if (customType != null && customType.length > 0) {
    param['custom_type'] = customType.join(',');
  }
  if (['all', 'nonsuper', 'super'].contains(superMode)) {
    param['supser_mode'] = superMode;
  }

  final resp = await http.get('/v3/users/$uuid', param);
  if (resp.statusCode == 200) {
    final js = jsonDecode(utf8.decode(resp.bodyBytes));
    final user = User.fromJson(js);
    return user;
  }
  return null;
}

Future<User> updateUser(UpdateUserReq req) async {
  final uuid = FlutterSendbird().currentUserId;
  final resp = await http.put('/v3/users/$uuid', req.toJson());
  if (resp.statusCode == 200) {
    final js = jsonDecode(utf8.decode(resp.bodyBytes));
    final user = User.fromJson(js);
    return user;
  }
  return null;
}

Future<RegistrationDeviceTokenResp> registerDeviceToken(String token) async {
  final userId = FlutterSendbird().currentUserId;
  var tokenType = 'gcm'; // or apns

  final Map<String, dynamic> param = {};

  if (io.Platform.isIOS) {
    param['apns_device_token'] = token;
    tokenType = 'apns';
  } else {
    param['gcm_reg_token'] = token;
  }

  final resp = await http.post('/v3/users/$userId/push/$tokenType', param);
  if (resp.statusCode == 200) {
    final js = jsonDecode(utf8.decode(resp.bodyBytes));
    return RegistrationDeviceTokenResp.fromJson(js);
  }
  return null;
}
