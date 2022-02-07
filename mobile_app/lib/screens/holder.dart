
import 'package:chat_app/screens/userspace/contacts/contacts.dart';
import 'package:chat_app/screens/userspace/conversation.dart';
import 'package:chat_app/screens/userspace/requests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
class Holder extends StatefulWidget {
  const Holder({Key? key}) : super(key: key);

  @override
  _HolderState createState() => _HolderState();
}

class _HolderState extends State<Holder> {
  int currentIndex = 0;
  dynamic userList;
  dynamic userMap;
  late dynamic id;
  List<String> title =['CONVERATIONS','REQUESTS'];

  Widget returnScreen(int index, dynamic users, dynamic you) {
    if (index == 0) {
      return Conversation(
        users: users,
        you: you,
      );
    } else  {
      return Requests(
        users: users,
        you: you,
      );
    }

    
  }

  @override
  Widget build(BuildContext context) {
    id = '';
    id = id.isEmpty ? ModalRoute.of(context)!.settings.arguments : id;
    return Scaffold(
        appBar: AppBar(
          title: Text('Safe Chat'),
          centerTitle: true,
          actions:<Widget>[
            currentIndex ==2? IconButton(
              icon: Icon(
                Icons.search,
              ),
              onPressed: () {
                
              },
            ):Container()
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
             showSearch(
                    context: context, delegate:ContactsPage(users: userList,you: userMap) );
          },
          child: Icon(Icons.message),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance),
                label: 'Conversations',
                backgroundColor: Colors.white),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance),
                label: 'Requests',
                backgroundColor: Colors.white),
            
          ],
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                  title[currentIndex],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25.sp,
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
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      userList = snapshot.data!.docs;
                      

                      userList.forEach((element) {
                        if (element.get('id') == id) {
                          userMap = element;
                        }
                      });

                      userList.remove(userMap);

                      return returnScreen(currentIndex, userList, userMap);
                    } else {
                      return Center(child: CircularProgressIndicator(),);
                    }
                  }),
            ),
          ],
        ));
  }
}
