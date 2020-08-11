package com.sstar.flutter_sendbird

/*
import com.sensestar.mermaids.BuildConfig
import com.sensestar.mermaids.cache.MyUserInfo
import com.sensestar.mermaids.objects.PreferenceKey
import com.sensestar.mermaids.record.BasicConfig
import kotlinx.coroutines.delay
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch*/
import android.content.Context
import android.util.Log
import com.sendbird.android.*
import com.sendbird.android.shadow.com.google.gson.JsonArray
import com.sendbird.android.shadow.com.google.gson.JsonObject
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterView
import java.io.File
import java.util.*


object SendBirdUtils {
    private const val MAX_REGISTER_FCM_RETRY_TIMES = 100
    private var registerFcmTokenTimes = 0
    var _flutterBinaryMessenger : BinaryMessenger? = null
    var _eventChannl : MutableMap<String, EventChannel> = mutableMapOf<String, EventChannel>()

    fun init( appId: String, context: Context, flutterBinaryMessnger: BinaryMessenger ) : Boolean{
        _flutterBinaryMessenger = flutterBinaryMessnger
         return SendBird.init( appId, context )
    }

    fun connectToSendBird(userId: String, accessToken: String, result : MethodChannel.Result) {
        Log.d(SendBirdUtils::class.java.simpleName, "$userId connect to message server !!")

        SendBird.connect(userId, accessToken, SendBird.ConnectHandler { _, e ->
            //Log.d(SendBirdUtils::class.java.simpleName, "connect error e : $e")
            if (e != null) {
                result.success( false )
                return@ConnectHandler
            } else {
                result.success( true )
                // Log.d(SendBirdUtils::class.java.simpleName, "Message server openChannelConnected $userId")
            }
        })
    }

     fun reconnect(){
        SendBird.reconnect()
    }

    fun updateCurrentUserInfo(nickName: String, headImageUrl: String, result :MethodChannel.Result ) {
        SendBird.updateCurrentUserInfo(nickName, headImageUrl, SendBird.UserInfoUpdateHandler { e ->
            Log.d(SendBirdUtils::class.java.simpleName, "updateCurrentUserInfo error e : $e")
            if (e != null) {    // Error.
                return@UserInfoUpdateHandler
            } else {
                //do nothing
                Log.d(SendBirdUtils::class.java.simpleName, "updateCurrentUserInfo OK!!")
                result.success( true )
            }
        })
    }

    fun getChannel( isOpen : Boolean, url: String, result :MethodChannel.Result ){
        val f = { group: BaseChannel?, e: SendBirdException? ->
            val jso = HashMap<String,Any>()
            if( group != null ) {
                extractChannel(group, jso)
                result.success( jso )
            }
        }
        _runChannel( isOpen, url, f )
    }

    fun enterOpenChannel(channelUrl: String, result :MethodChannel.Result ) {
        OpenChannel.getChannel(channelUrl) { openChannel, e ->
            Log.d(SendBirdUtils::class.java.simpleName, "enterOpenChannel error e : $e")
            if (e != null) {
                result.error( "Sendbird", e.toString(), e.code.toString() )
                // Error.
            } else {
                Log.d(SendBirdUtils::class.java.simpleName, "enterOpenChannel openChannel : $openChannel")
                openChannel.enter { e ->
                    Log.d(SendBirdUtils::class.java.simpleName, "enter openChannel error e : $e")
                    if (e != null) {
                        // Error.
                        result.error( "Sendbird", e.toString(), e.code.toString() )
                    } else {
                        Log.d(SendBirdUtils::class.java.simpleName, "Enter openChannel '${openChannel.name}' !!")
                        // openChannelManagementHandler?.onOpenChannelConnected()
                        val jso = HashMap<String,Any>()
                        extractChannel( openChannel, jso )
                        result.success( jso )
                    }
                }
            }
        }
    }

