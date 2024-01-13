import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:verdinho/chat_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());

  /*await Firebase.initializeApp();
  await FirebaseFirestore.instance.collection('col').doc('doc3').set({'text': 'daniel3'});

  DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('col').doc('doc3').get();
  print(snapshot.data());

  QuerySnapshot snapshot2 = await FirebaseFirestore.instance.collection('col').get();
  snapshot2.docs.forEach((d){
    print(d.data());
    d.reference.update({'text': 'daniel'});
    FirebaseFirestore.instance.collection('col').snapshots().listen((event) {
      event.docs.forEach((d){
        print(d.data());
      });
    });
  });*/
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        iconTheme: IconThemeData(
          color: Colors.blue,
        ),
      ),
      home: ChatScreen(),
    );
  }
}