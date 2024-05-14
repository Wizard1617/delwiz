import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:delwiz/Api/ApiRequest.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';

import '../../Models/NewsPuctireService.dart';
import '../../Models/NewsService.dart';
import '../../Models/PictureService.dart';

class AddNews extends StatefulWidget {
  const AddNews({Key? key}) : super(key: key);

  @override
  _AddNewsState createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews> {
  File? _selectedImage;
  List<XFile> _selectedMedia = []; // Изменено для поддержки множественного выбора
  final ImagePicker _picker = ImagePicker();
  Map<String, VideoPlayerController> _videoControllers = {}; // Кэш контроллеров

  TextEditingController _descriptionController = TextEditingController();
  int _currentPage = 0;

  Future<void> _selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

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
      aspectRatio: CropAspectRatio(
        ratioX: 1, // 1:1 aspect ratio
        ratioY: 1,
      ),
      compressQuality: 100, // Compression quality
      androidUiSettings: AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.deepOrange, // Toolbar color
        toolbarWidgetColor: Colors.white, // Toolbar icon color
        statusBarColor: Colors.deepOrange, // Status bar color
        backgroundColor: Colors.white, // Crop background color
      ),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
        aspectRatioLockDimensionSwapEnabled: false,
      ),
    );

    return croppedImage;
  }


  Future<void> _selectMedia(String mediaType) async {
    FileType fileType = FileType.media;
    if (mediaType == 'image') {
      fileType = FileType.image; // Изменение типа файла на изображения
    } else if (mediaType == 'video') {
      fileType = FileType.video; // Изменение типа файла на видео
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fileType, // использование выбранного типа файла
    );

    if (result != null) {
      for (var file in result.files) {
        if (mediaType == 'image') {
          // Обрабатываем каждое изображение: обрезка перед добавлением
          final croppedFile = await _cropImage(file.path!);
          if (croppedFile != null) {
            setState(() {
              _selectedMedia.add(XFile(croppedFile.path));
            });
          }
        } else if (mediaType == 'video') {
          // Для видео файлов просто добавляем их без обработки
          setState(() {
            _selectedMedia.add(XFile(file.path!));
          });
        }
      }
    }
  }
  Future<List<int>> _uploadMedia() async {
    List<int> pictureIds = [];
    Dio dio = Dio();
    var apiUrl = 'http://192.168.1.69:5108/api/Pictures';

    for (var media in _selectedMedia) {
      String? mimeType = lookupMimeType(media.path);
      MediaType mediaType = MediaType.parse(mimeType ?? 'application/octet-stream');
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(media.path, contentType: mediaType),
      });

      var response = await dio.post(apiUrl, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Предполагаем, что сервер возвращает JSON с ID изображения в поле 'idPicture'
        var data = response.data;
        pictureIds.add(data['idPicture']); // Убедитесь, что 'idPicture' - это правильный ключ
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }

    }
    return pictureIds;
  }



  Future<void> _addNews() async {
    try {
      Dio dio = Dio();
      var apiUrl = '$api/News';

      // Создаем FormData для отправки данных и файлов
      var newsData = FormData.fromMap({
        'Description_News': _descriptionController.text,
        'IdUser': IDUser.toString(), // ID пользователя
       /* 'Likes': '0', // Начальное количество лайков
        'DisLike': '0', // Начальное количество дислайков
        'LikedByCurrentUser': 'false',
        'DislikedByCurrentUser': 'false',
        'SendingTime': DateTime.now().toIso8601String(),*/
      });

      // Добавляем файлы к FormData
      for (var media in _selectedMedia) {
        String fileName = media.path.split('/').last;
        String mimeType = lookupMimeType(media.path) ?? 'application/octet-stream';
        newsData.files.add(MapEntry(
          'Files', // ключ 'Files' используется для связи с API
          await MultipartFile.fromFile(media.path, filename: fileName, contentType: MediaType.parse(mimeType)),
        ));
      }

      // Отправка данных на сервер
      var response = await dio.post(apiUrl, data: newsData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Новость успешно добавлена: ${response.data}');

        // Returning to the previous screen
        Navigator.pop(context);

        // Showing a success notification
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Публикация выложена"),
              duration: Duration(seconds: 2),
            )
        );
      }
      else {
        print('Ошибка при добавлении новости: ${response.statusCode}');
        print('Ошибка: ${response.data}');
      }
    } catch (e) {
      print('Исключение при добавлении новости: $e');
    }
  }


  Future<void> _playVideo(String path) async {
    final videoFile = File(path);
    final videoPlayerController = VideoPlayerController.file(videoFile);
    await videoPlayerController.initialize();
    // Установите начальную позицию и поставьте на паузу для отображения первого кадра
    videoPlayerController.play();
    videoPlayerController.pause();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: AspectRatio(
          aspectRatio: videoPlayerController.value.aspectRatio,
          child: VideoPlayer(videoPlayerController),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              videoPlayerController.dispose();
            },
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }


  Widget _buildMediaPreview() {
    final PageController pageController = PageController();
    var size = MediaQuery.of(context).size.width - 32; // Получаем ширину экрана и вычитаем горизонтальные отступы

    return Column(
      children: [
        SizedBox(
          height: size, // Размеры виджета PageView под аспект 1:1
          width: size,
          child: PageView.builder(
            controller: pageController,
            itemCount: _selectedMedia.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final media = _selectedMedia[index];
              final file = File(media.path);
              final mimeType = lookupMimeType(media.path);
              final isVideo = mimeType != null && mimeType.startsWith('video/');

              return Stack(
                children: [
                  if (isVideo) FutureBuilder<VideoPlayerController>(
                    future: _getOrCreateController(file.path),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return InkWell(
                          onTap: () => _playVideo(file.path),
                          child: AspectRatio(
                            aspectRatio: snapshot.data!.value.aspectRatio,
                            child: VideoPlayer(snapshot.data!),
                          ),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ) else InkWell(
                    onTap: () async {
                      final croppedImage = await _cropImage(file.path);
                      if (croppedImage != null) {
                        setState(() {
                          _selectedMedia[index] = XFile(croppedImage.path);
                        });
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 1, // Устанавливаем аспект 1:1
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMedia.removeAt(index);
                          _videoControllers.remove(file.path); // Удаление контроллера, если он есть
                          if (_currentPage >= _selectedMedia.length && _currentPage > 0) {
                            _currentPage--; // Уменьшить текущий индекс, если последняя страница была удалена
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54, // Частичная прозрачность для лучшей видимости
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 30, color: Colors.white),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54, // Частичная прозрачность для лучшей видимости
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentPage + 1} из ${_selectedMedia.length}',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить новость', style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white), // Установка цвета иконок на белый

        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedMedia.isNotEmpty) _buildMediaPreview(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _selectMedia('image'),
                      icon: Icon(Icons.image),
                      label: Text('Добавить фото'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700]?.withOpacity(0.4),
                        foregroundColor: Colors.deepOrangeAccent,
                      ),
                    ),
                    SizedBox(width: 35), // Отступ между кнопками
                    ElevatedButton.icon(
                      onPressed: () => _selectMedia('video'),
                      icon: Icon(Icons.videocam),
                      label: Text('Добавить видео'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700]?.withOpacity(0.4),
                        foregroundColor: Colors.deepOrangeAccent,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание новости',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addNews,
                child: Text('Опубликовать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700]?.withOpacity(0.4),
                  foregroundColor: Colors.deepOrangeAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<VideoPlayerController> _getOrCreateController(String path) async {
    VideoPlayerController controller;
    if (!_videoControllers.containsKey(path)) {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.setLooping(true); // Чтобы видео зацикливалось
      _videoControllers[path] = controller;
    } else {
      controller = _videoControllers[path]!;
    }

    if (controller.value.hasError) {
      print('Ошибка при инициализации видео: ${controller.value.errorDescription}');
    }

    return controller;
  }

  @override
  void dispose() {
    _videoControllers.values.forEach((controller) {
      controller.dispose();
    });
    _videoControllers.clear();
    super.dispose();
  }


}

