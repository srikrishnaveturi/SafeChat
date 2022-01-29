import 'package:chat_app/preprocessing/embeddingBuilder.dart';
import 'package:flutter/material.dart';
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({ Key? key }) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late dynamic id;
  @override
  Widget build(BuildContext context) {
    id = '';
    id = id.isEmpty ? ModalRoute.of(context)!.settings.arguments : id;
    EmbeddingBuilder.fetchJson(context, id);
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Align(
          alignment: Alignment.center,
          child: Image.asset('assets/images/splash.png'),
        )
      ),
    );
  }
}