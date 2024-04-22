import 'package:delwiz/Models/NewsDto.dart';
import 'package:delwiz/Pages/Profile/NewsDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoGridItem extends StatefulWidget {
  final String videoUrl;
  final List<NewsDto> newsData;
  const VideoGridItem({Key? key, required this.videoUrl, required this.newsData}) : super(key: key);

  @override
  _VideoGridItemState createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<VideoGridItem> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // for re-rendering with the video widget
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller != null && _controller!.value.isInitialized
        ? GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsListScreen(newsList: widget.newsData), // Передаем конкретную новость
          ),
        );      },
      child: ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover, // Ensures the video is cropped to fill the square
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),
                  Icon(Icons.play_circle_outline, size: 50, color: Colors.white70), // Play icon overlay
                ],
              ),
            ),
          ),
        ),
      ),
    )
        : Center(
      child: CircularProgressIndicator(), // Loading indicator while video is not ready
    );
  }
}
