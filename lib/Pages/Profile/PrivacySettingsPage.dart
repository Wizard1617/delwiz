import 'package:delwiz/Api/ApiRequest.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsPage extends StatefulWidget {
  @override
  _PrivacySettingsPageState createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool isPrivate = false;
  Dio dio = Dio();


  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  void _loadPrivacySetting() async {
    final prefs = await SharedPreferences.getInstance();
    final isPrivateStored = prefs.getBool('isPrivate') ?? false;
    setState(() {
      isPrivate = isPrivateStored;
    });
  }

  Future<void> _savePrivacySetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPrivate', value);
  }

  void updatePrivacy( bool privacySetting) async {
    try {
      final response = await dio.put(
        '$api/Users/$IDUser/privatnost',
        data: privacySetting,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Приватность аккаунта обновлена.'),
          ),
        );
      } else {
        // Обработка других статусов http
        throw Exception('Failed to update privacy setting');
      }
    } catch (e) {
      // Обработать ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении приватности: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Тот же код, что был ранее
    return Scaffold(
      appBar: AppBar(
        title: Text('Приватность'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Сделать аккаунт приватным',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            Switch(
              value: isPrivate,
              onChanged: (newValue) async {
                setState(() {
                  isPrivate = newValue;
                });
                await _savePrivacySetting(isPrivate);
                updatePrivacy(isPrivate); // ID пользователя нужно заменить на актуальное значение.
              },
              activeColor: Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }
}