    fun addConnectionManagementHandler(handlerId: String) {
        SendBird.addConnectionHandler(handlerId, object : SendBird.ConnectionHandler {
            override fun onReconnectStarted() {}
            override fun onReconnectFailed() {}
            override fun onReconnectSucceeded() {
            }
        })
    }

    fun getDoNotDisturb( result :MethodChannel.Result ) {
        SendBird.getDoNotDisturb { isDoNotDisturbOn, startHour, startMin, endHour, endMin, timezone, e ->
            if (e != null) {
                return@getDoNotDisturb
            }

            val calendar = Calendar.getInstance(Locale.getDefault())
            calendar.clear()
            calendar.set(Calendar.HOUR_OF_DAY, startHour)
            calendar.set(Calendar.MINUTE, startMin)
            val fromMillis = calendar.timeInMillis
            calendar.clear()
            calendar.set(Calendar.HOUR_OF_DAY, endHour)
            calendar.set(Calendar.MINUTE, endMin)
            val toMillis = calendar.timeInMillis

            val jso = HashMap<String,Any>()
            jso["enabled"]= isDoNotDisturbOn
            jso["start_hour"]= startHour
            jso["start_min"]= startMin
            jso["end_hour"]= endHour
            jso["end_min"]= endMin
            jso["timezone"]= timezone

            result.success( jso )
        }
    }

    fun setDoNotDisturb(doNotDisturb: Boolean, doNotDisturbFrom: String, doNotDisturbTo: String, result :MethodChannel.Result ) {
        if (doNotDisturbFrom.isNotEmpty() && doNotDisturbTo.isNotEmpty()) {
            val startHour = DateUtils.getHourOfDay(java.lang.Long.valueOf(doNotDisturbFrom))
            val startMin = DateUtils.getMinute(java.lang.Long.valueOf(doNotDisturbFrom))
            val endHour = DateUtils.getHourOfDay(java.lang.Long.valueOf(doNotDisturbTo))
            val endMin = DateUtils.getMinute(java.lang.Long.valueOf(doNotDisturbTo))
            SendBird.setDoNotDisturb(doNotDisturb, startHour, startMin, endHour, endMin, TimeZone.getDefault().id) {e ->
                if( e.code == 0 )
                    result.success( true )
            }
        }
    }

    fun registerPushTokenToSendBird( fcmToken : String, resutl :MethodChannel.Result ) {
        SendBird.registerPushTokenForCurrentUser(fcmToken, SendBird.RegisterPushTokenWithStatusHandler { ptrs, e ->
            if (e != null) {
                return@RegisterPushTokenWithStatusHandler
            }

            // Log.d(SendBirdUtils::class.java.simpleName, "ptrs $ptrs , e $e")

            if (ptrs == SendBird.PushTokenRegistrationStatus.PENDING) {
                // A token registration is pending.
                // Retry the registration after a connection has been successfully established.
                //TODO: PENDING retry
                /*
                GlobalScope.launch {
                    if (registerFcmTokenTimes < MAX_REGISTER_FCM_RETRY_TIMES) {
                        delay(3000)
                        registerFcmTokenTimes++
                        registerPushTokenToSendBird()
                    } else {
                        registerFcmTokenTimes = 0
                        return@launch
                    }
                }
                */
                Log.d( "sendbird", "registerToken error" )
                resutl.error( "sendbird", "registeToken error", null )
            }else{
                resutl.success( true )
                Log.d( "sendbird", "registerToken success" )
            }
        })
    }

    fun getUsers(userList: List<String>, result: MethodChannel.Result ){

        val userListQuery = SendBird.createApplicationUserListQuery()
        userListQuery.setUserIdsFilter(userList)
        //userListQuery?.next { p0, p1 ->
        //}
        userListQuery?.next( object: UserListQuery.UserListQueryResultHandler {
            override
            fun onResult(p0: MutableList<User>? , p1: SendBirdException?) {
                val jslist = mutableListOf<Any>();
                p0?.forEach { user ->

                    val jso = HashMap<String,Any>()
                    jso["nickname"]= user.nickname
                    jso["profile_url"]= user.profileUrl
                    jso["is_active"]= user.isActive
                    jso["is_online"]= user.connectionStatus == User.ConnectionStatus.ONLINE
                    jso["last_seen_at"]= user.lastSeenAt
                    jso["user_id"]=user.userId
                    jslist.add(jso)
                }
                result.success(jslist)
            }}
        )
    }

