import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:letstransport/dataprovider/appdata.dart';
import 'package:letstransport/screens/loginpage.dart';
import 'package:letstransport/screens/mainpage.dart';
import 'dart:io';
import 'package:letstransport/screens/registrationpage.dart';
import 'package:provider/provider.dart';

//INITIALIZING FIREBASE DATABASE
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'db2',
    options: Platform.isIOS
        ? FirebaseOptions(
            googleAppID: '1:297855924061:ios:c6de2b69b03a5be8',
            apiKey: '',
            databaseURL: 'https://flutterfire-cd2f7.firebaseio.com',
          )
        : FirebaseOptions(
            googleAppID: '1:671442545106:android:8f5cb9f6b7d5c1c0efc00b',
            apiKey: '',
            databaseURL:
                'https://letstransport-3b8f3-default-rtdb.firebaseio.com',
          ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //highest place in widget tree
    //hence setting up the provider here, so that appdata can be accessed from
    //anywhere in the app
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'Brand-Regular',
            primarySwatch: Colors.blue,
          ),
          initialRoute: MainPage.id,
          routes: {
            RegistrationPage.id: (context) => RegistrationPage(),
            LoginPage.id: (context) => LoginPage(),
            MainPage.id: (context) => MainPage(),
          }),
    );
  }
}
