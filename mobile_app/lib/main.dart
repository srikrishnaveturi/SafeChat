import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/chat/chatRoom.dart';
import 'package:chat_app/preprocessing/natural_language_processing.dart';
import 'package:chat_app/screens/contactList.dart';
import 'package:chat_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/chat/test.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NLP.loadModel();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: FireBaseFunction())
    ],
    child:MaterialApp(
        initialRoute: '/login',
        routes:{
          '/home':(context)=>Contacts(),
          '/login':(context)=>LoginScreen(title: 'Air India'),
          '/chatRoom': (context)=>ChatRoom(),
          '/test':(context)=>Profile()
        }
    ))
  );
}

