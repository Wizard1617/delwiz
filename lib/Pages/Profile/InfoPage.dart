import 'package:delwiz/Api/ApiRequest.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/User.dart';

class InfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<InfoPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  late User user; // Объявляем экземпляр User здесь

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

    setState(() {
      user = User(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        loginUser: loginUser,
      );
      _loginController.text = user.loginUser;
      _lastNameController.text = user.lastName;
      _firstNameController.text = user.firstName;
    });
  }

  Future<void> _updateUserInfo() async {
    final dio = Dio();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final response = await dio.put(
        '$api/Users/${user.id}/personalinfo',
        data: {
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "loginUser": _loginController.text,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'accept': '*/*',
          },
        ),
      );

      if (response.statusCode == 204) {
        // Обновляем данные в SharedPreferences
        prefs.setString('firstName', _firstNameController.text);
        prefs.setString('lastName', _lastNameController.text);
        prefs.setString('loginUser', _loginController.text);

        // Показываем Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Данные обновлены'),
          ),
        );

        // Возвращаемся на предыдущий экран
        Navigator.pop(context);
      } else {
        // Обработка ошибки
        print('Ошибка при обновлении данных: ${response.statusCode}');
      }
    } catch (error) {
      // Обработка ошибки
      print('Ошибка при обновлении данных: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // Можно показать индикатор загрузки
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Редактирование профиля',
          style: TextStyle(color: Colors.white),
        ),
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
              child: TextFormField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: 'Логин', // Подпись над полем
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  floatingLabelBehavior: FloatingLabelBehavior.auto, // Изменение положения подписи
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Закругленные края
                border: Border.all(color: Colors.deepOrangeAccent), // Оранжевая окантовка
              ),
              child: TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Фамилия', // Подпись над полем
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  floatingLabelBehavior: FloatingLabelBehavior.auto, // Изменение положения подписи
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Закругленные края
                border: Border.all(color: Colors.deepOrangeAccent), // Оранжевая окантовка
              ),
              child: TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Имя', // Подпись над полем
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  floatingLabelBehavior: FloatingLabelBehavior.auto, // Изменение положения подписи
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.deepOrange),
                padding: MaterialStateProperty.all<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
              onPressed: () {
                _updateUserInfo();
              },
              child: Text(
                'Изменить данные',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
