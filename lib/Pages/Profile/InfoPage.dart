import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Замените 'your_package' на ваш пакет
import '../../Models/User.dart';

class InfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<InfoPage> {
  late User user; // Объявите экземпляр User здесь

  @override
  void initState() {
    super.initState();
    _getUserInfoFromPrefs();
  }

  Future<void> _getUserInfoFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String loginUser = prefs.getString('loginUser') ?? '';
    final String firstName = prefs.getString('firstName') ?? '';
    final String lastName = prefs.getString('lastName') ?? '';
    final int userId = prefs.getInt('userId') ?? 0;

    user = User(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      loginUser: loginUser,
      // Добавьте остальные поля пользователя
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактирование профиля'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Закругленные края
                border: Border.all(color: Colors.deepOrangeAccent), // Оранжевая окантовка
              ),
              child: TextField(
                controller: TextEditingController(text: 'Login: ${user.loginUser}'),
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none, // Убираем стандартную окантовку текстового поля
                  contentPadding: EdgeInsets.all(10), // Отступы внутри текстового поля
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Закругленные края
                border: Border.all(color: Colors.deepOrangeAccent), // Оранжевая окантовка
              ),
              child: TextField(
                controller: TextEditingController(text: 'Last Name: ${user.lastName}'),
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none, // Убираем стандартную окантовку текстового поля
                  contentPadding: EdgeInsets.all(10), // Отступы внутри текстового поля
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Закругленные края
                border: Border.all(color: Colors.deepOrangeAccent), // Оранжевая окантовка
              ),
              child: TextField(
                controller: TextEditingController(text: 'First Name: ${user.firstName}'),
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none, // Убираем стандартную окантовку текстового поля
                  contentPadding: EdgeInsets.all(10), // Отступы внутри текстового поля
                ),
              ),
            ),
            // Добавьте здесь дополнительные поля для редактирования информации о пользователе
          ],
        ),
      ),
    );
  }
}