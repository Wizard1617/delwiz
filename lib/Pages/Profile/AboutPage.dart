import 'package:delwiz/Pages/Profile/SettingsPage.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('О приложении'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              size: 50,
              color: Colors.deepOrangeAccent,
            ),
            SizedBox(height: 20),
            Text(
              'Информация о приложении',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Данное приложение является дипломной работой двух студентов:\n Юрий - delur   Александр - wizard\n В данном приложении вы можете обмениваться файлами\n и информацией как путем новостей, так и переписки.\n Это всего лишь вторая версия приложения и каждое будущее обновление будет вносить дополнительный функционал, а также улучшать ваш экспириенс\n пользования данной соц. сетью... ',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
