

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/chat/chatRoom.dart';
import 'package:chat_app/preprocessing/natural_language_processing.dart';
import 'package:chat_app/screens/holder.dart';
import 'package:chat_app/screens/loadingScreen.dart';
import 'package:chat_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NLP.loadModel();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: FireBaseFunction())
    ],
    child:MaterialApp(
      localizationsDelegates: [
        FormBuilderLocalizations.delegate
      ],
        initialRoute: '/login',
        routes:{
          '/home':(context)=> Holder(),
          '/login':(context)=>LoginScreen(title: 'Safe Chat'),
          '/chatRoom': (context)=>ChatRoom(),
          '/splash':(context)=> LoadingScreen()
          
        }
    ))
  );
}

