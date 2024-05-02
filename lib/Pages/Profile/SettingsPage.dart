import 'package:delwiz/Pages/Profile/AboutPage.dart';
import 'package:delwiz/Pages/Profile/InfoPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api/ApiRequest.dart';
import '../AuthRegUser/Auth.dart';
import '../../Provider/ThemeProvider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  void logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Authorization()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Измените здесь, используя listen: true
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrangeAccent,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              // Измените логику отображения иконок в зависимости от темы
              themeProvider.getTheme().brightness == Brightness.dark ? Icons.dark_mode : Icons.wb_sunny,
              size: 30,
            ),
            onPressed: () {
              if (themeProvider.getTheme().brightness == Brightness.dark) {
                themeProvider.setLightTheme();
              } else {
                themeProvider.setDarkTheme();
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.person, color: Colors.deepOrangeAccent),
            title: Text('Аккаунт'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InfoPage()),
              );
              // Действие при нажатии: переход на страницу аккаунта
            },
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.deepOrangeAccent),
            title: Text('Приватность'),
            onTap: () {

              // Действие при нажатии: переход на страницу настроек приватности
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: Colors.deepOrangeAccent),
            title: Text('О приложении'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
              // Действие при нажатии: переход на страницу о приложении
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Выход'),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