    fun unregisterPushTokenToSendBird() {
        if( SendBird.getConnectionState() == SendBird.ConnectionState.OPEN  ) {
            SendBird.unregisterPushTokenAllForCurrentUser(SendBird.UnregisterPushTokenHandler { e ->
                if (e != null) {    // Error.
                    return@UnregisterPushTokenHandler
                }
            })
        }
    }

    fun disconnectSendBirdServer() {
        if( SendBird.getConnectionState() == SendBird.ConnectionState.OPEN  ) {
            SendBird.disconnect {
                Log.d(SendBirdUtils::class.java.simpleName, "Current user is disconnected !!")
            }
        }
    }

    fun removeConnectionManagementHandler(handlerId: String) {
        SendBird.removeConnectionHandler(handlerId)
    }

    fun fetchChannelList( result :MethodChannel.Result ) {
        val channelListQuery = GroupChannel.createMyGroupChannelListQuery()
        channelListQuery.order = GroupChannelListQuery.Order.LATEST_LAST_MESSAGE
        channelListQuery.isIncludeEmpty = true
        channelListQuery.next { list, e ->
            if (e != null) {    // Error.
                result.error("sendbird", e.toString(), null )
            } else {
                val ret = mutableListOf<Any>()
                for( channel in list ){
                    val jso = HashMap<String,Any>()
                    extractChannel(channel, jso )
                    ret.add(jso)
                }
                result.success( ret )
            }
        }
    }

    private fun extractChannel( baseChannel: BaseChannel, jso: HashMap<String,Any> ){
        jso["cover_url"]= baseChannel.coverUrl
        jso["name"]= baseChannel.name
        jso["url"]= baseChannel.url
        jso["data"]= baseChannel.data
        jso["is_open_channel"]= baseChannel.isOpenChannel

        when( baseChannel )
        {
            is GroupChannel ->{
                val channel = baseChannel as GroupChannel
                jso["is_public"]= channel.isPublic
                jso["custom_type"]= channel.customType
                jso["unread_message_count"]= channel.getUnreadMessageCount()
                val jsmsg = HashMap<String,Any>()
                if( channel.lastMessage != null ) {
                    extractMessage(channel.lastMessage, jsmsg)
                }
                jso["last_message"] = jsmsg

                val userlist = mutableListOf<Any>()
                for( member in channel.members ){
                    var usr = HashMap<String,Any>()
                    usr[ "nickname"]= member.nickname
                    usr[ "user_id"]= member.userId
                    usr[ "profile_url"]= member.profileUrl
                    userlist.add( usr )
                }
                jso[ "members"]= userlist

                var readlist = HashMap<String, Long >()
                val reads = channel.getReadStatus( true );
                reads.forEach {iter ->
                    val userid = iter.key
                    val readstate = iter.value
                    readlist[ userid ] =  readstate.timestamp
                }
                jso["read_status"]= readlist
                //for( k)

                //}
            }
            is OpenChannel ->{
                var channel = baseChannel as OpenChannel
                jso[ "custom_type"] = channel.customType

            }
        }

    }

