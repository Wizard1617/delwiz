import 'package:delwiz/Api/ApiRequest.dart';
import 'package:delwiz/Models/NewsDto.dart';
import 'package:delwiz/Models/NewsService.dart';
import 'package:delwiz/Pages/News/VideoScreen.dart';
import 'package:delwiz/Service/UserPhotoManager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class NewsWithComments extends StatefulWidget {
  final NewsDto newsCard;

  const NewsWithComments({Key? key, required this.newsCard}) : super(key: key);

  @override
  State<NewsWithComments> createState() => _NewsWithCommentsState();
}

class _NewsWithCommentsState extends State<NewsWithComments> {
  int _currentPageIndex = 0;

  final Map<int, VideoPlayerController> _videoControllers = {};

  final Map<int, bool> _isMuted = {}; // Для отслеживания состояния звука
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMediaPlayers();
    _loadUserProfileImage();
    _loadComments();
  }
// Предположим, что у вас уже имеется экземпляр Dio
  final Dio dio = Dio();

  void _sendComment() async {
    final String apiUrl = "$api/Comments";
    final int idNews = widget.newsCard.newsId;  // Пример id новости
    final String commentText = _commentController.text; // Текст комментария из TextFormField

    if(commentText.isNotEmpty) {
      final DateTime sendingTime = DateTime.now(); // Время отправления

      try {
        final response = await dio.post(
            apiUrl,
            data: {
              "idNews": idNews,
              "idUser": IDUser,
              "commentText": commentText,
              "sendingTime": sendingTime.toIso8601String(),
            },
            options: Options(
                headers: {
                  'accept': 'text/plain',
                  'Content-Type': 'application/json'
                }
            )
        );

        // Проверка статуса ответа
        if(response.statusCode == 201) {
          print('Комментарий успешно отправлен.');
          setState(() {
            // Добавляем новый комментарий в начало списка, чтобы он появился первым
            comments.insert(0, response.data);
            // Очищаем поле ввода
            _commentController.clear();
          });
        } else {
          // Обработка ошибок
          print('Ошибка при попытке отправить комментарий: ${response.statusCode}');
        }
      } catch (e) {
        // Обработка исключений при отправке комментария
        print('Исключение при отправке комментария: $e');
      }
    } else {
      print('Текст комментария не может быть пустым.');
    }
  }
  List comments = [];

  Future<void> _loadComments() async {
    try {
      final response =
          await dio.get('$api/Comments/News/${widget.newsCard.newsId}');
      if (response.statusCode == 200) {
        setState(() {
          comments = response.data;
        });
      } else {
        // Handle other errors.
        print('Ошибка получения данных: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions, such as no internet connection.
      print('An exception occurred: $e');
    }
  }
  void _showDeleteConfirmationDialog(BuildContext context, int commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение'),
          content: Text('Удалить комментарий?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалоговое окно подтверждения
              },
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () async {
                // Вызов функции для удаления комментария
                await _deleteComment(commentId);
                Navigator.of(context).pop(); // Закрыть диалоговое окно подтверждения
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(int commentId) async {
    final Dio dio = Dio();
    try {
      final response = await dio.delete(
        '$api/Comments/$commentId',
        options: Options(headers: {'accept': 'text/plain'}),
      );
      if (response.statusCode == 200) {
        print('Комментарий успешно удален.');
        setState(() { // Обновляем состояние
          // Удалить комментарий из списка по ID
          comments.removeWhere((c) => c['iD_Comment'] == commentId);
        });
      } else {
        print('Произошла ошибка при удалении комментария: ${response.statusCode}');
      }
      // Если нужно, здесь можно обрабатывать данные ответа
    } catch (e) {
      print('Исключение при попытке удалить комментарий: $e');
    }
  }

  void _showEditDeleteDialog(BuildContext context, Map<String, dynamic> comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите действие'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                InkWell(
                  child: Text('Изменить'),
                  onTap: () {
                    // Логика для изменения комментария
                    Navigator.of(context).pop(); // Закрыть диалоговое окно
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                InkWell(
                  child: Text('Удалить'),
                  onTap: () {
                    // Закрываем предыдущее диалоговое окно
                    Navigator.of(context).pop();
                    // Показать диалоговое окно подтверждения
                    _showDeleteConfirmationDialog(
                        context, comment['iD_Comment']);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initializeMediaPlayers() {
    for (var mediaFile
        in widget.newsCard.mediaFiles.where((m) => m.type == 'video')) {
      var controller =
          VideoPlayerController.networkUrl(Uri.parse(mediaFile.url))
            ..setVolume(0);
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

  final NewsService _newsService = NewsService();

  void _likeNews(int newsId, int idUser) async {
    try {
      final response = await _newsService.likeNews(newsId, idUser);
      if (!response.containsKey('error')) {
        if (widget.newsCard.newsId == newsId) {
          _updateNewsWithServerResponse(widget.newsCard, response);
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
        if (widget.newsCard.newsId == newsId) {
          _updateNewsWithServerResponse(widget.newsCard, response);
        }
      } else {
        print(response['error']);
      }
    } catch (e) {
      print('Error disliking news: $e');
    }
  }

  void _updateNewsWithServerResponse(
      NewsDto newsItem, Map<String, dynamic> response) {
    newsItem.likesNotifier.value =
        response['likes'] ?? newsItem.likesNotifier.value;
    newsItem.dislikesNotifier.value =
        response['dislikes'] ?? newsItem.dislikesNotifier.value;
    // Нет необходимости в вызове setState, так как ValueListenableBuilder автоматически обновит UI
  }

  ImageProvider? userProfileImage;

  void _loadUserProfileImage() async {
    userProfileImage =
        await UserPhotoManager().getUserPhoto(widget.newsCard.idUser);
    setState(() {});
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Комментарии'),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          // Оставляет место для поля ввода
          child: Column(children: [
            // Вывод карточки новости
            Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Вывод фото и видео
                  if (widget.newsCard.mediaFiles.isNotEmpty)
                    AspectRatio(
                      aspectRatio: widget.newsCard.mediaFiles
                              .any((media) => media.type == 'video')
                          ? 9 / 16
                          : 1 / 1,
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: widget.newsCard.mediaFiles.length,
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
                                var currentMedia =
                                    widget.newsCard.mediaFiles[index];
                                if (currentMedia.type == 'video' &&
                                    _videoControllers[currentMedia.pictureId]
                                            ?.value
                                            .isInitialized ==
                                        true) {
                                  _videoControllers[currentMedia.pictureId]!
                                      .play();
                                }
                              });
                            },
                            itemBuilder: (context, index) {
                              final mediaFile =
                                  widget.newsCard.mediaFiles[index];
                              if (mediaFile.type == 'video') {
                                var controller =
                                    _videoControllers[mediaFile.pictureId];
                                if (controller != null &&
                                    controller.value.isInitialized) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) => VideoScreen(
                                            videoUrl: mediaFile.url),
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
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              } else {
                                // For images, simply fit them to cover the square area
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          // Закрытие диалога при тапе за пределами изображения
                                          child: Scaffold(
                                            backgroundColor:
                                                Colors.black.withOpacity(0.7),
                                            // Полупрозрачный черный фон
                                            appBar: AppBar(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0, // Убираем тень
                                              actions: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.more_vert,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return ListTile(
                                                            leading: const Icon(
                                                                Icons.save_alt),
                                                            title: const Text(
                                                                'Сохранить фото'),
                                                            onTap: () async {
                                                              try {
                                                                var response =
                                                                    await Dio()
                                                                        .get(
                                                                  mediaFile.url,
                                                                  options: Options(
                                                                      responseType:
                                                                          ResponseType
                                                                              .bytes),
                                                                );
                                                                final result = await ImageGallerySaver.saveImage(
                                                                    Uint8List.fromList(
                                                                        response
                                                                            .data),
                                                                    quality: 60,
                                                                    name:
                                                                        "saved_image");
                                                                Navigator.pop(
                                                                    context); // Close the modal bottom sheet
                                                                if (result[
                                                                    'isSuccess']) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                      content: Text(
                                                                          "Фото сохранено!"),
                                                                      duration: Duration(
                                                                          seconds:
                                                                              2)));
                                                                } else {
                                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                      content: Text(
                                                                          "Не удалось сохранить фото."),
                                                                      duration: Duration(
                                                                          seconds:
                                                                              2)));
                                                                }
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(SnackBar(
                                                                        content:
                                                                            Text(
                                                                                "Ошибка сохранения: $e"),
                                                                        duration:
                                                                            const Duration(seconds: 2)));
                                                              }
                                                            });
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
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  // Ширина изображения равна ширине экрана
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                          mediaFile.url),
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
                                  child: Image.network(mediaFile.url,
                                      fit: BoxFit.cover),
                                );
                              }
                            },
                          ),
                          if (widget.newsCard.mediaFiles
                              .any((media) => media.type == 'video'))
                            Positioned(
                              right: 10,
                              bottom: 50,
                              // или любое другое значение для позиционирования
                              child: IconButton(
                                icon: Icon(
                                  // Проверяем, что _isMuted для текущего индекса страницы не возвращает null, иначе используем false
                                  _isMuted[widget
                                              .newsCard
                                              .mediaFiles[_currentPageIndex]
                                              .pictureId] ??
                                          false
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    // Получаем mediaFile для текущего индекса страницы
                                    final currentMedia = widget
                                        .newsCard.mediaFiles[_currentPageIndex];
                                    // Переключаем состояние звука
                                    bool isCurrentlyMuted =
                                        _isMuted[currentMedia.pictureId] ??
                                            true;
                                    _videoControllers[currentMedia.pictureId]
                                        ?.setVolume(isCurrentlyMuted ? 0 : 1);
                                    _isMuted[currentMedia.pictureId] =
                                        !isCurrentlyMuted;
                                  });
                                },
                              ),
                            ),
                          if (widget.newsCard.mediaFiles.length > 1)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                color: Colors.black.withOpacity(0.5),
                                child: Text(
                                  "${_currentPageIndex + 1} из ${widget.newsCard.mediaFiles.length}",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
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
                              backgroundImage: userProfileImage ??
                                  AssetImage('path/to/default/avatar.jpg'),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDateTime(
                                        widget.newsCard.sendingTime),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    widget.newsCard.description,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Логика для меню
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: widget.newsCard.likedByCurrentUser
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                _likeNews(
                                    widget.newsCard.newsId, int.parse(IDUser));
                                setState(() {
                                  widget.newsCard.likedByCurrentUser =
                                      !widget.newsCard.likedByCurrentUser;
                                  if (widget.newsCard.likedByCurrentUser) {
                                    widget.newsCard.dislikedByCurrentUser =
                                        false; // Ensure like/dislike are mutually exclusive
                                  }
                                });
                              },
                            ),
                            ValueListenableBuilder(
                              valueListenable: widget.newsCard.likesNotifier,
                              builder: (context, value, child) {
                                return Text('$value ');
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.thumb_down,
                                color: widget.newsCard.dislikedByCurrentUser
                                    ? Colors.yellow
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                _dislikeNews(
                                    widget.newsCard.newsId, int.parse(IDUser));
                                setState(() {
                                  widget.newsCard.dislikedByCurrentUser =
                                      !widget.newsCard.dislikedByCurrentUser;
                                  if (widget.newsCard.dislikedByCurrentUser) {
                                    widget.newsCard.likedByCurrentUser =
                                        false; // Ensure like/dislike are mutually exclusive
                                  }
                                });
                              },
                            ),
                            ValueListenableBuilder(
                              valueListenable: widget.newsCard.dislikesNotifier,
                              builder: (context, value, child) {
                                return Text('$value ');
                              },
                            ),
                            // Вывод количества дизлайков
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Поле для ввода комментария
        Container(
          height: 300,
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              var comment = comments[index];
              return ListTile(
                leading: CircleAvatar(
                  // Предполагается, что у вас уже есть доступ к URL аватара пользователя
                  backgroundImage: NetworkImage(comment['avatarUrl'] ?? 'путь/к/изображению/по/умолчанию.jpg'),
                ),
                title: Text(
                  comment['commentText'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().add_Hm().format(DateTime.parse(comment['sendingTime'])),
                  style: TextStyle(fontSize: 12),
                ),
                onLongPress: () {
                  if (comment['idUser'].toString() == IDUser.toString()) {
                    // Показать диалоговое окно с опциями "Изменить" и "Удалить"
                    _showEditDeleteDialog(context, comment);
                  }
                },
              );
            },
          ),
        ),

          ])),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Введите ваш комментарий',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendComment, // Передаем ссылку на функцию отправки комментария
            ),
          ],
        ),
      ),
    );
  }
}
