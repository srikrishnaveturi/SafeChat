import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FireBaseFunction extends ChangeNotifier {
  bool blocked = false;
  Widget widget = Container();
  bool safeMode = true;
  get getSafeMode {
    return safeMode;
  }

  get getBlockedStatus {
    return blocked;
  }

  storedBlockedState() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('blockedStatus');
  }

  void updateSafeMode(String groupChatId, String id, List<dynamic> ids) {
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection('Status')
        .doc('Status')
        .update({'safeMode': ids});
  }

  setSafeMode(String groupChatId, String id) {
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection('Status')
        .doc('Status');

    documentReference.get().then((document) {
      if (!document.exists) {
        FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
            documentReference,
            {
              'safeMode': [id]
            },
          );
        });
      }
    });
  }

  onSendMessage(String content, String id, String peerId,
      TextEditingController textEditingController, String groupChatId) {
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
          },
        );
      });
    }
  }

  onBlockOrUnblock(
      uid, peerID, array, BuildContext context, blockedStatus) async {
    if (blockedStatus) {
      array.remove(peerID);
    } else {
      array.add(peerID);
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'blocked': array});
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString('blocked', json.encode(array));
    return array;
  }

  getCurrentBlockedStatus(bool status) {
    blocked = status;
    notifyListeners();
  }

  sendRequest(requestArray, recievedArray, peerID, uid) {
    requestArray.add(peerID);
    recievedArray.add(uid);
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'requestSent': requestArray});
    FirebaseFirestore.instance
        .collection('users')
        .doc(peerID)
        .update({'requestRecieved': recievedArray});
  }

  acceptRequest(userAcceptArray, userRecievedArray, peerAcceptArray,
      peerRequestArray, peerID, uid) {
    userAcceptArray.add(peerID);
    userRecievedArray.remove(peerID);
    peerAcceptArray.add(uid);
    peerRequestArray.remove(uid);
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'requestAccepted': userAcceptArray});
    FirebaseFirestore.instance
        .collection('users')
        .doc(peerID)
        .update({'requestSent': peerRequestArray});
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'requestRecieved': userRecievedArray});
    FirebaseFirestore.instance
        .collection('users')
        .doc(peerID)
        .update({'requestAccepted': peerAcceptArray});
  }

  denyRequest(requestArray, recievedArray, peerID, uid) {
    requestArray.remove(peerID);
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'requestSent': requestArray});
  }
}
