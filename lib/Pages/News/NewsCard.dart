import 'package:delwiz/Pages/News/EditNews.dart';
import 'package:delwiz/Pages/News/NewsCommentsPage.dart';
import 'package:delwiz/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:video_player/video_player.dart';

import '../../Api/ApiRequest.dart';
import '../../Models/NewsDto.dart';
import '../../Models/NewsService.dart';
import '../../Service/UserPhotoManager.dart';
import 'VideoScreen.dart';
final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

class NewsCard extends StatefulWidget {
  final NewsDto news;

  NewsCard({
    required this.news,
  });

  @override
  _NewsCardState createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  final Map<int, VideoPlayerController> _videoControllers = {};
  int _currentPageIndex = 0;
  ImageProvider? userProfileImage;

  final Map
  <int, bool> _isMuted = {}; // Для отслеживания состояния звука


  @override
  void initState() {
    super.initState();
    _initializeMediaPlayers();
    _loadUserProfileImage();

  }
  final NewsService _newsService = NewsService();

  void _loadUserProfileImage() async {
    userProfileImage = await UserPhotoManager().getUserPhoto(widget.news.idUser);
    setState(() {});
  }

  void _initializeMediaPlayers() {
    for (var mediaFile in widget.news.mediaFiles.where((m) => m.type == 'video')) {
      var controller = VideoPlayerController.networkUrl(Uri.parse(mediaFile.url))..setVolume(0);
      _videoControllers[mediaFile.pictureId] = controller;
      _isMuted[mediaFile.pictureId] = false;
      // Инициализируем контроллер и настраиваем его
      controller.initialize().then((_) {
        controller.play(); // Запускаем видео
        
/*
        controller.pause(); // Сразу же ставим на паузу
*/
        setState(() {}); // Обновляем UI для отображения первого кадра
      }).catchError((error) {
        print("Ошибка при инициализации видео: $error");
      });
    }
  }
  void _updateNewsWithServerResponse(NewsDto newsItem, Map<String, dynamic> response) {
    newsItem.likesNotifier.value = response['likes'] ?? newsItem.likesNotifier.value;
    newsItem.dislikesNotifier.value = response['dislikes'] ?? newsItem.dislikesNotifier.value;
    // Нет необходимости в вызове setState, так как ValueListenableBuilder автоматически обновит UI
  }


  void _likeNews(int newsId, int idUser) async {
    try {
      final response = await _newsService.likeNews(newsId, idUser);
      if (!response.containsKey('error')) {
        if (widget.news.newsId == newsId) {
          _updateNewsWithServerResponse(widget.news, response);
        }
      } else {
        print(response['error']);
      }
    } catch (e) {
      print('Error liking news: $e');
    }
  }

  void _dislikeNews(int newsId, int idUser) async {
    try {
      final response = await _newsService.dislikeNews(newsId, idUser);
      if (!response.containsKey('error')) {
        if (widget.news.newsId == newsId) {
          _updateNewsWithServerResponse(widget.news, response);
        }
      } else {
        print(response['error']);
      }
    } catch (e) {
      print('Error disliking news: $e');
    }
  }

