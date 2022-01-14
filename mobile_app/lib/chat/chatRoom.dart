import 'dart:typed_data';

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/preprocessing/natural_language_processing.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:webcrypto/webcrypto.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  dynamic messages;
  TextEditingController textMessage = TextEditingController();
  dynamic data = {};
  List<String> decryptedMessages = [];
  late bool blockedStatus;
  bool safeModeStatus = true;
  ScrollController scrollController = new ScrollController();
  Map<bool, String> map = {true: 'On', false: 'Off'};

  blockMechanism() async {
    data['blockedByYou'] =
        await Provider.of<FireBaseFunction>(context, listen: false)
            .onBlockOrUnblock(data['id'], data['peerID'], data['blockedByYou'],
                context, data['blockedStatus']);
    data['blockedStatus'] = !data['blockedStatus'];
  }

  Future<bool> fetchDecryptedMessages(
      List<QueryDocumentSnapshot> encryptedMessages) async {
        print("LOOOOOOOOOOOOOOOOKKKKKKKKKKK ${data['DerivedBits']}");
        print(data['DerivedBits'].runtimeType);
         var aesGcmSecretKey = await AesGcmSecretKey.importRawKey(data['DerivedBits']);
    for (var msg in encryptedMessages) {
      decryptedMessages.add(await End2EndEncryption.decryption(
          aesGcmSecretKey, msg.get('content')));
    }
    print('DONEEEEEEEEEEEEEEEEEEEEEEEEEEEEE');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    data = data.isEmpty ? ModalRoute.of(context)!.settings.arguments : data;
    Provider.of<FireBaseFunction>(context).blocked = data['blockedStatus'];
    blockedStatus = Provider.of<FireBaseFunction>(context).blocked;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 2,
                ),
                CircleAvatar(
                  child: Icon(Icons.account_circle_outlined),
                  maxRadius: 20,
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        data['name'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(data['aboutMe'])
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FlatButton(
              onPressed: () async {
                bool x = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            'Are you sure you want to ${blockedStatus ? 'unblock' : 'block'} this conversation ?'),
                        content: Container(
                          width: 100,
                          height: 100,
                        ),
                        actions: [
                          FlatButton(
                              onPressed: () async {
                                await blockMechanism();
                                Navigator.pop(context, !blockedStatus);
                              },
                              child: Text('Yes')),
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context, blockedStatus);
                              },
                              child: Text('No'))
                        ],
                      );
                    });
                
                Provider.of<FireBaseFunction>(context, listen: false)
                    .getCurrentBlockedStatus(x);
                blockedStatus =
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .getBlockedStatus;
                print(blockedStatus);
              },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('id', isEqualTo: data['peerID'])
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    print(snapshot.data!.docs[0].get('blocked'));
                    data['blocked'] = snapshot.data!.docs[0].get('blocked');
                  }
                  return Icon(blockedStatus ? Icons.undo : Icons.block);
                },
              )),
          TextButton(
              onPressed: () async {
                var status = await FirebaseFirestore.instance
                    .collection('messages')
                    .doc(data['chatID'])
                    .collection('Status')
                    .doc('Status')
                    .get();
                if (status.get('safeMode')) {
                  if (status.get('userID') == data['id']) {
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .updateSafeMode(data['chatID'], data['id'],
                            !status.get('safeMode'));
                    Fluttertoast.showToast(
                        msg: 'Safe Mode ${map[!status.get('safeMode')]}');
                  } else {
                    showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Text('Safe Mode'),
                            content: Text('About Safe Mode'),
                          );
                        });
                  }
                } else {
                  Provider.of<FireBaseFunction>(context, listen: false)
                      .updateSafeMode(
                          data['chatID'], data['id'], !status.get('safeMode'));
                  Fluttertoast.showToast(
                      msg: 'Safe Mode ${map[!status.get('safeMode')]}');
                }
              },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(data['chatID'])
                    .collection('Status')
                    .doc('Status')
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  try {
                    safeModeStatus = snapshot.data!.get('safeMode');
                  } catch (e) {
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .setSafeMode(data['chatID'], data['id']);
                    safeModeStatus = true;
                  }

                  return Icon(
                    Icons.health_and_safety_outlined,
                    color: safeModeStatus ? Colors.green : Colors.red,
                  );
                },
              ))
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: [
              Flexible(
                  child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(data['chatID'])
                    .collection(data['chatID'])
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueGrey)));
                  } else {
                    messages = snapshot.data!.docs;

                    return FutureBuilder(
                        future: fetchDecryptedMessages(messages),
                        builder: (context, AsyncSnapshot ss) {
                          if (ss.hasData) {
                            print('SSSSSSSSSSSSSSSSSSSSSSSSSSSS $ss');
                            return ListView.builder(
                              itemCount: messages.length,
                              controller: scrollController,
                              scrollDirection: Axis.vertical,
                              padding: EdgeInsets.only(top: 10, bottom: 10),
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: EdgeInsets.only(
                                      left: 14, right: 14, top: 10, bottom: 10),
                                  child: Align(
                                    alignment: (messages[index].get('idFrom') ==
                                            data['id']
                                        ? Alignment.topRight
                                        : Alignment.topLeft),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: (messages[index]
                                                        .get('idFrom') ==
                                                    data['id']
                                                ? Colors.black
                                                : Colors.green)),
                                      ),
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        decryptedMessages[index],
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: (messages[index]
                                                        .get('idFrom') ==
                                                    data['id']
                                                ? Colors.black
                                                : Colors.green)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          else{
                            return Center(
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blueGrey)));
                          }
                        });
                  }
                },
              )),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: TextField(
                      controller: textMessage,
                      decoration: InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    onPressed: () async {
                      print(data['blocked']);
                      if (data['blocked'].contains(data['id'])) {
                        Fluttertoast.showToast(
                            msg: "You have been blocked by this contact");
                      } else if (data['blockedByYou']
                          .contains(data['peerID'])) {
                        Fluttertoast.showToast(
                            msg: "You have blocked this contact");
                      } else {
                        if (safeModeStatus) {
                          if (NLP.predict(textMessage.text) > 0.5) {
                            showDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    title: Text('WARNING!'),
                                    content: Text(
                                        'Please refrain from using abusive or disrespectful language'),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                          },
                                          child: Text('Exit'))
                                    ],
                                  );
                                });
                          } else {
                            Provider.of<FireBaseFunction>(context,
                                    listen: false)
                                .onSendMessage(
                                    await End2EndEncryption.encryption(
                                        data['DerivedBits'], textMessage.text),
                                    data['id'],
                                    data['peerID'],
                                    textMessage,
                                    data['chatID']);
                          }
                        } else {
                          Provider.of<FireBaseFunction>(context, listen: false)
                              .onSendMessage(textMessage.text, data['id'],
                                  data['peerID'], textMessage, data['chatID']);
                        }
                      }
                    },
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
