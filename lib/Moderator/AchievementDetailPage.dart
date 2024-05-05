import 'dart:io';

import 'package:delwiz/Api/ApiRequest.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AchievementDetailPage extends StatefulWidget {
  final String name;
  final String description;
  final int idProgress;
  final Widget photo;

  const AchievementDetailPage({
    required this.name,
    required this.description,
    required this.idProgress,
    required this.photo,

  });

  @override
  State<AchievementDetailPage> createState() => _AchievementDetailPageState();
}

class _AchievementDetailPageState extends State<AchievementDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Widget _croppedPhoto = widget.photo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подробная информация', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _selectImage,
              child: _croppedPhoto,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _editData,
              child: Text('Редактировать данные'),
            ),
          ],
        ),
      ),)
    );
  }

  Future<void> _selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final croppedImage = await _cropImage(pickedImage.path);

      if (croppedImage != null) {
        setState(() {
          _croppedPhoto = Image.file(croppedImage, fit: BoxFit.cover);
        });

        await uploadUserPhoto(widget.idProgress, croppedImage);
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
        toolbarColor: Colors.deepOrange,
        // Цвет панели инструментов
        toolbarWidgetColor: Colors.white,
        // Цвет иконок на панели инструментов
        statusBarColor: Colors.deepOrange,
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

  Future<void> uploadUserPhoto(int userId, File imageFile) async {
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Progresses/upload-photo/$userId',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('Фото успешно загружено. ID фото: ${response.data['photoID']}');
        // Обновите список фотографий с сервера или выполните другие действия
      } else {
        print('Ошибка при загрузке фото: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке фото: $e');
    }
  }

  Future<void> _editData() async {
    final String newName = _nameController.text;
    final String newDescription = _descriptionController.text;

    // Check if name and description are not empty
    if (newName.isEmpty || newDescription.isEmpty) {
      // Show a snackbar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    // Create a JSON payload
    final Map<String, dynamic> data = {
      'idProgress': widget.idProgress,
      'nameProgress': newName,
      'descriptionProgress': newDescription,
    };

    try {
      // Send a PUT request to update the data
      final response = await dio.put(
        '$api/Progresses/${widget.idProgress}',
        data: data,
      );

      // Check if the request was successful (status code 204)
      if (response.statusCode == 204) {
        // Show a snackbar with a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Данные успешно обновлены')),
        );
        Navigator.pop(context, true);

      } else {
        // Show a snackbar with an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Show a snackbar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке запроса: $e')),
      );
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
