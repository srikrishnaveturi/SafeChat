import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/preprocessing/embeddingBuilder.dart';
import 'package:chat_app/preprocessing/natural_language_processing.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:chat_app/service/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:sizer/sizer.dart';

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
  final scrollController = new ScrollController();
  Map<bool, String> map = {true: 'On', false: 'Off'};
  bool radio1 = false;
  bool radio2 = false;
  String toxicityLevel = '0';
  late List<dynamic> safeModeList;
  blockMechanism() async {
    data['blockedByYou'] =
        await Provider.of<FireBaseFunction>(context, listen: false)
            .onBlockOrUnblock(data['id'], data['peerID'], data['blockedByYou'],
                context, data['blockedStatus']);
    data['blockedStatus'] = !data['blockedStatus'];
  }

  Color safeModeColor(List<dynamic> ids, String uid, String peerID) {
    if ((ids.contains(uid) || ids.contains(peerID)) && ids.length == 1) {
      return Colors.yellow;
    } else if (ids.contains(uid) || ids.contains(peerID)) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  List<TextButton> getActions(bool second, BuildContext context, Widget content,
      String message, void Function(void Function()) stateChange) {
    if (!second) {
      return [
        TextButton(
            onPressed: () {
              stateChange(() {
                second = true;
                content = Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Text(message,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(
                        'Are you sure you want to report this message as NOT TOXIC?'),
                  ],
                );
              });
            },
            child: Text('Report')),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Exit'))
      ];
    } else {
      return [
        TextButton(
            onPressed: () async {
              stateChange(() {
                second = false;
                content = CircularProgressIndicator();
              });
              await ReportMessage.reportMessage(message, '0',
                  (String response) {
                Fluttertoast.showToast(msg: 'Message Reported');
              });
              Navigator.pop(context);
            },
            child: Text('Yes')),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('No'))
      ];
    }
  }

  Future<bool> fetchDecryptedMessages(
      List<QueryDocumentSnapshot> encryptedMessages) async {
    var holder = <String>[];
    var aesGcmSecretKey =
        await AesGcmSecretKey.importRawKey(data['DerivedBits']);
    for (var msg in encryptedMessages) {
      holder.add(await End2EndEncryption.decryption(
          aesGcmSecretKey, msg.get('content')));
    }
    decryptedMessages = holder;
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
                      Text(data['user_ID'])
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
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
                          TextButton(
                              onPressed: () async {
                                await blockMechanism();
                                Navigator.pop(context, !blockedStatus);
                              },
                              child: Text('Yes')),
                          TextButton(
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
              },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('id', isEqualTo: data['peerID'])
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    data['blocked'] = snapshot.data!.docs[0].get('blocked');
                  }
                  return Icon(blockedStatus ? Icons.undo : Icons.block);
                },
              )),
          TextButton(
              onPressed: () async {
                Provider.of<FireBaseFunction>(context, listen: false)
                    .updateSafeMode(data['chatID'], data['id'], safeModeList);
              },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(data['chatID'])
                    .collection('Status')
                    .doc('Status')
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    safeModeList = snapshot.data!.get('safeMode');
                    return Icon(
                      Icons.health_and_safety_outlined,
                      color: safeModeColor(snapshot.data!.get('safeMode'),
                          data['id'], data['peerID']),
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ))
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/Space.png'), fit: BoxFit.cover),
        ),
        child: Stack(
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
                      print('In Future');
                      return FutureBuilder(
                          future: fetchDecryptedMessages(snapshot.data!.docs),
                          builder: (context, AsyncSnapshot ss) {
                            if (ss.hasData) {
                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.99,
                                child: ListView.builder(
                                  itemCount: decryptedMessages.length,
                                  scrollDirection: Axis.vertical,
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onLongPress: () {
                                        Widget contentWidget = Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(10.w),
                                              child: Text(
                                                decryptedMessages[index],
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                                'Are you sure you want to report this message as TOXIC?')
                                          ],
                                        );
                                        showDialog(
                                            context: context,
                                            builder: (ctx) {
                                              return StatefulBuilder(
                                                  builder: (cx, stateChange) {
                                                return AlertDialog(
                                                  title: Text('REPORT'),
                                                  content: Container(
                                                      height: 30.h,
                                                      width: 70.h,
                                                      child: contentWidget),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () async {
                                                          stateChange(() {
                                                            contentWidget =
                                                                Expanded(
                                                                    child:
                                                                        Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ));
                                                          });
                                                          await ReportMessage
                                                              .reportMessage(
                                                                  decryptedMessages[
                                                                      index],
                                                                  toxicityLevel,
                                                                  (String
                                                                      response) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    'Message Reported');
                                                          });
                                                          Navigator.pop(ctx);
                                                        },
                                                        child: Text('Yes')),
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(ctx);
                                                        },
                                                        child: Text('No'))
                                                  ],
                                                );
                                              });
                                            });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            left: 14,
                                            right: 14,
                                            top: 10,
                                            bottom: 10),
                                        child: Align(
                                          alignment:
                                              (messages[index].get('idFrom') ==
                                                      data['id']
                                                  ? Alignment.topRight
                                                  : Alignment.topLeft),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: messages[index]
                                                          .get('idFrom') ==
                                                      data['id']
                                                  ? Colors.green[800]
                                                  : Colors.black,
                                              border: Border.all(
                                                  color: (messages[index]
                                                              .get('idFrom') ==
                                                          data['id']
                                                      ? Colors.green[800]!
                                                      : Colors.black)),
                                            ),
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              decryptedMessages[index],
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
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
                        if (data['blocked'].contains(data['id'])) {
                          Fluttertoast.showToast(
                              msg: "You have been blocked by this contact");
                        } else if (data['blockedByYou']
                            .contains(data['peerID'])) {
                          Fluttertoast.showToast(
                              msg: "You have blocked this contact");
                        } else {
                          if (safeModeList.length > 0) {
                            if (NLP.predict(textMessage.text,
                                    EmbeddingBuilder.embeddingData) >
                                0.5) {
                              bool second = false;
                              Widget content = Text(
                                  'Please refrain from using abusive or disrespectful language');

                              showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return StatefulBuilder(
                                        builder: (context, stateChange) {
                                      return AlertDialog(
                                          title: Text('WARNING!'),
                                          content: Container(
                                            width: 50.w,
                                            height: 30.h,
                                            child: content
                                            ),
                                          actions: [
                                            TextButton(
                                                onPressed: () async {
                                                  if (second) {
                                                    stateChange(() {
                                                      second = false;
                                                      content =
                                                          Center(child: CircularProgressIndicator(),);
                                                    });
                                                    await ReportMessage
                                                        .reportMessage(
                                                            textMessage.text,
                                                            '0',
                                                            (String response) {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              'Message Reported');
                                                    });
                                                    Navigator.pop(context);
                                                  }
                                                  stateChange(() {
                                                    second = true;
                                                    content = Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  10.w),
                                                          child: Text(
                                                              textMessage.text,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                        Text(
                                                            'Are you sure you want to report this message as NOT TOXIC?'),
                                                      ],
                                                    );
                                                  });
                                                },
                                                child: Text('Report')),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Exit'))
                                          ]);
                                    });
                                  });
                            } else {
                              Provider.of<FireBaseFunction>(context,
                                      listen: false)
                                  .onSendMessage(
                                      await End2EndEncryption.encryption(
                                          data['DerivedBits'],
                                          textMessage.text),
                                      data['id'],
                                      data['peerID'],
                                      textMessage,
                                      data['chatID']);
                            }
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
      ),
    );
  }
}