    private fun extractMessage( message: BaseMessage, json: HashMap<String,Any> ) {
        json["created_at"] = message.createdAt
        json["data"] = message.data
        json["message_id"]= message.messageId

        when (message) {
            is UserMessage -> {
                var umsg = message as UserMessage
                json[ "type"] = "USER"
                json[ "message" ] = umsg.message
                json["sender_id"] =  umsg.sender.userId
                json["sender_profile_url"] = umsg.sender.profileUrl
                json["sender_nickname"]= umsg.sender.nickname
                json["custom_type"] = umsg.customType
                if (message.mentionType == BaseMessageParams.MentionType.USERS) {
                    val array = mutableListOf<String>()
                    message.mentionedUsers.forEach{
                        array.add( it.userId )
                    }
                    json[ "mentioned_user_ids"] = array
                }
            }
            is AdminMessage -> {
                var amsg = message as AdminMessage;
                json[ "type"] = "ADMIN"
                json [ "message"] =  amsg.message
            }
            is FileMessage -> {
                var fmsg = message as FileMessage;
                json[ "type"] = "FILE"
                json[ "name" ] = fmsg.name
                json[ "request_id" ] = fmsg.requestId
                json[ "sender_id" ] = fmsg.sender.userId
                json[ "sender_profile_url" ] = fmsg.sender.profileUrl
                json[ "sender_nickname" ] = fmsg.sender.nickname
                json[ "custom_type" ] = fmsg.customType
                json[ "file_type" ] = fmsg.type
                json[ "url" ] = fmsg.url
            }
        }
    }

    fun listenChannelMessage( handlerId: String, result: MethodChannel.Result ){
        val channel = EventChannel( _flutterBinaryMessenger, handlerId)
        _eventChannl[ handlerId ] = channel
        Log.d("sendbird","sethandler")
        result.success(handlerId)
        channel.setStreamHandler(
            object: EventChannel.StreamHandler {
                override fun onListen(args : Any?, p1: EventChannel.EventSink? ) {
                    Log.d("sendbird","onlisten")
                    if( p1 == null ) {
                        Log.d("sendbird","onlisten unknown error")
                        return
                    }
                    val events = p1!!
                    SendBird.addChannelHandler( handlerId, object: SendBird.ChannelHandler(){
                        override fun onMessageReceived( channel: BaseChannel?, message: BaseMessage?) {
                            Log.d("sendbird","listen message")
                            val js = HashMap<String,Any>()
                            if( channel != null && message != null  ) {
                                js["event"]= "messageReceived"
                                js["channel_url"]= channel.url
                                js["is_open_channel"]= channel.isOpenChannel
                                extractMessage( message, js )
                                events.success( js )
                            }
                        }
                        override fun onUserEntered(channel: OpenChannel?, user: User?) {
                            var js = HashMap<String,Any>()
                            if( channel != null && user != null  ) {
                                js["event"]= "userEntered"
                                js["user_id"]= user.userId
                                js["nickname"]= user.nickname
                                js["profile_url"]= user.profileUrl
                                js["channel_url"]= channel.url
                                events.success( js )
                            }
                        }
                        override fun onUserJoined(channel: GroupChannel?, user: User?) {
                            var js = HashMap<String,Any>()
                            if( channel != null && user != null  ) {
                                js["event"]= "userJoined"
                                js["user_id"]= user.userId
                                js["nickname"]= user.nickname
                                js["profile_url"]= user.profileUrl
                                js["channel_url"]= channel.url
                                events.success( js )
                            }
                        }

                        override fun onReadReceiptUpdated(channel: GroupChannel?) {
                            var js = HashMap<String,Any>()
                            if( channel != null  ) {
                                js["event"]="readReceiptUpdate"
                                js["channel_url"]=channel.url
                                var jsChannel = HashMap<String,Any>()
                                extractChannel( channel, jsChannel )
                                js["channel"]=jsChannel
                                events.success( js )
                            }
                        }

                        override fun onTypingStatusUpdated(channel: GroupChannel?) {
                            var js = HashMap<String,Any>()
                            if( channel != null  ) {
                                js["event"]="typingStatusUpdated"
                                js["is_typing"]=channel.isTyping
                                js["channel_url"]=channel.url
                                events.success( js )
                            }
                        }

                        override fun onMessageUpdated(channel: BaseChannel?, message: BaseMessage?) {
                            var js = HashMap<String,Any>()
                            if( channel != null && message != null  ) {
                                js["event"]="messageUpdated"
                                js["channel_url"]=channel.url
                                js["is_open_channel"]=channel.isOpenChannel
                                extractMessage( message, js )
                                events.success( js )
                            }
                        }

                        override fun onMessageDeleted(channel: BaseChannel?, msgId: Long) {
                            var js = HashMap<String,Any>()

                            if( channel != null ) {
                                js["event"]="messageDeleted"
                                js["channel_url"]=channel.url
                                js["message_id"]=msgId
                                events.success( js )
                            }
                        }
                    })
                }

                override fun
                onCancel(args: Any?) {
                    _eventChannl.remove( handlerId )
                    SendBird.removeChannelHandler( handlerId )
                }
            }
        )// setHandler
    }

