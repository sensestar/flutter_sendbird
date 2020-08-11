//
//  SendBirdUtils.swift
//  Runner
//
//  Created by Maxi Lin on 2019/12/23.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation
import SendBirdSDK

class SendBirdUtils: NSObject {
    
    static let sharedInstance = SendBirdUtils()
    private let internalQueue = DispatchQueue(label: "SingletionInternalQueue", qos: .default, attributes: .concurrent)
    
    /*
    private var _dataCount: Int = 0
    
    var dataCount: Int {
        get {
            return internalQueue.sync {
                _dataCount
            }
        }
        
        set(newValue) {
            internalQueue.async(flags: .barrier) {
                self._dataCount = newValue
            }
        }
    }
    */
    
    
    var _binaryMessenger: FlutterBinaryMessenger?
    var _eventChannels = NSMutableDictionary()
    var _deviceToken: Data?
    
    func initSDK( appId: String, binaryMessenger: FlutterBinaryMessenger, rslt : FlutterResult ){
        _binaryMessenger = binaryMessenger
        let ret = SBDMain.initWithApplicationId(appId);
        rslt( ret );
    }
    
    func connect( uuid: String, token: String, rslt: @escaping FlutterResult ){
        SBDMain.connect( withUserId: uuid, accessToken: token ){ [unowned self] user, error in
            guard user != nil, error == nil else {
                self.connect( uuid:  uuid, token: token, rslt:rslt )
                return
            }
            
            // extension SBDConnectionDelegate
            SBDMain.add( self, identifier: uuid )
            self._registerPushToken()
           // self.registerPUshNotification()
           // self.unreadTrigger.onNext(())
           // self.getDoNotDisturbInformation()
            rslt(true)
        }
    }
    
   func reconnect(){
        SBDMain.reconnect()
    }
    
    func updateCurrentUserInfo( nickname:String, headImageUrl: String, rslt: @escaping FlutterResult){
        SBDMain.updateCurrentUserInfo(withNickname: nickname, profileUrl: headImageUrl) { err in
            if( err != nil ){
                NSLog( err.debugDescription )
                rslt(false)
            }else{
                rslt(true)
            }
        }
    }
    
    func getChannel( isOpen: Bool, url: String, rslt: @escaping FlutterResult ){
        func _do( group: SBDBaseChannel?, e: SBDError? ){
            if( group != nil ){
                var jso = NSMutableDictionary()
                SendBirdUtils.extractChannel(channel: group!, js: &jso)
                rslt( jso )
            }
        }
        
        _runChannel( isOpen: isOpen, url: url , fn: _do )

    }
    
    func enterOpenChannel( url: String, rslt: @escaping FlutterResult ){
        SBDOpenChannel.getWithUrl(url) {channel, err in
            if( err != nil ){
                NSLog("Enter Channel fail error")
                rslt(nil)
            }else{
                channel?.enter() { err in
                    if( err != nil ){
                        NSLog("Enter Channel fail")
                        rslt(nil)
                    }else{
                        var jso = NSMutableDictionary()
                        SendBirdUtils.extractChannel(channel: channel!, js: &jso)
                        rslt( jso )
                    }
                }
            }
        }
    }
    
    func getDoNotDisturb( rslt: @escaping FlutterResult ){
        SBDMain.getDoNotDisturb() { turnOn, startHour, startMin, endHour, endMin, timezone, err in
            if( err != nil ){
                NSLog( err.debugDescription )
                rslt( nil )
                return
            }
            
            let jso = NSMutableDictionary()
            jso["enabled"] = turnOn
            jso["start_hour"] =  startHour
            jso["start_min"] = startMin
            jso["end_hour"] = endHour
            jso["end_min"] = endMin
            jso["timezone"] = timezone
            rslt( jso)
        }
    }

    
    static func jsoToString_( jso :NSDictionary ) -> String{
        do{
            let data = try JSONSerialization.data(withJSONObject: jso, options: .prettyPrinted)
            return String( data:data, encoding: String.Encoding.utf8 )!
        }catch{
            NSLog("JSON encode fail")
            return "{}"
        }
    }
    static func jsArrayToString_( jso :NSArray ) -> NSArray{
        do{
            let ret = NSMutableArray()
            for element in jso{
                ret.add(  element as! NSDictionary )
            }
            return ret
        }catch{
            NSLog("JSON encode fail")
            return NSArray()
        }
    }

