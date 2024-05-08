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

  @override
  void initState() {
    super.initState();
    _fetchUserChats(IDUser);
  }

  Future<void> _fetchUserChats(String userId) async {
    try {
      final response = await Dio().get('$api/Correspondences/GetUserChats/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> userChatsData = response.data;
        final List<UserChatDto> newUserChats = [];

        for (final chatData in userChatsData) {
          final userChat = UserChatDto.fromJson(chatData);
          newUserChats.add(userChat);
        }

        setState(() {
          userChats = newUserChats;
        });
      } else {
        print('Failed to fetch user chats with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user chats: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepOrangeAccent,
        title: Text('Мессенджер',style: TextStyle(color: Colors.white),),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Ваш метод обновления данных
        child: ListView.builder(
          itemCount: userChats.length,
          itemBuilder: (context, index) {
            final userChat = userChats[index];

            return ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: userChat.userPhoto!.isNotEmpty
                    ? MemoryImage(Uint8List.fromList(userChat.userPhoto!))
                    : null,
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
