import 'dart:convert';
import 'dart:typed_data';

import 'package:delwiz/Pages/Messages/UserChatDto.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../Api/ApiRequest.dart';
import '../../Models/Correspondence.dart';
import '../../Models/MessageUser.dart';
import 'ChatScreen.dart';

class MessengerScreen extends StatefulWidget {
  @override
  _MessengerScreenState createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  List<UserChatDto> userChats = [];
  Map<int, Image> photoImages = {};

  @override
  void initState() {
    super.initState();
    _fetchUserChats(IDUser);
  }

  Future<void> _fetchUserChats(String userId) async {
    try {
      final response = await Dio().get(
        '$api/Correspondences/GetUserChats/$userId',
        options: Options(
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> userChatsData = response.data;

        final List<UserChatDto> newUserChats = userChatsData
            .map((chatData) => UserChatDto.fromJson(chatData))
            .toList();

        setState(() {
          userChats = newUserChats;
        });
        // Загружаем фото для каждого пользователя
        for (var userChat in userChats) {
          if (!photoImages.containsKey(userChat.senderId)) {
            await _fetchUserPhotos(userChat.senderId);
          }
        }
      } else {
        print('Ошибка загрузки чатов: ${response.statusCode}');
      }
    } catch (error) {
      print('Ошибка сети: $error');
    }
  }

  Future<void> _fetchUserPhotos(int idUser) async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response =
      await _dio.get('$api/Users/user-photos/$idUser');
      if (response.statusCode == 200) {
        final photoData = response.data;
        setState(() {
          final image = Image.memory(Uint8List.fromList(photoData!));
          photoImages[idUser] = image;
          print('Photo loaded for userId: $idUser');
        });
      } else {
        print(
            'Failed to fetch user photos with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          'Мессенджер',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemCount: userChats.length,
          itemBuilder: (context, index) {
            final userChat = userChats[index];
            final Image? userAvatar = photoImages[userChat.senderId];

            return ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey, // Цвет фона для края
                backgroundImage: userAvatar != null
                    ? userAvatar.image // Используйте изображение как фон
                    : null, // Не устанавливайте фон, если аватар пустой
                child: userAvatar == null
                    ? Icon(Icons.add_a_photo) // Иконка, если аватар пустой
                    : null, // Не показывайте дополнительный дочерний виджет, если есть изображение
              ),

              title: Text(userChat.userName),
              subtitle: Text(userChat.lastMessage),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      senderId: userChat.userId,
                      recipientId: userChat.senderId,
                      nameUser: userChat.userName,
                      isSupport: false,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _fetchUserChats(IDUser);
  }
}