    func setDoNotDisturb( enabled: Bool, timeFrom: String, timeEnd: String, rslt: @escaping FlutterResult){
        let startTimeTmp = timeFrom.split(separator: ":")
        let endTimeTmp = timeEnd.split( separator: ":")
        if( startTimeTmp.count < 2 || endTimeTmp.count < 2 ){
            rslt(false)
            return
        }
        let sh = ( startTimeTmp[0] as NSString ).intValue
        let sm = ( startTimeTmp[1] as NSString ).intValue
        let eh = ( endTimeTmp[0] as NSString ).intValue
        let em = ( endTimeTmp[1] as NSString ).intValue
        //guard let sh = Int32( startTimeTmp[0] ) else { return -1 }
        //guard let sm = Int( startTimeTmp[1] ) else { -1 }
        //guard let eh = Int( endTimeTmp[0] ) else { -1 }
        //guard let em = Int( endTimeTmp[1] ) else { -1 }
        if( sh < 0 || sm < 0 || eh < 0 || em < 0 ){
            rslt(false)
            return
        }
        let timezone = TimeZone.current.identifier

        SBDMain.setDoNotDisturbWithEnable(enabled, startHour: sh, startMin: sm, endHour: eh, endMin: em, timezone: timezone) { err in
            if( err == nil ){
                rslt(true)
            }else{
                //NSLog( err. )
            }
        }
        
    }
    
    func _registerPushToken(){
        guard let _deviceToken = _deviceToken else{
            NSLog( "SB device token not set" )
            return
        }
        
        SBDMain.registerDevicePushToken( _deviceToken, unique: false){ status, err in
            switch status{
            case .success:
                NSLog("SB register token success")
            default:
                NSLog("SB register token fail")
            }
        }
    }
    
    func saveDeviceToken( token : Data ){
        _deviceToken = token
    }
    
    func registerPushTokenToSendBird( fcmToken: String, unique: Bool, rslt: @escaping FlutterResult ){
        rslt( true ) // auto register with pending data
      /*  SBDMain.registerDevicePushToken( fcmToken.data(using: String.Encoding.utf8)! , unique: unique){ status , err in
            if ( err !=  nil ){
                rslt( false )
                return
            }
            switch status{
            case .success:
                rslt( true )
                
            default:
                NSLog("SB fcm token update fail")
                rslt( false )
            }
            
        } //completionHandler: <#T##((SBDPushTokenRegistrationStatus, SBDError?) -> Void)?##((SBDPushTokenRegistrationStatus, SBDError?) -> Void)?##(SBDPushTokenRegistrationStatus, SBDError?) -> Void#>)
        */
    }
    
    func unregisterPushTokenToSendBird( rslt: @escaping FlutterResult ){
        if( SBDMain.getConnectState() == .open){
            SBDMain.unregisterAllPushToken(){ rasson, err in
                if( err != nil ){
                    rslt( false )
                }else{
                    rslt( true )
                }
                
            }
        }
    }
    
    func disconnectSendBirdServer(){
        if( SBDMain.getConnectState() == .open){
            SBDMain.disconnect() {
                NSLog("SB disconnected")
            }
        }
    }
    
    func getUsers( userIds: Array<String>, rslt: @escaping FlutterResult ){
        let appUserQuery = SBDMain.createApplicationUserListQuery()
        appUserQuery?.userIdsFilter = userIds
        appUserQuery?.loadNextPage(){ users, err in
            if( err != nil || users == nil){
                rslt("[]")
                return
            }
            let rsltList = NSMutableArray()
            for user in users! {
                let jso = NSMutableDictionary()
                jso["nickname"] = user.nickname
                jso["profile_url"] = user.profileUrl
                jso["is_active"] = user.isActive
                jso["is_online"] = user.connectionStatus == .online
                jso["last_seen_at"] = user.lastSeenAt
                jso["user_id"] = user.userId
                rsltList.add(jso)
            }
            rslt( rsltList )
        }
    }
    
