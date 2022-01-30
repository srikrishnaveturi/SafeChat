import 'dart:convert';

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ContactsPage extends SearchDelegate{
  dynamic users;
  dynamic you;
   List<int> dynamic2Uint8ListConvert(List<dynamic> list) {
    var intList = <int>[];
    list.forEach((element) {
      intList.add(element as int);
    });

    return intList;
  }

  Widget getTrailingWidget(requestSent,requestRecieved,requestAccepted,peerID,List<dynamic> suggestions,int index,BuildContext context){
    if(requestSent.contains(peerID)){
      return Icon(Icons.check);
    }

    else if(requestRecieved.contains(peerID)){
      return Column(
                children: [
                  Expanded(
                    child: ButtonTheme(
                      height: 15,
                      child: TextButton(
                          onPressed: () {
                            Provider.of<FireBaseFunction>(context, listen: false)
                                .acceptRequest(
                                    you.get('requestAccepted'),
                                    you.get('requestRecieved'),
                                    suggestions[index].get('requestAccepted'),
                                    suggestions[index].get('requestSent'),
                                    suggestions[index].get('id'),
                                    you.get('id'));
                          },
                          style: ButtonStyle(
                             
                              shape:
                                  MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                          side: BorderSide(color: Colors.red)))),
                          child: FittedBox(fit:BoxFit.fitHeight,child: Text('Accept'))),
                    ),
                  ),
                  SizedBox(height: 5,),
                      Expanded(
                        child: ButtonTheme(
                        height: 15,
                        child: TextButton(
                        onPressed: () {
                          
                        },
                        style: ButtonStyle(
                            shape:
                                MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(color: Colors.red)))),
                        child: FittedBox(fit:BoxFit.fitHeight,child: Text('Deny'))),
                      ),
                        )
                ],
              );
    }

    else if(requestAccepted.contains(peerID)){
      return SizedBox(height: 0,width: 0,);
    }

    else{
      return TextButton(
        onPressed: () {
          Provider.of<FireBaseFunction>(context, listen: false).sendRequest(
              you.get('requestSent'),suggestions[index].get('requestRecieved'), suggestions[index].get('id'), you.get('id'));
        },
        child: Icon(Icons.add));
    }
  }

  ContactsPage({this.users,this.you});
  @override
  List<Widget> buildActions(BuildContext context) {
    
    return [
      IconButton(
        onPressed: (){
          query = "";
        }, 
        icon: Icon(Icons.clear))
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    
    return IconButton(
      onPressed: (){
        close(context, null);
      }, 
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow, 
        progress: transitionAnimation)
      );
  }

  @override
  Widget buildResults(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<dynamic> suggestions = users.where((element){
      if(element.get('user_ID').toLowerCase().startsWith(query.toLowerCase()) || element.get('name').toLowerCase().startsWith(query.toLowerCase())){
        return true;
      }
      else{
        return false;
      }
    }).toList();
    return Column(
      children: [
        Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                  'CONTACTS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
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
                ],
                )),
        Expanded(
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context,index){
              return Card(
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: ListTile(
                    title: Center(
                      child: Text(suggestions[index].get('user_ID')),
                    ),
                    subtitle: Center(
                      child: Text(suggestions[index].get('name')),
                    ),
                    leading: Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.blue[800]
                    ),
                    onTap: () async {
                     if(you.get('requestAccepted').contains(suggestions[index].get('id'))){
                        SharedPreferences pref = await SharedPreferences.getInstance();
                      List<dynamic> sortList = [
                        pref.getString('id'),
                        suggestions[index].id
                      ];
                      sortList.sort();
                      dynamic finalString = sortList[0] + sortList[1];
        
                      if (!pref
                          .getStringList('securedConvos')!
                          .contains(finalString)) {
                        var derivedBits = await End2EndEncryption.returnDerivedBits(
                            json.decode(suggestions[index].get('publicKey')),
                            json.decode(pref.getString('privateKey')!));
                        var list = pref.getStringList('securedConvos');
                        list!.add(finalString);
                        pref.setStringList('securedConvos', list);
                        var map = json.decode(pref.getString('DerivedBitsMap')!);
                        map[finalString] = derivedBits;
        
                        await pref.setString('DerivedBitsMap', json.encode(map));
                      }
        
                      Navigator.pushNamed(context, '/chatRoom', arguments: {
                        'chatID': finalString,
                        'id': pref.getString('id'),
                        'peerID': suggestions[index].id,
                        'name': suggestions[index].get('name'),
                        'blocked': suggestions[index].get('blocked'),
                        'blockedByYou': you.get('blocked'),
                        'blockedStatus': you
                            .get('blocked')
                            .contains(suggestions[index].get('id')),
                        'user_ID': suggestions[index].get('user_ID'),
                        'DerivedBits': dynamic2Uint8ListConvert(json
                            .decode(pref.getString('DerivedBitsMap')!)[finalString]),
                      });
                     }
                    },
                    trailing: getTrailingWidget(you.get('requestSent'), you.get('requestRecieved'), you.get('requestAccepted'), suggestions[index].get('id'), suggestions, index, context),
                  ),
                ),
              );
            }
            ),
        ),
      ],
    );

  }
  
}