    private  fun _handleGetChannelMessage(messages: List<BaseMessage>, result: MethodChannel.Result  ) {
        var retList = mutableListOf<Any>()
        for( msg in messages ){
            var js = HashMap<String,Any>()
            extractMessage( msg, js )
            retList.add( js );
        }
        result.success( retList )
    }

    private fun _messagesToJsonList( messages: List<BaseMessage> ): MutableList<Any>{
        var retList = mutableListOf<Any>()
        for( msg in messages ){
            var js = HashMap<String,Any>()
            extractMessage( msg, js )
            retList.add( js );
        }
        return retList;
    }

    fun getMessagesByTimestamp( isOpenChannel: Boolean, groupUrl: String, timeStamp: Long, revertSort: Boolean, cnt : Int, customType: String, result: MethodChannel.Result ){

        val f = { group :BaseChannel, e: SendBirdException?  ->
            if (e == null) {
                group.getPreviousMessagesByTimestamp(timeStamp, false, cnt, revertSort, BaseChannel.MessageTypeFilter.ALL, customType) { messages, e2 ->
                    if (e2 == null) {
                        _handleGetChannelMessage(messages, result)
                    } else {
                        result.error("Sendbird", e2.toString(), null)
                    }
                }
            } else {
                result.error("Sendbird", e.toString(), null)
            }
        }


        _runChannel( isOpenChannel, groupUrl, f )

    }

    fun getMessagesByMsgId( isOpenChannel: Boolean, groupUrl: String, msgId: Long, revertSort: Boolean, forward: Boolean, cnt : Int,  customType: String, result: MethodChannel.Result ){

        val f = { group :BaseChannel, e: SendBirdException?  ->
            if (e == null) {
                if( forward ){
                    group.getNextMessagesById(msgId, false, cnt, revertSort, BaseChannel.MessageTypeFilter.ALL, customType) { messages, e2 ->
                        if (e2 == null) {
                            _handleGetChannelMessage(messages, result)
                        } else {
                            result.error("Sendbird", e2.toString(), null)
                        }
                    }
                }else {
                    group.getPreviousMessagesById(msgId, false, cnt, revertSort, BaseChannel.MessageTypeFilter.ALL, customType) { messages, e2 ->
                        if (e2 == null) {
                            _handleGetChannelMessage(messages, result)
                        } else {
                            result.error("Sendbird", e2.toString(), null)
                        }
                    }
                }
            } else {
                result.error("Sendbird", e.toString(), null)
            }
        }


        _runChannel( isOpenChannel, groupUrl, f )

    }

    private fun _runChannel( isOpenChannel: Boolean, groupUrl: String, fn: (BaseChannel, SendBirdException? )->Unit ){
         if( isOpenChannel ){
             OpenChannel.getChannel( groupUrl ) { group, e ->
                 fn( group, e )
             }
         }else {
             GroupChannel.getChannel(groupUrl) { group, e ->
                 fn( group, e )
             }
         }
    }