    func fetchChannelList( rslt: @escaping FlutterResult){
        let channelQuery = SBDGroupChannel.createMyGroupChannelListQuery()
        channelQuery?.order = .latestLastMessage
        channelQuery?.includeEmptyChannel = true
        channelQuery?.loadNextPage(){ groups, err in
            if( err != nil ){
                NSLog( err.debugDescription )
                rslt("[]")
                return
            }
            let jsarr = NSMutableArray()
            for grp in groups! {
                var jso = NSMutableDictionary()
                SendBirdUtils.extractChannel(channel: grp, js: &jso)
                jsarr.add(jso)
            }
            rslt( jsarr )
        }
    }
    
    
    
    static func extractChannel( channel: SBDBaseChannel, js: inout NSMutableDictionary ){
        js["cover_url"] = channel.coverUrl
        js["name"] = channel.name
        js["url"] = channel.channelUrl
        js["data"] = channel.data
        js["is_open_channel"] = channel.isOpen()
        switch channel{
        case let opench as SBDOpenChannel:
            js["custom_type"] = opench.customType
        case let groupch as SBDGroupChannel:
            js["is_public"] = groupch.isPublic
            js["custom_type"] = groupch.customType
            js["unread_message_count"] = groupch.unreadMessageCount
            var msg = NSMutableDictionary()
            if( groupch.lastMessage != nil ) {
                extractMessage( msg: groupch.lastMessage!, js: &msg )
            }
            js["last_message"] = msg
            
            let members = NSMutableArray()
            if( groupch.members != nil ) {
                for member in (groupch.members as! [SBDMember] ){
                 let jsmem = NSMutableDictionary()
              
                 jsmem["nickname"] = member.nickname
                 jsmem["user_id"] = member.userId
                 jsmem["profile_url"] = member.profileUrl
                 members.add(jsmem)
              }
            }
            js["members"] = members
            
            let readlist = NSMutableDictionary()
            let readInfo = groupch.getReadStatus(includingAllMembers: true)
            
            // 'getReadStatus' Function may deprecated
            for (k, info) in readInfo {
                let jsinfo = info as NSDictionary
                readlist[k] = jsinfo["last_seen_at"]
            }
            js["read_status"] = readlist
            
        default:
            NSLog("channel extract error")
        }
    }
    
    static func extractMessage( msg: SBDBaseMessage, js: inout NSMutableDictionary ){
        js["created_at"] = msg.createdAt
        js["data"] = msg.data
        js["message_id"] = msg.messageId
        switch msg {
        case let umsg as SBDUserMessage:
            js["type"] = "USER"
            js["message"] = umsg.message
            js["sender_id"] = umsg.sender?.userId
            js["sender_profile_url"] = umsg.sender?.profileUrl
            js["sender_nickname"] = umsg.sender?.nickname
            js["custom_type"] = umsg.customType
            if( umsg.mentionType == SBDMentionType.users ){
                if( umsg.mentionedUsers != nil ){
                    let users = NSMutableArray()
                    for user in umsg.mentionedUsers!{
                        users.add( user.userId )
                    }
                    js["mentioned_user_ids"] = users
                }
            }
        case let amsg as SBDAdminMessage:
            js["type"] = "ADMIN"
            js["message"] = amsg.message
        case let fmsg as SBDFileMessage:
            js["type"] = "FILE"
            js["name"] = fmsg.name
            js["request_id"] = fmsg.requestId
            js["sender_id"] = fmsg.sender?.userId
            js["sender_profile_url"] = fmsg.sender?.profileUrl
            js["sender_nickname"] = fmsg.sender?.nickname
            js["custom_type"] = fmsg.customType
            js["file_type"] = fmsg.type
            js["url"] = fmsg.url
        default:
            NSLog("message type error")
        }
    }
    
    
    func listenChannelMessage( handlerId: String, rslt: @escaping FlutterResult ){
        var event = FlutterEventChannel(name: handlerId, binaryMessenger: _binaryMessenger! )
        _eventChannels[handlerId] = event
        rslt(handlerId)
        
  
        
        // onLiten, onCancel
        event.setStreamHandler( EventHandler(name: handlerId) )
        
    }
    
    func removeEventHandler( name: String ){
        _eventChannels.removeObject(forKey: name)
    }
    
    var messageQuery = NSMutableDictionary()
    
