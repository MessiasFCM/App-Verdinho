import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:verdinho/text_composer.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  User? _currentUser;
  bool _isLoading = false;

  Future<User?> _getUser() async {

    if(_currentUser != null) { return _currentUser; }
    try{
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      return user;

    } catch (error) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  void _sendMessage({String? text, File? imgFile}) async {

    final User? user = await _getUser();

    if(user == null) {
      _scaffoldkey.currentState!.showSnackBar(
          const SnackBar(
            content: Text("Nao foi possivel fazer o login, tente novamente!"),
            backgroundColor: Colors.red,)
      );
    }

    Map<String, dynamic> data = {
      "uid" : user!.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoURL,
      'time': Timestamp.now(),
    };

    if(imgFile != null){
      setState(() {
        _isLoading = true;
      });
      TaskSnapshot taskSnapshot = await FirebaseStorage.instance.ref().child(
          user.uid + DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(imgFile);

      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;

      setState(() {
        _isLoading = false;
      });
    }

    if(text != null){
      data['text'] = text;
    }

    await FirebaseFirestore.instance.collection('messages2').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        title: Text(
          _currentUser != null ? 'Olá, ${_currentUser?.displayName}' : 'Verdinho'
        ),
        centerTitle: true,
        elevation: 0,
        actions: <Widget> [
          _currentUser != null ? IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: (){
                FirebaseAuth.instance.signOut();
                googleSignIn.signOut();
                _scaffoldkey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text("Você saiu com sucesso!")
                  ),
                );
              },
          ) : Container(),
        ],
      ),
      body: Column(
          children: <Widget>[
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('messages2').orderBy('time').snapshots(),
                  builder: (context, snapshot){
                    switch(snapshot.connectionState){
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      default:
                        List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();
                        
                        return ListView.builder(
                            itemCount: documents.length,
                            reverse: true,
                            itemBuilder: (context, index){
                              return ChatMessage(
                                  documents[index].data() as dynamic,
                                  documents[index].get('uid') == _currentUser?.uid,
                              );
                            }
                        );
                    }
                  },
                ),
            ),
            _isLoading ? LinearProgressIndicator() : Container(),
            TextComposer(_sendMessage),
          ],
      ),
    );
  }
}