    fun _handleChangeLogs( group: BaseChannel,
                           updatedList: List<BaseMessage> , deletedList: List<Long>,
                           hasMore: Boolean, token: String,
                           e: SendBirdException?, result: MethodChannel.Result ){
        if (e == null) {
            var updatedMessages = _messagesToJsonList( updatedList )
            var retObj =  HashMap<String,Any>()
            retObj["updated"]=updatedMessages
            var deletedIds = mutableListOf<Long>()
            for( id in deletedList ){
                deletedIds.add( id )
            }

            retObj["delete"]=deletedIds
            retObj["has_more"]=hasMore
            retObj["query_token"]=token
            result.success( retObj )

        } else {
            result.error("Sendbird", e.toString(), null)
        }

    }

    fun getMessageChangeLogsByToken(isOpenChannel: Boolean, groupUrl: String, token: String, result: MethodChannel.Result){
        val f = { group: BaseChannel, e: SendBirdException? ->
            if( e == null ) {
                group.getMessageChangeLogsByToken( token, true ){ updatedList, deletedList, hasMore, token, e->
                    _handleChangeLogs( group,updatedList, deletedList, hasMore, token, e, result )
                }
            } else {
                result.error("Sendbird", e.toString(), null)
            }
        }

        _runChannel( isOpenChannel, groupUrl, f )
    }

    fun getMessageChangeLogsByTimeStamp( isOpenChannel: Boolean, groupUrl: String, timeStamp: Long, result: MethodChannel.Result ){
        val f = { group: BaseChannel, e: SendBirdException? ->
            if( e == null ){
                group.getMessageChangeLogsByTimestamp( timeStamp, true) { updatedList, deletedList, hasMore, token, e->
                    _handleChangeLogs( group, updatedList, deletedList, hasMore, token, e, result )
                }
            } else {
                result.error("Sendbird", e.toString(), null)
            }
        }

        _runChannel( isOpenChannel, groupUrl, f )
    }

    var queryHandler = mutableMapOf<String, PreviousMessageListQuery>()

    fun getLastMessages( isOpen: Boolean, qid: String,  url : String , cnt : Int, result: MethodChannel.Result  ){
        val f = { group :BaseChannel, e: SendBirdException?  ->
            var query : PreviousMessageListQuery?
            if( queryHandler.containsKey(qid) ){
                query = queryHandler[qid]
            }else{
                query = group?.createPreviousMessageListQuery() // this query could use again to fetch all
                if( query != null )
                    queryHandler[qid] = query
            }
            if( e != null ) {
                Log.d("Sendbird", e.toString())
            }
            query?.load( cnt, true ) { messages, e ->
                if( e == null ) {
                    _handleGetChannelMessage(messages, result)
                }
            }
            Unit
        }

        _runChannel( isOpen, url, f )


    }

    fun sendUserMessage( isOpen: Boolean, url :String, customType :String,
                         message: String, userData: String,
                         metionUsers :List<String>, result: MethodChannel.Result ){
        val f = { group: BaseChannel?, e: SendBirdException? ->
            var msg = UserMessageParams()
                    .setMessage(message)
                    .setCustomType(customType)
                    .setData(userData)

            if( metionUsers.count() > 0 ){
                msg.setMentionType(  BaseMessageParams.MentionType.USERS )
                msg.setMentionedUserIds( metionUsers )
            }

            group?.sendUserMessage( msg ) { sentMsg, e ->
                if( e == null ){
                    if( sentMsg != null ) {
                        var js = HashMap<String,Any>()
                        extractMessage( sentMsg, js)
                        result.success( js )
                    }
                }
            }
            Unit
        }
        _runChannel( isOpen, url, f )

    }