    func _handleGetChannelMessages( msgs: [SBDBaseMessage]?, rslt: FlutterResult ){
        guard let msgs = msgs else {
            return
        }
        
        let retList = NSMutableArray()
        for msg in msgs {
            var jsmsg = NSMutableDictionary()
            SendBirdUtils.extractMessage(msg: msg, js: &jsmsg)
            retList.add( jsmsg )
        }
        rslt( retList )
    }
    
    func getLastMessages( isOpen: Bool, queryId: String, url: String, cnt: Int, rslt: @escaping FlutterResult){
        func _do( channel: SBDBaseChannel?, err: SBDError? ){
            var query: SBDPreviousMessageListQuery? = messageQuery[queryId] as? SBDPreviousMessageListQuery
            
            if ( query == nil ){
                query = channel?.createPreviousMessageListQuery()
                messageQuery[queryId] = query
            }
            
            query?.load(){ msgs, err in
                self._handleGetChannelMessages( msgs: msgs, rslt: rslt )
            }
            
        }
        
        _runChannel( isOpen: isOpen, url: url , fn: _do )
    }
    
    func getMessagesByTimestamp( isOpen: Bool, url: String, timeStamp: Int64,
                                 revertSoft: Bool, cnt: Int, customType: String, rslt: @escaping FlutterResult){
        func _do( channel: SBDBaseChannel?, err: SBDError? ){
            
            channel?.getPreviousMessages(byTimestamp: timeStamp, limit: cnt, reverse: revertSoft){ msgs, err in
            
                self._handleGetChannelMessages(msgs: msgs, rslt: rslt)
            }
        }
        
        _runChannel( isOpen: isOpen, url: url , fn: _do )
    }
    
    func getMessagesByMsgId( isOpen: Bool, url: String, msgId: Int64,
                             revertSoft: Bool, forward: Bool,
                             cnt: Int, customType: String, rslt: @escaping FlutterResult){
        func _do( channel: SBDBaseChannel?, err: SBDError? ){
            
            if( forward ){
                channel?.getNextMessages(byMessageId: msgId, limit: cnt, reverse: revertSoft,
                                             messageType:SBDMessageTypeFilter.all,
                                             customType: customType ){ msgs, err in
                
                    self._handleGetChannelMessages(msgs: msgs, rslt: rslt)
                }

                
            }else{
                channel?.getPreviousMessages(byMessageId: msgId, limit: cnt, reverse: revertSoft,
                                             messageType:SBDMessageTypeFilter.all,
                                             customType: customType){ msgs, err in
                
                    self._handleGetChannelMessages(msgs: msgs, rslt: rslt)
                }

            }
            
        }
        
        _runChannel( isOpen: isOpen, url: url , fn: _do )
    }
    func getMessageChangeLogsByTimestamp( isOpen: Bool, url: String, timestamp: Int64, rslt: @escaping FlutterResult ){
        func _do( channel: SBDBaseChannel?, err: SBDError?){

            channel?.getMessageChangeLogs(byTimestamp: timestamp, includeMetaArray: true ){
                messageList, deletedIds, hasMore, token, err in
                SendBirdUtils._handleChangeLogs(messageList: messageList, deletedIds: deletedIds, hasMore: hasMore, token: token, rslt: rslt)
            }
            
        }
        _runChannel(isOpen: isOpen, url: url, fn: _do )
    }
    
    func getMessageChangeLogsByToken( isOpen: Bool, url: String, token: String, rslt: @escaping FlutterResult ){
        func _do( channel: SBDBaseChannel?, err: SBDError?){

            channel?.getMessageChangeLogs(withToken: token, includeMetaArray: true){
                messageList, deletedIds, hasMore, token, err in
                SendBirdUtils._handleChangeLogs(messageList: messageList, deletedIds: deletedIds, hasMore: hasMore, token: token, rslt: rslt)

            }
                        
        }
        _runChannel(isOpen: isOpen, url: url, fn: _do )
    }
    
    static func _handleChangeLogs( messageList: [SBDBaseMessage]?, deletedIds: [NSNumber]?, hasMore: Bool, token: String?, rslt: FlutterResult ){
        let jsarr = NSMutableArray()
        for msg in messageList! {
            var jso = NSMutableDictionary()
            SendBirdUtils.extractMessage(msg: msg, js: &jso)
            jsarr.add(jso)
        }
         let ret = NSMutableDictionary()
         ret["updated"] = jsarr
         ret["delete"] = deletedIds
         ret["has_more"] = hasMore
         ret["query_token"] = token
         rslt( ret )
    }
    
