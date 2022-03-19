import 'dart:convert';
import 'dart:io';

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  dynamic data;
  TextEditingController userID = TextEditingController();
  TextEditingController age = TextEditingController();
  final picker = ImagePicker();
  FileImage setImage = FileImage(File(''));
  String base64Image = '';

  void pickImageFromGallery() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 25);
    base64Image = base64Encode(await pickedFile!.readAsBytes());
    setState(() {
      setImage = FileImage(File(pickedFile.path));
    });
  }

  @override
  Widget build(BuildContext context) {
    data = data == null ? ModalRoute.of(context)!.settings.arguments : data;
    print('DATAAAAA $data');
    userID.text = data['user_ID'];
    age.text = data['age'].toString();
   if(base64Image.length==0){
     base64Image=data['image'];
   }
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Container(
              height: double.infinity,
              child: FormBuilder(
                child: SingleChildScrollView(
                  child: Center(
                    child: Center(
                      child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.w),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(15.w),
                                child: CircleAvatar(
                                 
                                  backgroundImage: base64Image.length == 0
                                      ? AssetImage('assets/images/Space.png')
                                      : Image.memory(
                                              base64Decode(base64Image))
                                          .image,
                                  radius: 12.w,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  pickImageFromGallery();
                                },
                                icon: Icon(Icons.camera),
                              ),
                              Text(
                                data['name'],
                                style: TextStyle(
                                  fontSize: 20.sp,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5.w),
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
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: 5.w, left: 5.w, right: 5.w),
                                child: FormBuilderTextField(
                                  name: 'Age',
                                  controller: age,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Age',
                                    labelText: 'Age',
                                    icon: Icon(
                                      Icons.cake,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 5.w, left: 5.w, right: 5.w),
                                    child: Text(
                                      'Converstaions : ${data['requestAccepted'].length}',
                                      style: TextStyle(fontSize: 15.sp),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 5.w, left: 5.w, right: 5.w),
                                    child: Text(
                                      'Requests : ${data['requestRecieved'].length}',
                                      style: TextStyle(fontSize: 15.sp),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                  onPressed: () {
                                    Provider.of<FireBaseFunction>(context,
                                            listen: false)
                                        .updateProfile(data['id'], userID.text,
                                            int.parse(age.text), base64Image);
                                    Navigator.pop(context);
                                    Fluttertoast.showToast(msg: 'Update sucessfull');
                                  },
                                  child: Text('Edit'))
                            ],
                          )),
                    ),
                  ),
                ),
              )),
        ));
  }
}
