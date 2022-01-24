import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/preprocessing/embeddingBuilder.dart';

import 'package:chat_app/security/e2ee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Contacts extends StatefulWidget {
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  dynamic listOfSnapshots;
  dynamic userMap;
  late dynamic id;

  List<int> dynamic2Uint8ListConvert(List<dynamic> list) {
    var intList = <int>[];
    list.forEach((element) {
      intList.add(element as int);
    });

    return intList;
  }

  Widget widgetDecision(
      requestArray, acceptedArray, uid, BuildContext context, index) {
    if (listOfSnapshots[index].get('requestSent').contains(userMap.get('id'))) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
              onPressed: () {
                Provider.of<FireBaseFunction>(context, listen: false)
                    .acceptRequest(
                        userMap.get('requestAccepted'),
                        listOfSnapshots[index].get('requestSent'),
                        listOfSnapshots[index].get('id'),
                        id);
              },
              child: Icon(Icons.check)),
          TextButton(
              onPressed: () {
                Provider.of<FireBaseFunction>(context, listen: false)
                    .denyRequest(userMap.get('requestAccepted'),
                        listOfSnapshots[index].get('id'), id);
              },
              child: Icon(Icons.clear)),
        ],
      );
    } else if (userMap
            .get('requestAccepted')
            .contains(listOfSnapshots[index].get('id')) ||
        listOfSnapshots[index].get('requestAccepted').contains(id)) {
      return Column(
        children: [Icon(Icons.check), Text('Accepted')],
      );
    } else if (userMap
        .get('requestSent')
        .contains(listOfSnapshots[index].get('id'))) {
      return Column(
        children: [Icon(Icons.send), Text('Request sent')],
      );
    }

    return TextButton(
        onPressed: () {
          Provider.of<FireBaseFunction>(context, listen: false).sendRequest(
              userMap.get('requestSent'), listOfSnapshots[index].get('id'), id);
        },
        child: Icon(Icons.add));
  }

  @override
  void initState(){
    super.initState();
    EmbeddingBuilder.setEmbeddingData();

  }

  @override
  Widget build(BuildContext context) {
    id = '';
    id = id.isEmpty ? ModalRoute.of(context)!.settings.arguments : id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
              child: Center(
            child: Text(
              'Contacts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )),
        ),
      ),
      body: Container(
          child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          listOfSnapshots = snapshot.data!.docs;

                          listOfSnapshots.forEach((element) {
                            if (element.get('id') == id) {
                              userMap = element;
                            }
                          });

                          listOfSnapshots.remove(userMap);

                          return ListView.builder(
                              itemCount: listOfSnapshots.length,
                              itemBuilder: (context, index) {
                                return Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0)),
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.account_circle_outlined,
                                          size: 60,
                                        ),
                                        trailing: widgetDecision(
                                            listOfSnapshots[index]
                                                .get('requestSent'),
                                            listOfSnapshots[index]
                                                .get('requestAccepted'),
                                            listOfSnapshots[index].get('id'),
                                            context,
                                            index),
                                        title: Center(
                                          child: Text(
                                            listOfSnapshots[index].get('name'),
                                            style: TextStyle(fontSize: 17),
                                          ),
                                        ),
                                        subtitle: Center(
                                          child: Text(
                                            listOfSnapshots[index]
                                                .get('aboutMe'),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        onTap: () async {
                                          if (listOfSnapshots[index]
                                                  .get('requestAccepted')
                                                  .contains(id) ||
                                              userMap
                                                  .get('requestAccepted')
                                                  .contains(
                                                      listOfSnapshots[index]
                                                          .get('id'))) {
                                            SharedPreferences pref =
                                                await SharedPreferences
                                                    .getInstance();
                                            List<dynamic> sortList = [
                                              pref.getString('id'),
                                              listOfSnapshots[index].id
                                            ];
                                            sortList.sort();
                                            dynamic finalString =
                                                sortList[0] + sortList[1];

                                            if (!pref
                                                .getStringList('securedConvos')!
                                                .contains(finalString)) {
                                              var derivedBits = await End2EndEncryption
                                                  .returnDerivedBits(
                                                      json.decode(
                                                          listOfSnapshots[index]
                                                              .get(
                                                                  'publicKey')),
                                                      json.decode(
                                                          pref.getString(
                                                              'privateKey')!));
                                              var list = pref.getStringList(
                                                  'securedConvos');
                                              list!.add(finalString);
                                              pref.setStringList(
                                                  'securedConvos', list);
                                              var map = json.decode(
                                                  pref.getString(
                                                      'DerivedBitsMap')!);
                                              map[finalString] = derivedBits;

                                              await pref.setString(
                                                  'DerivedBitsMap',
                                                  json.encode(map));
                                            }

                                            Navigator.pushNamed(
                                                context, '/chatRoom',
                                                arguments: {
                                                  'chatID': finalString,
                                                  'id': pref.getString('id'),
                                                  'peerID':
                                                      listOfSnapshots[index].id,
                                                  'name': listOfSnapshots[index]
                                                      .get('name'),
                                                  'blocked':
                                                      listOfSnapshots[index]
                                                          .get('blocked'),
                                                  'blockedByYou':
                                                      userMap.get('blocked'),
                                                  'blockedStatus': userMap
                                                      .get('blocked')
                                                      .contains(
                                                          listOfSnapshots[index]
                                                              .get('id')),
                                                  'aboutMe':
                                                      listOfSnapshots[index]
                                                          .get('aboutMe'),
                                                  'DerivedBits':
                                                      dynamic2Uint8ListConvert(
                                                          json.decode(pref
                                                                  .getString(
                                                                      'DerivedBitsMap')!)[
                                                              finalString]),
                                                });
                                          } else {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'Please send a request to chat or wait for them to accept your request');
                                          }
                                        },
                                      ),
                                    ));
                              });
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      }),
                
          ),
    );
  }
}