    func sendUserMessage( isOpen: Bool, url: String, customType: String,
                          message: String, userData: String,
                          metionUsers: [String], rslt: @escaping FlutterResult ){
        func _do( channel: SBDBaseChannel?, err: SBDError? ){
            let msg = SBDUserMessageParams(message: message)!
            msg.customType = customType
            msg.data = userData
            if( metionUsers.count > 0){
                msg.mentionType = .users
                msg.mentionedUserIds = metionUsers
            }
            
            
            channel?.sendUserMessage(  with: msg){ sentMsg, err in
                if( sentMsg != nil && err == nil ){
                    var jso = NSMutableDictionary()
                    SendBirdUtils.extractMessage(msg: sentMsg!, js: &jso)
                    rslt( jso )
                }
            }
        }
        _runChannel( isOpen: isOpen, url: url , fn: _do )
    }
    
    func _runChannel( isOpen: Bool, url: String, fn: @escaping (_ channel: SBDBaseChannel?, _ err: SBDError?)->() ){
        if( isOpen ){
            SBDOpenChannel.getWithUrl( url)  { channel, err in
                fn( channel, err )
            }
        }else{
            SBDGroupChannel.getWithUrl( url ) { channel, err in
                fn( channel, err )
            }
        }
    }
    
    func updateUserMessage( isOpen: Bool, url: String, customType: String,
                            msgId: Int64,  message: String, userData: String,
                             rslt: @escaping FlutterResult ){
           func _do( channel: SBDBaseChannel?, err: SBDError? ){
               let msg = SBDUserMessageParams(message: message)!
               msg.customType = customType
               msg.data = userData
               
            channel?.updateUserMessage( withMessageId: msgId,
                                        userMessageParams: msg) { sentMsg, err in
                   if( sentMsg != nil && err == nil ){
                       var jso = NSMutableDictionary()
                       SendBirdUtils.extractMessage(msg: sentMsg!, js: &jso)
                       rslt( jso )
                   }
               }
           }
           
            _runChannel( isOpen: isOpen, url: url , fn: _do )

       }
    

    func sendFileMessage( isOpen: Bool, url: String, customType: String,
                          message: String, userData: String, filePath: String, fileType: String, 
                          metionUsers: [String], rslt: @escaping FlutterResult
                          ){
        let uuid = UUID().uuidString
        let event = FlutterEventChannel(name: filePath, binaryMessenger: _binaryMessenger! )
        //_eventChannels[uuid] = event
        let jso = NSMutableDictionary()
        jso["channel"] = uuid
        let data = jso
        rslt( data )
        
        func _do( channel: SBDBaseChannel?, err: SBDError? ){
            
            event.setStreamHandler( FileMessageStreamHandler( uuid, createdFunc: { evt in

                
                channel?.sendFileMessage(withFilePath: filePath, type: message, thumbnailSizes: nil,
                                         data: nil, customType: customType, progressHandler: { _, sent, total in
                    let jso = NSMutableDictionary()
                    jso["event"] = "progress"
                    jso["total_sent"] = sent
                    jso["total_bytes"] = total
                    evt( jso )
                }, completionHandler: {msg, err in
                    if( msg == nil ){
                        evt( { "error: sendbird unknown error"} )
                    }else{
                        let jso = NSMutableDictionary()
                        var jsmsg = NSMutableDictionary()
                        SendBirdUtils.extractMessage(msg: msg!, js: &jsmsg)
                        jso["event"] = "onsent"
                        jso["msg"] = jsmsg
                        evt( jso)
                    }
                        
                })
            }))
            
            
            
        }
        
        _runChannel( isOpen: isOpen, url: url , fn: _do )

  
    }
    
    func markAsRead( url: String, rslt: @escaping FlutterResult ){
        SBDGroupChannel.getWithUrl(url){ channel, err in
            channel?.markAsRead()
            if( err == nil ){
                rslt( true )
            }
        }
    }
    
