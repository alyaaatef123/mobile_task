import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart'; // الصفحة الرئيسية


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إعداد Firebase Options للويب
  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyBKTP6T56nNxwBI-4pURxaVkOCFGetBBPg",
    authDomain: "mega-market-773aa.firebaseapp.com",
    projectId: "mega-market-773aa",
    storageBucket: "mega-market-773aa.appspot.com",
    messagingSenderId: "204378825312",
    appId: "1:204378825312:web:e041d90c232952bcd95905",
  );

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Shopping App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: const Center(
        child: Text(
          'Firebase Initialized Successfully!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
