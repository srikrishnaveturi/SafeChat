import 'dart:async';
import 'dart:convert';
import 'package:chat_app/chat/chatClass.dart';

import 'package:chat_app/security/e2ee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';


class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences? prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  User? currentUser;

  TextEditingController userID = TextEditingController();
  TextEditingController age = TextEditingController();

  final formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && prefs?.getString('id') != null) {
      Navigator.pushReplacementNamed(context, '/home',
          arguments: prefs!.getString('id'));
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> documents = result.docs;

        if (documents.length == 0) {
          // Update data to server if new user

          var x = await End2EndEncryption.generateKeys();

          FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set({
            'name': firebaseUser.displayName,
            'id': firebaseUser.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            'blocked': [],
            'user_ID': userID.text,
            'age': int.parse(age.text),
            'aboutMe': 'XYZ',
            'requestSent': [],
            'requestAccepted': [],
            'publicKey': json.encode(x[0])
          });

          // Write data to local
          currentUser = firebaseUser;
          await prefs?.setString('id', currentUser!.uid);
          await prefs?.setString('name', currentUser!.displayName ?? "");
          await prefs?.setString('blocked', '[]');

          await prefs?.setString('publicKey', json.encode(x[0]));
          await prefs?.setString('privateKey', json.encode(x[1]));
          await prefs?.setStringList('securedConvos', []);
          await prefs?.setString('DerivedBitsMap', json.encode({}));
        } else {
          DocumentSnapshot documentSnapshot = documents[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);
          // Write data to local
          await prefs?.setString('id', userChat.id);
          await prefs?.setString('name', userChat.name);
          await prefs?.setString('aboutMe', userChat.aboutMe);
          await prefs?.setString('blocked', '[]');
        }
        Fluttertoast.showToast(msg: "Sign in success");
        this.setState(() {
          isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/home',
            arguments: currentUser!.uid);
      } else {
        Fluttertoast.showToast(msg: "Sign in fail");
        this.setState(() {
          isLoading = false;
        });
      }
    } else {
      Fluttertoast.showToast(msg: "Can not init google sign in");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FormBuilder(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  height: MediaQuery.of(context).size.height * 0.3645,
                  width: MediaQuery.of(context).size.width * 1,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/Login.PNG'),
                        fit: BoxFit.cover),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    foreground: Paint()..shader=LinearGradient(
                      colors: <Color>[
                        Colors.blue[900]!,
                        Colors.blue[700]!,
                        Colors.blue[500]!,
                        Colors.blue[300]!,
                        
                      ]
                      ).createShader(Rect.fromLTWH(0, 0, 200, 100))
                  ), 
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: FormBuilderTextField(
                        name: 'UserID',
                        controller: userID,
                        
                        decoration: InputDecoration(
                          border: InputBorder.none,
                            hintText: 'User ID',
                            labelText: 'User ID',
                            icon: Icon(
                              Icons.account_box_outlined,
                              color: Colors.black,
                            ),),
                            
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(context),
                        ]),
                      ),
                    ),
                  ),
                ),
          
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: FormBuilderTextField(
                        name: 'age',
                        controller: age,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                            hintText: 'Age',
                            labelText: 'Age',
                            icon: Icon(
                              Icons.cake,
                              color: Colors.black,
                            ),
                            ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(context),
                          FormBuilderValidators.numeric(context),
                          FormBuilderValidators.max(context, 100)
                        ]),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: ButtonTheme(
                      minWidth: 200,
                      height: 700,
                      child: SignInButton(
                        Buttons.Google, text: 'Sign up with Google',
                      
                          onPressed: () {
                        if (formKey.currentState!.validate()) {
                          handleSignIn().catchError((err) {
                            Fluttertoast.showToast(msg: err.toString());
                            this.setState(() {
                              isLoading = false;
                            });
                          });
                        }
                      }),
                    ),
                  ),
                ),
                // Loading
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
