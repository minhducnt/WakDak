import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/ui/screen/home/home_screen.dart';
import 'package:wakDak/ui/screen/ticket/chat_screen.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

backgroundMessage(NotificationResponse notificationResponse) {
  print('notification(${notificationResponse.id}) action tapped: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print('notification action tapped with input: ${notificationResponse.input}');
  }
}

class NotificationUtility {
  late BuildContext context;
  NotificationUtility({required this.context});
  void initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {},
    );

    //Android 13 or higher
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationPayload(notificationResponse.payload!);

            break;
          case NotificationResponseType.selectedNotificationAction:

            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: backgroundMessage,
    );
    _requestPermissionsForIos();
  }

  static Future<void> onBackgroundMessage(RemoteMessage remoteMessage) async {
    //perform any background task if needed here
    if (streamController != null && !streamController!.isClosed) {
      streamController!.sink.add("1");
    }
  }

  selectNotificationPayload(String? payload) async {
    if (payload != null) {
      List<String> pay = payload.split(",");
      if (pay[0] == "products") {
      } else if (pay[0] == "categories") {
        Navigator.of(context)
            .pushNamed(Routes.cuisineDetail, arguments: {'categoryId': pay[1], 'name': UiUtils.getTranslatedLabel(context, deliciousCuisineLabel)});
      } else if (pay[0] == "wallet") {
        Navigator.of(context).pushNamed(Routes.wallet);
      } else if (pay[0] == "place_order" || pay[0] == "order") {
        Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
          'id': pay[1],
          'riderId': "",
          'riderName': "",
          'riderRating': "",
          'riderImage': "",
          'riderMobile': "",
          'riderNoOfRating': "",
          'isSelfPickup': "",
          'from': 'orderDetail'
        });
      } else if (pay[0] == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => ChatScreen(
                    id: pay[1],
                    status: "",
                  )),
        );
      } else if (pay[0] == "ticket_status") {
        Navigator.of(context).pushNamed(Routes.ticket);
      } else {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    }
  }

  Future<void> _requestPermissionsForIos() async {
    if (Platform.isIOS) {
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions();
    }
  }

  Future<void> onDidReceiveLocalNotification(int? id, String? title, String? body, String? payload) async {}

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    //print("initialMessage"+initialMessage.toString());
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    // handle background notification
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    // handle background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    //handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("data:onMessage");
      print("data notification*********************************${message.data}");
      var data = message.data;
      print("data notification*********************************$data");
      var title = data['title'].toString();
      var body = data['body'].toString();
      var type = data['type'].toString();
      var image = data['image'].toString();
      var id = data['type_id'] ?? '';

      if (image != 'null' && image != '') {
        generateImageNotification(title, body, image, type, id);
      } else {
        generateSimpleNotification(title, body, type, id);
      }
    });
  }

// notification type is move to screen
  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['type'] == 'category') {
      Navigator.of(context).pushNamed(Routes.cuisine, arguments: false);
    }
    if (message.data['type'] == "products") {
      //getProduct(id, 0, 0, true);
    } else if (message.data['type'] == "categories") {
      Navigator.of(context).pushNamed(Routes.cuisineDetail,
          arguments: {'categoryId': message.data['type_id'], 'name': UiUtils.getTranslatedLabel(context, deliciousCuisineLabel)});
    } else if (message.data['type'] == "wallet") {
      Navigator.of(context).pushNamed(Routes.wallet);
    } else if (message.data['type'] == 'place_order' || message.data['type'] == 'order') {
      if (streamController != null && !streamController!.isClosed) {
        streamController!.sink.add("1");
      }
      Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
        'id': message.data['type_id'],
        'riderId': "",
        'riderName': "",
        'riderRating': "",
        'riderImage': "",
        'riderMobile': "",
        'riderNoOfRating': "",
        'isSelfPickup': "",
        'from': 'orderDetail'
      });
    } else if (message.data['type'] == "ticket_message") {
      Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => ChatScreen(
                  id: message.data['type_id'],
                  status: "",
                )),
      );
    } else if (message.data['type'] == "ticket_status") {
      Navigator.of(context).pushNamed(Routes.ticket);
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  DarwinNotificationDetails darwinNotificationDetails = const DarwinNotificationDetails(
    categoryIdentifier: "",
  );

  Future<void> generateImageNotification(String title, String msg, String image, String type, String? id) async {
    var largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    var bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true, contentTitle: title, htmlFormatContentTitle: true, summaryText: msg, htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'com.wakdak.wakdakCustomer', //channel id
      'WakDak', //channel name
      channelDescription: 'WakDak', //channel description
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation, icon: "@mipmap/launcher_icon",
    );
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: darwinNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, title, msg, platformChannelSpecifics, payload: "$type,${id!}");
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  // notification on foreground
  Future<void> generateSimpleNotification(String title, String msg, String type, String? id) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'com.wakdak.wakdakCustomer', //channel id
        'WakDak', //channel name
        channelDescription: 'WakDak', //channel description
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: "@mipmap/launcher_icon");
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: darwinNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, title, msg, platformChannelSpecifics, payload: "$type,${id!}");
  }
}
