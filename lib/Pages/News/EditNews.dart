import 'dart:io';

import 'package:delwiz/Models/NewsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; // Убедитесь, что добавили зависимость в pubspec.yaml

class EditNews extends StatefulWidget {
  final int newsId;
  final String initialDescription;

  const EditNews({
    Key? key,
    required this.newsId,
    required this.initialDescription,
  }): super(key: key);

  @override
  _EditNewsState createState() => _EditNewsState();
}

class _EditNewsState extends State<EditNews> {
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile> _selectedMedia = [];
  final ImagePicker _picker = ImagePicker();
  final NewsService _newsService = NewsService();
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.initialDescription;
  }

  Future<void> _selectImage() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      for (var file in pickedFiles) {
        // Обрезка изображения
        var croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        );
        if (croppedFile != null) {
          setState(() {
            _selectedImages.add(XFile(croppedFile.path));
          });
        }
      }
    }
  }

  Future<void> _selectVideo() async {
    final XFile? pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedVideo != null) {
      setState(() {
        _selectedVideos.add(pickedVideo);
      });
    }
  }

  Future<void> _saveChanges() async {
    // Собираем все медиа файлы в один список
    List<XFile> mediaFiles = [..._selectedImages, ..._selectedVideos];

    await _newsService.editNews(
      newsId: widget.newsId,
      newDescription: _descriptionController.text,
      mediaFiles: mediaFiles,
    );
    Navigator.of(context).pop();
  }
  Widget _buildMediaListView() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Количество элементов в ряду
          crossAxisSpacing: 4.0, // Расстояние между элементами по горизонтали
          mainAxisSpacing: 4.0, // Расстояние между элементами по вертикали
        ),
        itemCount: _selectedImages.length + _selectedVideos.length,
        itemBuilder: (context, index) {
          bool isVideo = index >= _selectedImages.length;
          XFile media = isVideo ? _selectedVideos[index - _selectedImages.length] : _selectedImages[index];
          return GridTile(
            child: isVideo ?
            // Для видео показываем иконку
            Container(
              color: Colors.black45,
              child: Center(
                child: Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ) :
            // Для изображений используем Image.file
            Image.file(
              File(media.path),
              fit: BoxFit.cover,
            ),
            footer: GridTileBar(
              backgroundColor: Colors.black45,
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    if (isVideo) {
                      _selectedVideos.removeAt(index - _selectedImages.length);
                    } else {
                      _selectedImages.removeAt(index);
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _descriptionController.text = widget.initialDescription;

    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать новость'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectImage,
                    child: Text('Выбрать фото'),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectVideo,
                    child: Text('Выбрать видео'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildMediaListView(),
/*
            Expanded(
              child: ListView.builder(
                itemCount: _selectedMedia.length,
                itemBuilder: (context, index) {
                  var media = _selectedMedia[index];
                  bool isVideo = media.mimeType!.startsWith('video/');
                  return ListTile(
                    leading: isVideo ? Icon(Icons.videocam) : Icon(Icons.image),
                    title: Text(media.name),
                    subtitle: isVideo ? Text("Видео") : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => setState(() {
                        _selectedMedia.removeAt(index);
                      }),
                    ),
                  );
                },
              ),
            ),
*/
          ],
        ),
      ),
    );
  }
}