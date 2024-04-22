import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;

  VideoScreen({required this.videoUrl});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializePlayer();
  }

  void _initializePlayer() async {
    await _controller.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: _controller.value.aspectRatio,
      autoPlay: true,
      looping: false,
      // Подготовка настроек контроллера
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.deepOrangeAccent,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
      placeholder: Container(
        color: Colors.black,
      ),
      autoInitialize: true,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? Chewie(
        controller: _chewieController,
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
