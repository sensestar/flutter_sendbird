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
            var jso = JsonObject()
            if( group != null ) {
                extractChannel(group, jso)
                result.success( jso.toString() )
            }
        }
        if( isOpen ) {
            OpenChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }
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
                        var jso = JsonObject()
                        extractChannel( openChannel, jso )
                        result.success( jso.toString() )
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

            val jso = JsonObject()
            jso.addProperty("enabled", isDoNotDisturbOn)
            jso.addProperty( "start_hour", startHour )
            jso.addProperty( "start_min", startMin )
            jso.addProperty( "end_hour", endHour )
            jso.addProperty( "end_min", endMin )
            jso.addProperty( "timezone", timezone )

            result.success( jso.toString() )
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
                var jslist = mutableListOf<String>();
                p0?.forEach { user ->

                    var jso = JsonObject()
                    jso.addProperty("nickname", user.nickname)
                    jso.addProperty("profile_url", user.profileUrl)
                    jso.addProperty("is_active", user.isActive)
                    jso.addProperty("is_online", user.connectionStatus == User.ConnectionStatus.ONLINE )
                    jso.addProperty("last_seen_at", user.lastSeenAt)
                    jso.addProperty("user_id", user.userId)
                    jslist.add(jso.toString())
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
                var ret = mutableListOf<String>()
                for( channel in list ){
                    var jso = JsonObject()
                    extractChannel(channel, jso )
                    ret.add(jso.toString())
                }
                result.success( ret )
            }
        }
    }

    private fun extractChannel( baseChannel: BaseChannel, jso: JsonObject ){
        jso.addProperty("cover_url", baseChannel.coverUrl)
        jso.addProperty("name", baseChannel.name)
        jso.addProperty("url", baseChannel.url)
        jso.addProperty("data", baseChannel.data)
        jso.addProperty("is_open_channel", baseChannel.isOpenChannel)

        when( baseChannel )
        {
            is GroupChannel ->{
                var channel = baseChannel as GroupChannel
                jso.addProperty("is_public", channel.isPublic)
                jso.addProperty("custom_type", channel.customType)
                jso.addProperty("unread_message_count", channel.getUnreadMessageCount() )
                var jsmsg = JsonObject()
                if( channel.lastMessage != null ) {
                    extractMessage(channel.lastMessage, jsmsg)
                }
                jso.add("last_message", jsmsg )

                var userlist = JsonArray()
                for( member in channel.members ){
                    var usr = JsonObject()
                    usr.addProperty( "nickname", member.nickname )
                    usr.addProperty( "user_id", member.userId )
                    usr.addProperty( "profile_url", member.profileUrl )
                    userlist.add( usr )
                }
                jso.add( "members", userlist )

                var readlist = JsonObject()
                val reads = channel.getReadStatus( true );
                reads.forEach {iter ->
                    val userid = iter.key
                    val readstate = iter.value
                    readlist.addProperty( userid, readstate.timestamp );
                }
                jso.add("read_status", readlist )
                //for( k)

                //}
            }
            is OpenChannel ->{
                var channel = baseChannel as OpenChannel
                jso.addProperty( "custom_type", channel.customType)

            }
        }

    }

    private fun extractMessage( message: BaseMessage, json: JsonObject ) {
        json.addProperty("created_at", message.createdAt)
        json.addProperty("data", message.data)
        json.addProperty("message_id", message.messageId)

        when (message) {
            is UserMessage -> {
                var umsg = message as UserMessage
                json.addProperty( "type", "USER" )
                json.addProperty("message", umsg.message )
                json.addProperty("sender_id", umsg.sender.userId )
                json.addProperty("sender_profile_url", umsg.sender.profileUrl )
                json.addProperty("sender_nickname", umsg.sender.nickname )
                json.addProperty("custom_type", umsg.customType )
                if (message.mentionType == BaseMessageParams.MentionType.USERS) {
                    val array = JsonArray()
                    message.mentionedUsers.forEach{
                        array.add( it.userId )
                    }
                    json.add( "mentioned_user_ids", array )
                }
            }
            is AdminMessage -> {
                var amsg = message as AdminMessage;
                json.addProperty( "type", "ADMIN")
                json.addProperty( "message", amsg.message )
            }
            is FileMessage -> {
                var fmsg = message as FileMessage;
                json.addProperty( "type", "FILE" )
                json.addProperty( "name", fmsg.name )
                json.addProperty( "request_id", fmsg.requestId )
                json.addProperty( "sender_id", fmsg.sender.userId )
                json.addProperty( "sender_profile_url", fmsg.sender.profileUrl )
                json.addProperty( "sender_nickname", fmsg.sender.nickname )
                json.addProperty( "custom_type", fmsg.customType )
                json.addProperty( "file_type", fmsg.type )
                json.addProperty( "url", fmsg.url )
            }
        }
    }

    fun listenChannelMessage( handlerId: String, result: MethodChannel.Result ){
        var channel = EventChannel( _flutterBinaryMessenger, handlerId)
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
                            var js = JsonObject()
                            if( channel != null && message != null  ) {
                                js.addProperty("event", "messageReceived")
                                js.addProperty("channel_url", channel.url)
                                js.addProperty("is_open_channel", channel.isOpenChannel)
                                extractMessage( message, js )
                                events.success( js.toString() )
                            }
                        }
                        override fun onUserEntered(channel: OpenChannel?, user: User?) {
                            var js = JsonObject()
                            if( channel != null && user != null  ) {
                                js.addProperty("event", "userEntered")
                                js.addProperty("user_id", user.userId)
                                js.addProperty("nickname", user.nickname)
                                js.addProperty("profile_url", user.profileUrl)
                                js.addProperty("channel_url", channel.url )
                                events.success( js.toString() )
                            }
                        }
                        override fun onUserJoined(channel: GroupChannel?, user: User?) {
                            var js = JsonObject()
                            if( channel != null && user != null  ) {
                                js.addProperty("event", "userJoined")
                                js.addProperty("user_id", user.userId)
                                js.addProperty("nickname", user.nickname)
                                js.addProperty("profile_url", user.profileUrl)
                                js.addProperty("channel_url", channel.url )
                                events.success( js.toString() )
                            }
                        }

                        override fun onReadReceiptUpdated(channel: GroupChannel?) {
                            var js = JsonObject()
                            if( channel != null  ) {
                                js.addProperty("event", "readReceiptUpdate")
                                js.addProperty("channel_url", channel.url )
                                var jsChannel = JsonObject()
                                extractChannel( channel, jsChannel )
                                js.add( "channel", jsChannel )
                                events.success( js.toString() )
                            }
                        }

                        override fun onTypingStatusUpdated(channel: GroupChannel?) {
                            var js = JsonObject()
                            if( channel != null  ) {
                                js.addProperty("event", "typingStatusUpdated")
                                js.addProperty( "is_typing", channel.isTyping )
                                js.addProperty(  "channel_url", channel.url );
                                events.success( js.toString() )
                            }
                        }

                        override fun onMessageUpdated(channel: BaseChannel?, message: BaseMessage?) {
                            var js = JsonObject()
                            if( channel != null && message != null  ) {
                                js.addProperty("event", "messageUpdated")
                                js.addProperty("channel_url", channel.url)
                                js.addProperty("is_open_channel", channel.isOpenChannel)
                                extractMessage( message, js )
                                events.success( js.toString() )
                            }
                        }

                        override fun onMessageDeleted(channel: BaseChannel?, msgId: Long) {
                            var js = JsonObject()
                            if( channel != null ) {
                                js.addProperty("event", "messageDeleted")
                                js.addProperty( "channel_url", channel.url )
                                js.addProperty( "message_id", msgId )
                                events.success( js.toString() )
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

    private  fun _handleGetChannelMessage(messages: List<BaseMessage>, result: MethodChannel.Result  ){
        var retList = mutableListOf<String>()
        for( msg in messages ){
            var js = JsonObject()
            extractMessage( msg, js )
            retList.add( js.toString() );
        }
        result.success( retList )
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


        if( isOpenChannel ){
            OpenChannel.getChannel( groupUrl ) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(groupUrl) { group, e ->
                f( group, e )
            }
        }

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


        if( isOpenChannel ){
            OpenChannel.getChannel( groupUrl ) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(groupUrl) { group, e ->
                f( group, e )
            }
        }

    }

    var queryHandler = mutableMapOf<String, PreviousMessageListQuery>()

    fun getLastMessages( isOpen: Boolean, qid: String,  url : String , cnt : Int, result: MethodChannel.Result  ){
        val f = { group :BaseChannel?, e: SendBirdException?  ->
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
        }

        if( isOpen ) {
            OpenChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }

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
                        var js = JsonObject()
                        extractMessage( sentMsg, js)
                        result.success( js.toString() )
                    }
                }
            }
        }

        if( isOpen ) {
            OpenChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }

    }

    fun updateUserMessage( isOpen: Boolean, url :String, customType :String,
                         msgId: Long, message: String, userData: String,
                         result: MethodChannel.Result ){
        val f = { group: BaseChannel?, e: SendBirdException? ->
            var msg = UserMessageParams()
                    .setMessage(message)
                    .setCustomType(customType)
                    .setData(userData)

            group?.updateUserMessage( msgId, msg ) { sentMsg, e ->
                if( e == null ){
                    if( sentMsg != null ) {
                        var js = JsonObject()
                        extractMessage( sentMsg, js)
                        result.success( js.toString() )
                    }
                }
            }
        }

        if( isOpen ) {
            OpenChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }

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
                            var json = JsonObject()
                            extractMessage(p0, json)
                            var ret = JsonObject()
                            ret.addProperty( "event", "onsent" )
                            ret.add( "msg", json )
                            event.success( ret.toString() )
                        }
                        // channel.cancel()
                    }

                    // bytesSent, totalBytesSent, totalBytesToSend
                    override fun onProgress(p0: Int, p1: Int, p2: Int) {
                        //_uploadPhotoProgress.value = arrayOf(p0, p1, p2)
                        var json = JsonObject();
                        json.addProperty("event", "progress" )
                        json.addProperty("total_sent", p1 )
                        json.addProperty( "total_bytes", p2 )
                        event.success( json.toString() )
                    }
                })
            }

            var jsonChannel = JsonObject()
            jsonChannel.addProperty("channel", filePath )
            result.success( jsonChannel.toString() )
        }



        if( isOpen ) {
            OpenChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }else {
            GroupChannel.getChannel(url) { group, e ->
                f( group, e )
            }
        }
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
                var json = JsonObject()
                extractChannel( group, json )
                result.success( json.toString() )
            }
            if( e != null ){
                result.error("sendbird",e.toString(), null)
            }
        }
    }

}