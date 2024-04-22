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

  final Map<int, bool> _isMuted = {}; // Для отслеживания состояния звука


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
                          return Center(child: CircularProgressIndicator());
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
                                    icon: Icon(Icons.more_vert, color: Colors.white),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ListTile(
                                              leading: Icon(Icons.save_alt),
                                              title: Text('Сохранить фото'),
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
                                                        SnackBar(content: Text("Фото сохранено!"), duration: Duration(seconds: 2))
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text("Не удалось сохранить фото."), duration: Duration(seconds: 2))
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("Ошибка сохранения: $e"), duration: Duration(seconds: 2))
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        "${_currentPageIndex + 1} из ${widget.news.mediaFiles.length}",
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                      backgroundImage: userProfileImage ?? AssetImage('path/to/default/avatar.jpg'), // Provide a default image
                      radius: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(widget.news.sendingTime),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.news.description,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
