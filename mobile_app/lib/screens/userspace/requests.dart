import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Requests extends StatefulWidget {
  final dynamic users;
  final dynamic you;
  Requests({Key? key, this.users, this.you}) : super(key: key);

  @override
  _RequestsState createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  dynamic requests = [];
  @override
  Widget build(BuildContext context) {
    requests = [];
    widget.users.forEach((element) {
      if (widget.you.get('requestRecieved').contains(element.get('id'))) {
        requests.add(element);
      }
    });
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ListTile(
              title: Center(
                child: Text(requests[index].get('name')),
              ),
              subtitle: Center(
                child: Text(requests[index].get('user_ID')),
              ),
              leading: Icon(
                Icons.account_circle,
                color: Colors.blue[800],
                size: 60,
              ),
              trailing: Column(
                children: [
                  Expanded(
                    child: ButtonTheme(
                      height: 15,
                      child: TextButton(
                          onPressed: () {
                            Provider.of<FireBaseFunction>(context, listen: false)
                                .acceptRequest(
                                    widget.you.get('requestAccepted'),
                                    widget.you.get('requestRecieved'),
                                    requests[index].get('requestAccepted'),
                                    requests[index].get('requestSent'),
                                    requests[index].get('id'),
                                    widget.you.get('id'));
                          },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.green),
                              shape:
                                  MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                          side: BorderSide(color: Colors.red)))),
                          child: FittedBox(fit:BoxFit.fitHeight,
                          child: Text(
                            'ACCEPT',
                            style: TextStyle(
                            color: Colors.white
                          ),
                            ))),
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
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                            shape:
                                MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(color: Colors.red)))),
                        child: FittedBox(fit:BoxFit.fitHeight,
                        child: Text(
                          'DENY',
                          style: TextStyle(
                            color: Colors.white
                          ),
                          ))),
                      ),
                        )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