  @override
  void dispose() {
    _videoControllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[700]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.news.mediaFiles.isNotEmpty)
            AspectRatio(
              aspectRatio: widget.news.mediaFiles.any((media) => media.type == 'video') ? 9 / 16 : 1 / 1,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.news.mediaFiles.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPageIndex = index;
                        // Останавливаем все видео
                        _videoControllers.forEach((key, controller) {
                          if (controller.value.isInitialized) {
                            controller.pause();
                          }
                        });
                        // Воспроизводим видео только для текущей страницы
                        var currentMedia = widget.news.mediaFiles[index];
                        if (currentMedia.type == 'video' && _videoControllers[currentMedia.pictureId]?.value.isInitialized == true) {
                          _videoControllers[currentMedia.pictureId]!.play();
                        }
                      });
                    },


                    itemBuilder: (context, index) {
                      final mediaFile = widget.news.mediaFiles[index];
                      if (mediaFile.type == 'video') {
                        var controller = _videoControllers[mediaFile.pictureId];
                        if (controller != null && controller.value.isInitialized) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => VideoScreen(videoUrl: mediaFile.url),
                              ));
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: controller.value.size.width,
                                  height: controller.value.size.height,
                                  child: VideoPlayer(controller),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      } else {
                        // For images, simply fit them to cover the square area
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () => Navigator.pop(context), // Закрытие диалога при тапе за пределами изображения
                                  child: Scaffold(
                                    backgroundColor: Colors.black.withOpacity(0.7), // Полупрозрачный черный фон
                                    appBar: AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0, // Убираем тень
                                      actions: [
                                    IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ListTile(
                                              leading: const Icon(Icons.save_alt),
                                              title: const Text('Сохранить фото'),
                                              onTap: () async {
                                                try {
                                                  var response = await Dio().get(
                                                    mediaFile.url,
                                                    options: Options(responseType: ResponseType.bytes),
                                                  );
                                                  final result = await ImageGallerySaver.saveImage(
                                                      Uint8List.fromList(response.data),
                                                      quality: 60,
                                                      name: "saved_image"
                                                  );
                                                  Navigator.pop(context); // Close the modal bottom sheet
                                                  if (result['isSuccess']) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text("Фото сохранено!"), duration: Duration(seconds: 2))
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text("Не удалось сохранить фото."), duration: Duration(seconds: 2))
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("Ошибка сохранения: $e"), duration: const Duration(seconds: 2))
                                                  );
                                                }
                                              }
                                          );
                                        },
                                      );
                                    },
                                  ),


                                  // Другие действия, если они вам нужны
                                      ],
                                    ),
                                    body: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1 / 1,
                                        child: Container(
                                          width: MediaQuery.of(context).size.width, // Ширина изображения равна ширине экрана
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(mediaFile.url),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Image.network(mediaFile.url, fit: BoxFit.cover),
                        );


                      }

                    },
                  ),
                  if (widget.news.mediaFiles.any((media) => media.type == 'video'))
                    Positioned(
                      right: 10,
                      bottom: 50, // или любое другое значение для позиционирования
                      child: IconButton(
                        icon: Icon(
                          // Проверяем, что _isMuted для текущего индекса страницы не возвращает null, иначе используем false
                          _isMuted[widget.news.mediaFiles[_currentPageIndex].pictureId] ?? false ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            // Получаем mediaFile для текущего индекса страницы
                            final currentMedia = widget.news.mediaFiles[_currentPageIndex];
                            // Переключаем состояние звука
                            bool isCurrentlyMuted = _isMuted[currentMedia.pictureId] ?? true;
                            _videoControllers[currentMedia.pictureId]?.setVolume(isCurrentlyMuted ? 0 : 1);
                            _isMuted[currentMedia.pictureId] = !isCurrentlyMuted;
                          });
                        },
                      ),
                    ),

                  if(widget.news.mediaFiles.length > 1)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        "${_currentPageIndex + 1} из ${widget.news.mediaFiles.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),


          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: userProfileImage ?? const AssetImage('path/to/default/avatar.jpg'), // Provide a default image
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(widget.news.sendingTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.news.description,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if(widget.news.idUser == int.parse(IDUser) || nameRole != 'Блогер')...[

                    PopupMenuButton<String>(
                      onSelected: (String result) async{
                        switch (result) {
                          case 'Изменить':
                          // Открыть страницу редактирования
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditNews(
                                  newsId: widget.news.newsId, // Возьмите id новости, который нужно редактировать
                                  initialDescription: widget.news.description, // Возьмите начальное описание новости, чтобы отобразить на экране редактирования
                                ),
                              ),
                            );
                            break;
                          case 'Удалить':
                          // Действие по удалению новости
                            final shouldDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('Удалить публикацию?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete) {
                              try {
                                await deleteNews(widget.news.newsId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Публикация удалена'),
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка удаления: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                            break;
                          default:
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Изменить',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.deepOrange), // Серый цвет иконки для "Изменить"
                            title: Text(
                              'Изменить',
                              style: TextStyle(color: Colors.grey), // Серый цвет текста
                            ),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Удалить',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.deepOrange), // Использование deepOrange цвета для иконки "Удалить"
                            title: Text(
                              'Удалить',
                              style: TextStyle(color: Colors.grey), // Использование deepOrange цвета для текста
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
    ],
    ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: widget.news.likedByCurrentUser ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        _likeNews(widget.news.newsId, int.parse(IDUser));
                        setState(() {
                          widget.news.likedByCurrentUser = !widget.news.likedByCurrentUser;
                          if (widget.news.likedByCurrentUser) {
                            widget.news.dislikedByCurrentUser = false; // Ensure like/dislike are mutually exclusive
                          }
                        });
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: widget.news.likesNotifier,
                      builder: (context, value, child) {
                        return Text('$value ');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.thumb_down,
                        color: widget.news.dislikedByCurrentUser ? Colors.yellow : Colors.grey,
                      ),
                      onPressed: () {
                        _dislikeNews(widget.news.newsId, int.parse(IDUser));
                        setState(() {
                          widget.news.dislikedByCurrentUser = !widget.news.dislikedByCurrentUser;
                          if (widget.news.dislikedByCurrentUser) {
                            widget.news.likedByCurrentUser = false; // Ensure like/dislike are mutually exclusive
                          }
                        });
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: widget.news.dislikesNotifier,
                      builder: (context, value, child) {
                        return Text('$value ');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: Colors.grey, // Цвет иконки комментария
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsWithComments(newsCard: widget.news),
                          ),
                        );
                      },

                    ),

                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> deleteNews(int newsId) async {
    var dio = Dio();
    final response = await dio.delete('$api/News/$newsId');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete news');
    }
  }
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
