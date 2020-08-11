import Flutter
import UIKit

public class SwiftFlutterSendbirdPlugin: NSObject, FlutterPlugin {
  var _binaryMessager: FlutterBinaryMessenger?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_sendbird", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterSendbirdPlugin()
    instance._binaryMessager = registrar.messenger()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
@objc
  public static func saveDeviceToken( with data: Data ){
    SendBirdUtils.sharedInstance.saveDeviceToken( token: data )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) ->(){
        switch call.method{
        case "getPlatformVersion": 
              result("iOS " + UIDevice.current.systemVersion)
        case "init":
            let appId = call.arguments as! String;
            SendBirdUtils.sharedInstance.initSDK(appId: appId, binaryMessenger: _binaryMessager!, rslt: result )
        case "connect":
            let args = call.arguments as! NSArray;
            let userId = args[0] as! String
            let token = args[1] as! String
            SendBirdUtils.sharedInstance.connect(uuid: userId, token: token, rslt: result)
        case "disconnect":
            SendBirdUtils.sharedInstance.disconnectSendBirdServer()
        case "reconnect":
            SendBirdUtils.sharedInstance.reconnect()
        case "viewUser":
            let userIds = call.arguments as! [String]
            SendBirdUtils.sharedInstance.getUsers( userIds: userIds, rslt: result )
        case "enterOpenChannel":
            let chId = call.arguments as! String
            SendBirdUtils.sharedInstance.enterOpenChannel(url: chId, rslt: result)
        case "getDoNotDisturb":
            SendBirdUtils.sharedInstance.getDoNotDisturb(rslt: result)
        case "setDoNotDisturb":
            let params = call.arguments as! NSArray
            let enable = params[0] as! Bool
            let startTime = params[1] as! String
            let endTime = params[2] as! String
            SendBirdUtils.sharedInstance.setDoNotDisturb(enabled: enable, timeFrom: startTime, timeEnd: endTime, rslt: result)
        case "registerPushTokenToSendBird":
            let token = call.arguments as! String
            SendBirdUtils.sharedInstance.registerPushTokenToSendBird(fcmToken: token, unique: false, rslt: result)
        case "unregisterPushTokenToSendBird":
            
                
            SendBirdUtils.sharedInstance.unregisterPushTokenToSendBird( rslt: result )
            
        case "fetchChannelList":
            SendBirdUtils.sharedInstance.fetchChannelList(rslt: result )
        case "listenChannelMessage":
            let handlerId = call.arguments as! String
            SendBirdUtils.sharedInstance.listenChannelMessage(handlerId: handlerId, rslt: result )
        case "getMessageByTime":
            let params = call.arguments as! NSArray
            let isOpen = params[0] as! Bool
            let url = params[1] as! String
            let timeStamp = params[2] as! Int64
            let cnt = params[3] as! Int
            let customType = params[4] as! String
            SendBirdUtils.sharedInstance.getMessagesByTimestamp(isOpen: isOpen, url: url, timeStamp: timeStamp, revertSoft: false, cnt: cnt, customType: customType, rslt: result)
        case "getMessagesByMsgId":
            let params = call.arguments as! NSArray
            let isOpen = params[0] as! Bool
            let url = params[1] as! String
            let msgId = params[2] as! Int64
            let forward = params[3] as! Bool
            let cnt = params[4] as! Int
            let customType = params[5] as! String
            SendBirdUtils.sharedInstance.getMessagesByMsgId(isOpen: isOpen, url: url, msgId: msgId, revertSoft: false, forward: forward, cnt: cnt, customType: customType, rslt: result)

        case "getLastMessages":
            let params = call.arguments as! NSArray
            let isOpen = params[0] as! Bool
            let qid = params[1] as! String
            let url = params[2] as! String
            let cnt = params[3] as! Int
            SendBirdUtils.sharedInstance.getLastMessages(isOpen: isOpen, queryId: qid, url: url, cnt: cnt, rslt: result)
            
        case "sendUserMessage":
            let paramList = call.arguments as! NSArray
            let isOpen = paramList[0] as! Bool
            let url = paramList[1] as! String
            let customType = paramList[2] as! String
            let message = paramList[3] as! String
            let userData = paramList[4] as! String
            let memtions = paramList[5] as! String
            let memtionUsers = memtions.split( separator: ",").map({ x in String(x)} )
            SendBirdUtils.sharedInstance.sendUserMessage(isOpen: isOpen, url: url, customType: customType, message: message, userData: userData, metionUsers: memtionUsers, rslt: result)

        case "updateUserMessage":
            let paramList = call.arguments as! NSArray
            let isOpen = paramList[0] as! Bool
            let url = paramList[1] as! String
            let customType = paramList[2] as! String
            let messageId = paramList[3] as! Int64
            let message = paramList[4] as! String
            let userData = paramList[5] as! String
            SendBirdUtils.sharedInstance.updateUserMessage(isOpen: isOpen, url: url, customType: customType, msgId: messageId, message: message, userData: userData, rslt: result)

        case "sendFileMessage":
            let paramList = call.arguments as! NSArray
            let isOpen = paramList[0] as! Bool
            let url = paramList[1] as! String
            let customType = paramList[2] as! String
            let message = paramList[3] as! String
            let userData = paramList[4] as! String
            let filePath = paramList[5] as! String
            let fileType = paramList[6] as! String
            let memtions = paramList[7] as! String
            let mentionUsers = memtions.split( separator: ",").map({ x in String(x)} )
            SendBirdUtils.sharedInstance.sendFileMessage(isOpen: isOpen, url: url, customType: customType, message: message,
                                    userData: userData, filePath: filePath, fileType: fileType, metionUsers: mentionUsers, rslt: result )
            
        case "getChannel":
            let params = call.arguments as! NSArray
            let isOpen = params[0] as! Bool
            let url = params[1] as! String
            SendBirdUtils.sharedInstance.getChannel(isOpen: isOpen, url: url, rslt: result)
        case "markAsRead":
            let url = call.arguments as! String
            SendBirdUtils.sharedInstance.markAsRead(url: url, rslt: result )
        case "createChannelWithUserIds":
            let params = call.arguments as! NSArray
            let userIds = params[0] as! [String]
            let isDistinct = params[1] as! Bool
            SendBirdUtils.sharedInstance.createChannelWithUserIds(uids: userIds, isDistinct: isDistinct, rslt: result )
        default:
            NSLog("Sendbird method called")
        }
    }
}
