import 'dart:io';
import 'dart:typed_data';

import 'package:delwiz/Api/ApiRequest.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AddAchievementPage extends StatefulWidget {
  @override
  State<AddAchievementPage> createState() => _AddAchievementPageState();
}

class _AddAchievementPageState extends State<AddAchievementPage> {
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Добавить достижение',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: SingleChildScrollView(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.deepOrangeAccent),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Icon(Icons.add_a_photo, color: Colors.deepOrangeAccent),
                ),
              ),
              SizedBox(height: 20,),
              // Название
              Container(
                margin: EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrangeAccent),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(8.0),
                    hintText: 'Название',
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Описание
              Container(
                margin: EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrangeAccent),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(8.0),
                    hintText: 'Описание',
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Кнопка "Создать достижение"
              ElevatedButton(
                onPressed: _createAchievement,
                child: Text('Создать достижение'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.deepOrangeAccent),
                ),
              ),
            ],
          ),
        ),
      ),)
    );
  }

  Future<void> _selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
    await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final croppedImage = await _cropImage(pickedImage.path);

      if (croppedImage != null) {
        setState(() {
          _selectedImage = croppedImage;
        });
      }
    }
  }

  Future<File?> _cropImage(String imagePath) async {
    final imageCropper = ImageCropper();

    final croppedImage = await imageCropper.cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(
        ratioX: 1, // 1:1 aspect ratio
        ratioY: 1,
      ),
      compressQuality: 100,
      // Compression quality
      androidUiSettings: const AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.deepOrangeAccent,
        // Цвет панели инструментов
        toolbarWidgetColor: Colors.white,
        // Цвет иконок на панели инструментов
        statusBarColor: Colors.deepOrangeAccent,
        // Цвет статус-бара
        backgroundColor: Colors.white, // Цвет фона обрезки
      ),
      iosUiSettings: const IOSUiSettings(
        minimumAspectRatio: 1.0,
        aspectRatioLockDimensionSwapEnabled: false,
      ),
    );

    return croppedImage;
  }

  Future<void> _createAchievement() async {
    final String name = _nameController.text;
    final String description = _descriptionController.text;

    if (name.isEmpty || description.isEmpty || _selectedImage == null) {
      // Проверка на заполнение всех полей
      // Можно показать пользователю сообщение об ошибке
      return;
    }

    try {
      // Отправка запроса на создание достижения
      final response = await dio.post(
        '$api/Progresses',
        data: {
          'nameProgress': name,
          'descriptionProgress': description,
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        final int idProgress = responseData['idProgress'];

        // После успешного создания достижения отправляем фото
        await uploadAchievementsPhoto(idProgress, _selectedImage!);
      } else {
        // Обработка ошибки
        print('Ошибка при создании достижения: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при создании достижения: $e');
    }
  }

  Future<void> uploadAchievementsPhoto(int idProgress, File imageFile) async {
    // Отправка запроса на загрузку фото
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'achievement_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Progresses/upload-photo/$idProgress',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('Фото успешно загружено для достижения ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Фото успешно загружено для достижения '),
            duration: Duration(seconds: 2), // Установите продолжительность по вашему усмотрению
          ),
        );
        Navigator.pop(context, true); // Передача параметра о успешной загрузке
      } else {
        print('Ошибка при загрузке фото для достижения : ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке фото для достижения : ${response.statusCode}'),
            duration: Duration(seconds: 2), // Установите продолжительность по вашему усмотрению
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке фото для достижения : $e'),
          duration: Duration(seconds: 2), // Установите продолжительность по вашему усмотрению
        ),
      );    }
  }
}