    func createChannelWithUserIds( uids:[String], isDistinct: Bool, rslt: @escaping FlutterResult ){
        SBDGroupChannel.createChannel(withUserIds: uids, isDistinct: isDistinct){
           channel, err in
            if( err != nil ){
                NSLog( err!.debugDescription )
                return
            }
            
            var jso = NSMutableDictionary()
            SendBirdUtils.extractChannel(channel: channel!, js: &jso)
            rslt( jso )
        }
    }
    
    
    
}


class FileMessageStreamHandler :NSObject,  FlutterStreamHandler{

    var event: FlutterEventSink?
    var handlerName: String = ""
    var onCreated: ( _ event: @escaping FlutterEventSink )->()
    
    //convenience
    init( _ name: String,  createdFunc: @escaping (@escaping FlutterEventSink )->() ){
        //super.init()
        handlerName = name
        onCreated = createdFunc
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        event = events
        onCreated( event! )
        
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
                
        return nil
    }
}

class EventHandler :NSObject,  FlutterStreamHandler, SBDChannelDelegate{
      
      var event: FlutterEventSink?
      var handlerName: String = ""
      
      //convenience
      init( name: String ){
          super.init()
          handlerName = name
      }
      
      func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
          event = events
          SBDMain.add( self, identifier: handlerName)
          return nil
      }
      func onCancel(withArguments arguments: Any?) -> FlutterError? {
          SendBirdUtils.sharedInstance.removeEventHandler(name: handlerName )
          SBDMain.removeChannelDelegate(forIdentifier: handlerName )
          return nil
      }
      
      func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
          guard let event = event else{
              return
          }
          
          var jso = NSMutableDictionary()
          jso["event"] = "messageReceived"
          jso["channel_url"] = sender.channelUrl
          jso["is_open_channel"] = sender.isOpen()
          SendBirdUtils.extractMessage(msg: message, js: &jso)
          event( jso )
      }
      func channel(_ sender: SBDOpenChannel, userDidEnter user: SBDUser) {
          guard let event = event else{
              return
          }
          let jso = NSMutableDictionary()
          jso["event"] = "userEntered"
          jso["user_id"] = user.userId
          jso["nickname"] = user.nickname
          jso["profile_url"] = user.profileUrl
          jso["channel_url"] = sender.channelUrl
          event( jso )
      }
    
    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        guard let event = event else{
            return
        }
        let jso = NSMutableDictionary()
        jso["event"] = "userJoined"
        jso["user_id"] = user.userId
        jso["nickname"] = user.nickname
        jso["profile_url"] = user.profileUrl
        jso["channel_url"] = sender.channelUrl
        event( jso )
    }
    
    func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
        guard let event = event else{
            return
        }
        let jso = NSMutableDictionary()
        jso["event"] = "readReceiptUpdate"
        jso["channel_url"] = sender.channelUrl
        var jsChannel = NSMutableDictionary()
        SendBirdUtils.extractChannel(channel: sender, js: &jsChannel)
        jso["channel"] = jsChannel
        event( jso )
        
    }
    
    func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        guard let event = event else{
            return
        }
        let jso = NSMutableDictionary()
        jso["event"] = "typingStatusUpdated"
        jso["is_typing"] = sender.isTyping()
        jso["channel_url"] = sender.channelUrl
        event( jso )
    }
    
    func channel(_ sender: SBDBaseChannel, didUpdate message: SBDBaseMessage) {
        guard let event = event else{
            return
        }
        var jso = NSMutableDictionary()
        jso["event"] = "messageUpdated"
        jso["channel_url"] = sender.channelUrl
        jso["is_open_channel"] = sender.isOpen()
        SendBirdUtils.extractMessage(msg: message, js: &jso)
        event( jso )
    }
    
    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        guard let event = event else{
            return
        }
        let jso = NSMutableDictionary()
        jso["event"] = "messageDeleted"
        jso["channel_url"] = sender.channelUrl
        jso["message_id"] = messageId
        event( jso )
    }
    
  }


// SBDConnectionDelegate, SBDMAIN.add
extension SendBirdUtils : SBDConnectionDelegate {
    func didStartReconnection() {
        NSLog("SB Connection Started")
    }
    func didFailReconnection() {
        NSLog("SB Connection Fail")
    }
    func didSucceedReconnection() {
        NSLog("SB Connection Connected")

    }
    func didCancelReconnection() {
        NSLog("SB Connection Cancel")
    }
   
}