    fun updateUserMessage( isOpen: Boolean, url :String, customType :String,
                         msgId: Long, message: String, userData: String,
                         result: MethodChannel.Result ){
        val f = { group: BaseChannel?, e: SendBirdException? ->
            val msg = UserMessageParams()
                    .setMessage(message)
                    .setCustomType(customType)
                    .setData(userData)

            group?.updateUserMessage( msgId, msg ) { sentMsg, e ->
                if( e == null ){
                    if( sentMsg != null ) {
                        val js = HashMap<String,Any>()
                        extractMessage( sentMsg, js)
                        result.success( js )
                    }
                }
            }

            Unit
        }

        _runChannel( isOpen, url, f )



    }    

    fun createStreamChannel(  handlerId: String,  onListen: ( e: EventChannel.EventSink ) -> Unit ) : EventChannel  {
        var channel = EventChannel( _flutterBinaryMessenger, handlerId)
        // _eventChannl[ handlerId ] = channel
        Log.d("sendbird","sethandler")

        channel.setStreamHandler(
                object: EventChannel.StreamHandler {
                    override fun onListen(args: Any?, p1: EventChannel.EventSink?) {
                        Log.d("sendbird", "onlisten")
                        if (p1 == null) {
                            Log.d("sendbird", "onlisten unknown error")
                            return
                        }
                        val events = p1!!
                        onListen( events )
                    }
                    override fun onCancel(args: Any?) {
                        _eventChannl.remove( handlerId )
                        SendBird.removeChannelHandler( handlerId )
                    }
                })
        return channel
    }

    fun sendFileMessage( isOpen: Boolean, url :String, customType :String,
                         message: String, userData: String, filePath: String, mimeType: String,
                         metionUsers :List<String>, result: MethodChannel.Result ) {

        val f = { group: BaseChannel?, e: SendBirdException? ->
            val file = File(filePath)

            val fileMessageParams = FileMessageParams()
            fileMessageParams.setFile(file)
            fileMessageParams.setFileName(file.name)
            fileMessageParams.setMimeType(mimeType)
            fileMessageParams.setCustomType(customType)


            if( metionUsers.count() > 0 ){
                fileMessageParams.setMentionType(  BaseMessageParams.MentionType.USERS )
                fileMessageParams.setMentionedUserIds( metionUsers )
            }

            val channel = createStreamChannel( file.path ) { event ->
                group?.sendFileMessage(fileMessageParams, object : BaseChannel.SendFileMessageWithProgressHandler {
                    override fun onSent(p0: FileMessage?, p1: SendBirdException?) {
                        if (p1 != null) {
                            result.error("sendfile", p1.toString(), null)
                        } else if (p0 != null) {
                            val json = HashMap<String,Any>()
                            extractMessage(p0, json)
                            val ret = HashMap<String,Any>()
                            ret[ "event"] = "onsent"
                            ret[ "msg"] =  json
                            event.success( ret )
                        }
                        // channel.cancel()
                    }

                    // bytesSent, totalBytesSent, totalBytesToSend
                    override fun onProgress(p0: Int, p1: Int, p2: Int) {
                        //_uploadPhotoProgress.value = arrayOf(p0, p1, p2)
                        var json = HashMap<String,Any>();
                        json["event"]= "progress"
                        json["total_sent"]= p1
                        json[ "total_bytes"]= p2
                        event.success( json )
                    }
                })
            }

            var jsonChannel = HashMap<String,Any>()
            jsonChannel["channel"] = filePath
            result.success( jsonChannel )
        }


        _runChannel( isOpen, url, f )

    }

    fun markAsRead( url: String, result: MethodChannel.Result  ){
        GroupChannel.getChannel(url) { group, e ->
            group?.markAsRead()
            if(e == null )
                result.success(true)
        }
    }

    fun createChannelWithUserIds( uids : List<String>, isDistinct: Boolean, result: MethodChannel.Result ){
        GroupChannel.createChannelWithUserIds(  uids, isDistinct ) { group, e ->
            if( group != null ){
                val json = HashMap<String,Any>()
                extractChannel( group, json )
                result.success( json )
            }
            if( e != null ){
                result.error("sendbird",e.toString(), null)
            }
        }
    }

}