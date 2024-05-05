import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:delwiz/Pages/Profile/AchievementsTab.dart';
import 'package:delwiz/Pages/Profile/SettingsPage.dart';
import 'package:delwiz/Pages/Profile/VideoGridItem.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api/ApiRequest.dart';
import '../../Models/NewsDto.dart';
import '../../Models/User.dart';
import '../../main.dart';

List<Image> photoImages = [];

class ProfileSupportPage extends StatefulWidget {
  final User? user;

  const ProfileSupportPage({Key? key, this.user}) : super(key: key);

  @override
  State<ProfileSupportPage> createState() => _ProfileSupportPageState();
}

class _ProfileSupportPageState extends State<ProfileSupportPage>
    with AutomaticKeepAliveClientMixin {
  // Другие части вашего класса остаются без изменений

  @override
  bool get wantKeepAlive => true;

  List<Uint8List> photoAllImages = [];
  List<NewsDto> newsData = []; // Добавляем здесь
  bool isDataLoaded = false;
  bool isUserLoaded = false; // Флаг для отслеживания загрузки данных пользователя

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getUserInfoFromPrefs();
    if (!isDataLoaded) {
      UserInfo();
    }
  }

  void UserInfo() {
    _fetchUserPhotos();
/*
    _fetchUserNews();
*/
    setState(() {
      isDataLoaded = true;
    });
  }

  Future<void> _getUserInfoFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int userId = prefs.getInt('userId') ?? 0;
     IDUser = prefs.getInt('userId').toString() ?? '';
    final String firstName = prefs.getString('firstName') ?? '';
    final String lastName = prefs.getString('lastName') ?? '';
    final String loginUser = prefs.getString('loginUser') ?? '';

    user = User(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      loginUser: loginUser,
      // Добавьте остальные поля пользователя
    );

    setState(() {
      isUserLoaded = true; // Устанавливаем флаг в true после успешной загрузки данных пользователя
    });  }

/*
  void _showNewsDetails(Map<String, dynamic> newsData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsListScreen(newsList: [newsData]),
      ),
    );
  }
*/

  Future<void> uploadUserPhoto(int userId, File imageFile) async {
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Users/upload-photo/$userId',
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

  Future<void> _selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final croppedImage = await _cropImage(pickedImage.path);

      if (croppedImage != null) {
        setState(() {
          final image = Image.file(croppedImage, fit: BoxFit.cover);
          photoImages.add(image);
        });

        // Теперь загрузите обрезанное фото на сервер и обновите логику загрузки
        await uploadUserPhoto(int.parse(IDUser), croppedImage);
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

  Future<void> _fetchUserPhotos() async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response =
          await _dio.get('$api/Users/user-photos/$IDUser');
      if (response.statusCode == 200) {
        final photoData = response.data;
        setState(() {
          final image = Image.memory(Uint8List.fromList(photoData!));
          photoImages.add(image);
        });
      } else {
        // Обработка ошибки
        print(
            'Failed to fetch user photos with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> uploadUserPhotos(int userId, File imageFile) async {
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Users/upload-photos/$userId',
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Adjust this part based on the actual response structure
        if (responseData.containsKey('photoID')) {
          print('Фото успешно загружено. ID фото: ${responseData['photoID']}');
          // Обновите список фотографий с сервера или выполните другие действия
        } else {
          print('Ошибка при загрузке фото: Неверный формат ответа');
        }
      } else {
        print('Ошибка при загрузке фото: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке фото: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Профиль",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('Настройки'),
                value: 'settings',
              ),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Settings()),
                );
              }
            },
            shape: RoundedRectangleBorder(
              // Добавляет закругленные углы
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Вызовите здесь функции для обновления данных
          await _fetchUserPhotos();
        },
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Обеспечивает возможность прокрутки
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _selectImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[700],
                      ),
                      child: ClipOval(
                        child: photoImages.isNotEmpty
                            ? photoImages.last
                            : const Icon(Icons.add_a_photo),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isUserLoaded) ...[
                    // Отображаем индикатор загрузки, если данные пользователя еще не загружены
                    Center(
                      child: CircularProgressIndicator(),
                    )
                  ] else ...[
                    // Отображаем данные пользователя, если они загружены
                    Text(
                      user.firstName + ' '+user.lastName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user.loginUser}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            )),
      ),
    );
  }
}
