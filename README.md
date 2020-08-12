# flutter_sendbird

A new flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# flutter_sendbird

Sendbird wrapped in flutter


## Getting Started

```
  flutter_sendbird
    git:
      url: https://github.com/sensestar/flutter_sendbird

```

## 

import
```
import 'package:flutter_sendbird/flutter_sendbird.dart'
```

init/ connect
```
    FlutterSendbird().init('myappId');
    FlutterSendbird().connect(userId, sendbirdToken );
    // start listen events
    FlutterSendbird().listenChannelMessages();
```

listen message event
```
    FlutterSendbird().eventChannelMessage.stream.listen((msg) {
        print('${msg.senderNickname}: ${msg.message}');
    });
```

listen other event
```
    FlutterSendbird().eventChannel.stream.listen((json) {
      switch (json['event']) {
        case 'readReceiptUpdate':
            print('readReceiptUpdate');
        break;
      }
```
