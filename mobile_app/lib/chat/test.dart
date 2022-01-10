import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool switchButton= false;
  Map<bool,String> text={false:'Off',true:'On'};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(

            expandedHeight: 400,
            toolbarHeight: 150,
            pinned: true,
            floating: false,
            backgroundColor: Colors.blueGrey,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(''),
              background: Container(
                color: Colors.green,
              ),
            ),

            /*actions: [
              IconButton(
                  onPressed: (){},
                  icon: Icon(Icons.video_call)
              ),
              IconButton(
                  onPressed: (){},
                  icon: Icon(Icons.call)
              ),
              IconButton(
                  onPressed: (){},
                  icon: Icon(Icons.more_vert)
              ),

            ],*/
            title:
              Container(

                  child: SafeArea(


                    child:Column(


                      children: [
                        Row(


                          children: [
                            IconButton(
                                onPressed: (){},
                                icon: Icon(Icons.arrow_back)
                            ),
                            Spacer(),

                            Row(
                              children: [
                                IconButton(
                                    onPressed: (){},
                                    icon: Icon(Icons.video_call)
                                ),
                                IconButton(
                                    onPressed: (){},
                                    icon: Icon(Icons.call)
                                ),
                                IconButton(
                                    onPressed: (){},
                                    icon: Icon(Icons.more_vert)
                                ),
                              ],
                            ),


                          ],
                        ),

                        Padding(
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 30),
                          child: Container(
                            transform: Matrix4.translationValues(-15, 0, 0),
                            child:ListTile(
                              title: Text('Name'),
                              subtitle: Text('last seen'),
                              leading: CircleAvatar(backgroundColor: Colors.green,radius: 30,),
                            ) ,
                          )
                        )


                      ],
                    ) ,
                  )
              ) ,

          ),
          SliverFillRemaining(
            child: Container(
              color: Colors.grey[800],
              child: Column(
                children: [

                  ListTile(
                    title: Text('Info'),
                  ),
                  ListTile(
                    title: Text('9819401014'),
                    subtitle: Text('Mobile'),
                  ),
                  ListTile(
                    title: Text('Notifications'),
                    subtitle: Text('Off'),
                    trailing: CupertinoSwitch(
                        value: switchButton,
                        onChanged: (value){
                          setState(() {
                            switchButton=value;

                          });

                        }
                    ),
                  )
                ],

              ),
            ),
          )
        ],
      ),
      /*appBar:AppBar(
        backgroundColor: Colors.green[800],
        flexibleSpace: SafeArea(
          child: Container(
            child: Row(
              children: [
                IconButton(
                  onPressed: (){},
                  icon: Icon(Icons.arrow_back)
                ),


              ],
            )
          )
        ),
        actions: [
          IconButton(
              onPressed: (){},
              icon: Icon(Icons.video_call)
          ),
          IconButton(
              onPressed: (){},
              icon: Icon(Icons.call)
          ),
          IconButton(
              onPressed: (){},
              icon: Icon(Icons.more_vert)
          ),

        ],
      ),

      body: Container(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(),
              title: Text('Name'),
              subtitle: Text('Last Seen'),
            ),
            ListTile(
              title: Text('Info'),
            ),
            ListTile(
              title: Text('9819401014'),
              subtitle: Text('Mobile'),
            ),
            ListTile(
              title: Text('Notifications'),
              subtitle: Text('On'),
              trailing: CupertinoSwitch(
                  value: switchButton,
                  onChanged: (value){
                    switchButton=value;
                  }
              ),
            )
          ],

        ),
      ),*/

    );
  }
}
