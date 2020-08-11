package com.sstar.flutter_sendbird

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.util.Log
import android.content.Context;
/** FlutterSendbirdPlugin */
public class FlutterSendbirdPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var _flutterBinaryMessenger : BinaryMessenger? = null
  private var _applicationContext : Context? = null
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    _flutterBinaryMessenger = flutterPluginBinding.getFlutterEngine().getDartExecutor()
    _applicationContext = flutterPluginBinding.getApplicationContext()
    channel = MethodChannel( _flutterBinaryMessenger, "flutter_sendbird")
    channel.setMethodCallHandler(this);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_sendbird")
      channel.setMethodCallHandler(FlutterSendbirdPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

      when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "init" -> {
          val appid = call.arguments as String
          //GlobalScope.async {
            
              var ret = SendBirdUtils.init(appid, _applicationContext!!, _flutterBinaryMessenger!! )
              //var ret = SendBirdUtils.init(appid, GetContext(), GetBinaryMessenger() )
              result.success(ret)

          //}
        }
        "connect" -> {
          var params = call.arguments as List<String>
          val userid = params[0];
          val token = params[1];
          SendBirdUtils.connectToSendBird(userid, token, result)
        }
        "disconnect" -> {
          SendBirdUtils.disconnectSendBirdServer()
          result.success(true)
        }
        "reconnect" -> {
          SendBirdUtils.reconnect()
          result.success(true)
        }
        "viewUser" -> {
          var userids = call.arguments as List<String>
          var ret = SendBirdUtils.getUsers(userids, result)
        }
        "updateCurrentUser" -> {
          val params = call.arguments as List<String>
          val nickname = params[0]
          val img = params[1]
          SendBirdUtils.updateCurrentUserInfo(nickname, img, result)
        }
        "enterOpenChannel" -> {
          val channelId = call.arguments as String
          SendBirdUtils.enterOpenChannel(channelId, result)
        }
        "getDoNotDisturb" -> {
          SendBirdUtils.getDoNotDisturb(result)
        }
        "setDoNotDisturb" -> {
          val params = call.arguments as List<String>
          val enable = params[0].toBoolean()
          val startTime = params[1]
          val endTime = params[2]
          SendBirdUtils.setDoNotDisturb(enable, startTime, endTime, result)
        }
        "registerPushTokenToSendBird" -> {
          val token = call.arguments as String
          SendBirdUtils.registerPushTokenToSendBird(token, result)
        }
        "unregisterPushTokenToSendBird" -> {
          SendBirdUtils.unregisterPushTokenToSendBird()
        }
        "fetchChannelList" ->{
          SendBirdUtils.fetchChannelList( result )
        }
        "listenChannelMessage" ->{
          val handelid = call.arguments as String
          SendBirdUtils.listenChannelMessage( handelid, result )
        }
        "getMessageByTime" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val timeStamp = paramList[2] as Long
          val cnt = paramList[3] as Int
          val customType = paramList[4]

          SendBirdUtils.getMessagesByTimestamp( isOpen, url, timeStamp, false, cnt , customType, result )
        }
        "getMessagesByMsgId" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val msgId = paramList[2] as Long
          val forward = paramList[3] as Boolean
          val cnt = paramList[4] as Int
          val customType = paramList[5]
          SendBirdUtils.getMessagesByMsgId( isOpen, url, msgId, false, forward, cnt, customType, result )
        }
        "getLastMessages" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val qid = paramList[1]
          val url = paramList[2]
          val cnt = paramList[3] as Int
          SendBirdUtils.getLastMessages( isOpen, qid , url, cnt, result );
        }
        "sendUserMessage" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val customType = paramList[2]
          val message = paramList[3]
          val userData = paramList[4]
          val memtions = paramList[5]
          val mentionUsers = memtions.split(",")
          SendBirdUtils.sendUserMessage(isOpen, url, customType, message, userData, mentionUsers, result )
        }
        "updateUserMessage" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val customType = paramList[2]
          val msgId = paramList[3] as Long
          val message = paramList[4]
          val userData = paramList[5]
          SendBirdUtils.updateUserMessage(isOpen, url, customType, msgId, message, userData, result )
        }
        "sendFileMessage" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val customType = paramList[2]
          val message = paramList[3]
          val userData = paramList[4]
          val filePath = paramList[5]
          val fileType = paramList[6]
          val memtions = paramList[7]
          val mentionUsers = memtions.split(",")
          SendBirdUtils.sendFileMessage(isOpen, url, customType, message, userData, filePath, fileType,  mentionUsers, result )

        }
        "getMessageChangeLogsByTimestamp" ->{
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val timeStamp = paramList[2] as Long
          SendBirdUtils.getMessageChangeLogsByTimeStamp( isOpen, url, timeStamp, result )
        }
        "getMessageChangeLogsByToken" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          val token = paramList[2] as String
          SendBirdUtils.getMessageChangeLogsByToken( isOpen, url, token, result )
        }        
        "getChannel" -> {
          val paramList = call.arguments as List<String>
          val isOpen = paramList[0] as Boolean
          val url = paramList[1]
          SendBirdUtils.getChannel( isOpen,url, result )
        }
        "markAsRead"->{
          val url = call.arguments as String;
          SendBirdUtils.markAsRead( url, result )
        }
        "createChannelWithUserIds" ->{
          val paramList = call.arguments as List<Any>
          val userIds = paramList[0] as List<String>
          val isDistinct = paramList[1] as Boolean
          SendBirdUtils.createChannelWithUserIds( userIds, isDistinct, result )
        }
        else -> {
          Log.d("sendbird", "unknown")
          result.notImplemented()

        }
      } // when    
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
