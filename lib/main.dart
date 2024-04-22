import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart'; // Добавленный импорт
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import 'Pages/Messages/ChatScreen.dart';
import 'Models/User.dart';
import 'Pages/AuthRegUser/Auth.dart';
import 'Pages/Navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'Service/MyFirebaseMessagingService.dart';

import 'Provider/ThemeProvider.dart'; // Импортируйте ThemeProvider

String login = "";
String password = "";

var loginUsers = '';
var lastNames = '';
late User user;

void data_recording() {
  print(loginUsers + ' ' + lastNames);
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> backgroundHandler(RemoteMessage message) async {
  if (message.data.containsKey('openChat')) {
    // Здесь можно выполнить дополнительные действия, если это необходимо
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  bool isDarkMode = prefs.getBool('darkMode') ?? false; // Загрузка сохраненной темы
  await Firebase.initializeApp();
  String channelId = "1622228238850543549";
  String channelName = "Новое сообщение";
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  MyFirebaseMessagingService _firebaseMessagingService = MyFirebaseMessagingService();
  await _firebaseMessagingService.initializeNotificationChannel();

  AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
    channelId,
    channelName,
    importance: Importance.max,
    description: 'Описание канала',
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);
  // Инициализируйте ThemeProvider
  ThemeData initialTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
  ThemeProvider themeProvider = ThemeProvider(initialTheme);

  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (context) => ThemeProvider(initialTheme),
      child: OverlaySupport.global(
        child: MyApp(isLoggedIn: isLoggedIn),
      ),
    ),
  );
  AuthenticatedApp().setupInteractions();
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final PageStorageBucket bucket = PageStorageBucket();

  MyApp({required this.isLoggedIn});


  @override
  Widget build(BuildContext context) {
    // Получите текущую тему из ThemeProvider
    ThemeData currentTheme = Provider.of<ThemeProvider>(context).getTheme();

    return MaterialApp(
      navigatorKey: navigatorKey, // Добавьте эту строку
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).getTheme(),
      home: isLoggedIn ? AuthenticatedApp() : const Authorization(),
    );

  }
}

class AuthenticatedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ваш код для загрузки данных пользователя и отображения соответствующего экрана
    return FutureBuilder<User>(
      future: getUserInfoFromSharedPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            user = snapshot.data!;
            return NavigationScreen(user: user);
          } else {
            return const CircularProgressIndicator();
          }
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void setupInteractions() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        navigateToChatScreen(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigateToChatScreen(message);
    });
  }

  void navigateToChatScreen(RemoteMessage message) {
    // Извлечение необходимых данных для навигации
    final data = message.data;
    final recipientId = data['senderId'];
    final senderId = data['recipientId'];
    final nameUser = data['nameUser'];

    // Выполнение навигации
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => ChatScreen(
        recipientId: int.parse(recipientId),
        senderId: int.parse(senderId),
        nameUser: nameUser,
      )));
    }
  }
}

