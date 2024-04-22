import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:delwiz/Models/NewsDto.dart';
import 'package:delwiz/Pages/Profile/AchievementsTab.dart';
import 'package:delwiz/Pages/Profile/NewsDetailsScreen.dart';
import 'package:delwiz/Pages/Profile/VideoGridItem.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api/ApiRequest.dart';
import '../../Models/User.dart';
import '../Messages/ChatScreen.dart';
import '../AuthRegUser/Auth.dart';

class UserProfile extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String login;
  final int recipientId;
  final int senderId;
  final Uint8List? userPhoto;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.login,
    this.userPhoto,
    required this.recipientId,
    required this.senderId,
  });

  @override
  _UserProfileState createState() => _UserProfileState();
}
String? MaNameUser;
class _UserProfileState extends State<UserProfile> {
  bool isRequestSent = false;
  bool isRequestReceived = false;
  int? applicationId;
  bool isInFriends = false;
  Future<User> user = getUserInfoFromSharedPreferences();
  List<NewsDto> newsData = []; // Добавляем здесь
  List<Image> photoImages = [];

  set anOtherMenuActive(bool anOtherMenuActive) {}
  bool isDataLoaded = false;
  Future<void> _fetchUserPhotos() async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response =
      await _dio.get('$api/Users/user-photos/${widget.recipientId}');
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
  @override
  void initState() {
    super.initState();
    checkFriendRequest();
    checkIsInFriends();
    _getUserInfoFromPrefs();
    if (!isDataLoaded) {
      _fetchUserPhotos();
      _fetchUserNews();
    }
  }
  Future<void> _fetchUserNews() async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.json;
      Response response = await _dio.get('$api/Users/user-news/${widget.recipientId}');
      print('Response data: ${response.data}'); // Логирование ответа сервера
      if (response.statusCode == 200) {
        final newsListJson = response.data as List;
        List<NewsDto> newsList =
        newsListJson.map((json) => NewsDto.fromJson(json)).toList();
        setState(() {
          this.newsData = newsList; // Обновляем список новостей типа NewsDto
          isDataLoaded = true; // Обновляем флаг загрузки данных


        });
      } else {
        print(
            'Failed to fetch user news with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user news: $error');
    }
  }


  Future<void> _getUserInfoFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int userId = prefs.getInt('userId') ?? 0;
    final String firstName = prefs.getString('firstName') ?? '';
    final String lastName = prefs.getString('lastName') ?? '';
    final String loginUser = prefs.getString('loginUser') ?? '';
  MaNameUser = lastName;
    user = User(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      loginUser: loginUser,

    ) as Future<User>;

    setState(() {});
  }

  Future<void> checkIsInFriends() async {
    try {
      final inFriends = await isUserInFriends(int.parse(IDUser), widget.recipientId);
      setState(() {
        isInFriends = inFriends;
      });
    } catch (error) {
      print('Ошибка при проверке друзей: $error');
    }
  }

  Future<void> checkFriendRequest() async {
    final requestSent = await isFriendRequestSent(widget.recipientId, widget.senderId);
    final requestReceived = await isFriendRequestSent(widget.senderId, widget.recipientId);

    setState(() {
      isRequestSent = requestSent;
      isRequestReceived = requestReceived;
       anOtherMenuActive = true;
    });
  }

  Future<void> checkIdApplication() async {
    try {
      applicationId = await getApplicationIdByUser(int.parse(IDUser), widget.recipientId);
    } catch (error) {
      print('Ошибка при проверке заявки в друзья: $error');
    }
  }

  Future<void> acceptFriendRequest() async {
    try {
      await postFriendRequest(int.parse(IDUser), widget.recipientId);
      await postFriendRequest(widget.recipientId, int.parse(IDUser));
      await checkIdApplication();
      await deleteApplication(applicationId!);
    } catch (error) {
      print('Ошибка при принятии заявки в друзья: $error');
    }
  }
  Future<int?> getApplicationIdByUserIds(int userId, int recipientId) async {
    try {
      final Dio dio = Dio();
      final response = await dio.get('$api/Applications/$userId/$recipientId');
      if (response.statusCode == 200) {
        return response.data['idApplications'];
      } else {
        throw Exception('Failed to get application ID.');
      }
    } catch (error) {
      print('Ошибка при получении ID заявки: $error');
      return null;
    }
  }
  Future<int?> getApplicationIdByUser(int userId, int recipientId) async {
    try {
      final Dio dio = Dio();
      final response = await dio.get('$api/Applications/add/$userId/$recipientId');
      if (response.statusCode == 200) {
        return response.data['idApplications'];
      } else {
        throw Exception('Failed to get application ID.');
      }
    } catch (error) {
      print('Ошибка при получении ID заявки: $error');
      return null;
    }
  }

  Future<bool> isUserInFriends(int userId, int friendsId) async {
    try {
      final response = await Dio().get('$api/Friends');
      if (response.statusCode == 200) {
        final List<dynamic> friends = response.data;
        return friends.any((friend) => friend['userId'] == userId && friend['friendsId'] == friendsId);
      }
    } catch (error) {
      throw error;
    }
    return false;
  }
  Future<void> cancelFriendRequest() async {
    try {
      final Dio dio = Dio();
      final response = await dio.delete('$api/Applications/$applicationId');
      if (response.statusCode == 204) {
        print("Заявка успешно отменена");
        // Обновите локальное состояние, чтобы убрать иконку hourglass_top
        setState(() {
          isRequestSent = false;
        });
      } else {
        throw Exception('Failed to cancel the application.');
      }
    } catch (error) {
      print('Ошибка при отмене заявки: $error');
    }
  }

  Future<void> rejectFriendRequest() async {
    if (applicationId == null) {
      // Fetch the applicationId first
      applicationId = await getApplicationIdByUser(int.parse(IDUser), widget.recipientId);
    }

    if (applicationId != null) {
      try {
        final Dio dio = Dio();
        final response = await dio.delete('$api/Applications/$applicationId');
        if (response.statusCode == 204) {
          print("Friend request successfully rejected.");
          // Update local state to reflect that there's no longer an ongoing request
          setState(() {
            isRequestReceived = false;
          });
        } else {
          throw Exception('Failed to reject the friend request. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error rejecting friend request: $error');
      }
    } else {
      print('Application ID not found, cannot reject the request.');
    }
  }


  Future<void> deleteFriend(int userId, int friendId) async {
    try {
      final Dio dio = Dio();
      final response = await dio.delete('$api/Friends/$userId/$friendId');
      if (response.statusCode == 200) {
        print("Friend successfully deleted.");
        // Optionally, update your UI or state here
      } else {
        throw Exception('Failed to delete the friend. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting friend: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль' ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            ClipOval(
              child: SizedBox(
                width: 100,  // Diameter width
                height: 100, // Diameter height
                child: photoImages.isNotEmpty
                    ? photoImages.last
                    : const Icon(Icons.add_a_photo, size: 60), // Setting the Icon size for visual consistency
              ),
            ),
            SizedBox(height: 16),
            // Используем Stack для размещения текста и иконок
            Stack(
              children: [
                // Центрированный текст
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text('${widget.firstName} ${widget.lastName}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('@${widget.login}', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
                // Иконки, выровненные вправо
                Align(
                  alignment: Alignment.centerRight  ,
                  child: Padding(
                    padding: EdgeInsets.only(right: 30.0, top: 10), // Уменьшаем отступ с правого края
                    child: FutureBuilder<bool>(
                      future: isUserInFriends(int.parse(IDUser), widget.recipientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data ?? false) {
                            return IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final RenderBox button = context.findRenderObject() as RenderBox;
                                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(Offset.zero, ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );

                                final String? selectedValue = await showMenu<String>(
                                  context: context,
                                  position: position, // Use calculated coordinates
                                  items: [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Удалить из друзей', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                  color: Colors.deepOrangeAccent, // Background color of the menu
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  ),
                                );

                                if (selectedValue == 'delete') {
                                  await deleteFriend(int.parse(IDUser), widget.recipientId); // Assuming you have the IDs necessary to identify the friendship.
                                }

                              },
                            );

                          } else if (isRequestSent) {
                            return IconButton(
                              icon: Icon(Icons.hourglass_top, color: Colors.amber),
                              onPressed: () async {
                                applicationId = await getApplicationIdByUserIds(int.parse(IDUser), widget.recipientId);
                                if (applicationId != null) {
                                  final RenderBox button = context.findRenderObject() as RenderBox;
                                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                                  final RelativeRect position = RelativeRect.fromRect(
                                    Rect.fromPoints(
                                      button.localToGlobal(Offset.zero, ancestor: overlay),
                                      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                    ),
                                    Offset.zero & overlay.size,
                                  );
                                  final bool shouldCancel = await showMenu(
                                    color: Colors.deepOrangeAccent, // Цвет фона меню
                                    context: context,
                                    position: position, // Позиционирование меню
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10), // Скругление углов
                                    ),
                                    items: <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'cancel',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Внутренние отступы
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5), // Скругление углов внутри элемента меню
                                            color: Colors.transparent, // Прозрачный цвет для контейнера внутри PopupMenuItem
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(Icons.cancel, color: Colors.white), // Иконка отмены
                                              SizedBox(width: 10), // Пространство между иконкой и текстом
                                              Text(
                                                'Отменить заявку',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Стиль текста
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                      == 'cancel';
                                  if (shouldCancel) {
                                    await cancelFriendRequest();
                                  }
                                }
                              },
                            );


                          } else if (isRequestReceived) {
                            return IconButton(
                              icon: Icon(Icons.person_add, color: Colors.deepOrangeAccent),
                              onPressed: () async {
                                final RenderBox button = context.findRenderObject() as RenderBox;
                                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(Offset.zero, ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );

                                final String? selectedValue = await showMenu<String>(
                                  context: context,
                                  position: position, // Используйте рассчитанные координаты
                                  items: [
                                    PopupMenuItem<String>(
                                      value: 'accept',
                                      child: ListTile(
                                        leading: Icon(Icons.check, color: Colors.green),
                                        title: Text('Принять', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'reject',
                                      child: ListTile(
                                        leading: Icon(Icons.cancel, color: Colors.red),
                                        title: Text('Отклонить', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                  color: Colors.deepOrangeAccent, // Цвет фона меню
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0), // Скругление углов
                                  ),
                                );

                                if (selectedValue == 'accept') {
                                  await acceptFriendRequest();
                                } else if (selectedValue == 'reject') {
                                  await rejectFriendRequest();
                                }
                                setState(() {});
                              },
                            );
                          }

                          else {
                            return IconButton(
                              icon: Icon(Icons.person_add, color: Colors.deepOrangeAccent),
                              onPressed: () async {
                                await sendFriendRequest(widget.recipientId, widget.senderId);
                                setState(() {
                                  isRequestSent = true;
                                });
                              },
                            );
                          }
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => ChatScreen(
                      senderId: widget.senderId,
                      recipientId: widget.recipientId,
                      senderAvatar: widget.userPhoto,
                      recipientAvatar: widget.userPhoto,
                      nameUser: widget.lastName,
                    ),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepOrangeAccent),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                ),
              ),
              child: Text('Отправить сообщение'),
            ),
            TabBar(
              tabs: [
                const Tab(text: "Фотографии"),
                const Tab(text: "Достижения"),
              ],
              indicatorColor: Colors.deepOrangeAccent,
              labelColor: Colors.grey[700],
              unselectedLabelColor: Colors.grey[700],
            ),
            Container(
              height: 400, // Задайте подходящую высоту
              child: TabBarView(
                key: const PageStorageKey<String>('newsListKey'),
                children: [
                  // Вкладка Фотографии
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: newsData.length,
                    itemBuilder: (BuildContext context, int index) {
                      final newsItem = newsData[index];
                      final firstMediaFile = newsItem.mediaFiles.isNotEmpty ? newsItem.mediaFiles.first : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsListScreen(newsList: newsData), // Передаем конкретную новость
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.all(0),
                          child: firstMediaFile != null ? (
                              firstMediaFile.type == 'video' ?
                              VideoGridItem(videoUrl: firstMediaFile.url, newsData: newsData,) : // Используем VideoGridItem для видео
                              CachedNetworkImage( // Виджет для изображения
                                imageUrl: firstMediaFile.url,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                fit: BoxFit.cover,
                              )
                          ) : Container(
                            alignment: Alignment.center,
                            child: const Text('Нет медиа'),
                          ),
                        ),
                      );
                    },
                  ),


                  // Вкладка Достижения
                  AchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }




}
