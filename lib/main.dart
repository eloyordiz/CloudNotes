import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io'; // NOS DEVUELVE EL SO, PARA DISTINGUIR SI ESTAMOS EN LINUX, WINDOWS, MAC U ANDROID
import 'dart:ffi';
import 'package:sqlite3/open.dart';
import 'package:cloud_notes/views/home_screen.dart';
// IMPORTS PARA EL ALMACENAMIENTO EN NUBE
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    open.overrideFor(OperatingSystem.linux, () {
      return DynamicLibrary.open('libsqlite3.so.0');
    });

    //BASE DATOS LOCAL
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  //BASE DATOS NUBE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CloudNotesApp());
}

class CloudNotesApp extends StatelessWidget {
  const CloudNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: StreamBuilder(
        stream: AuthService().userStatus,
        builder: (context, snapshot) {
          // SI DEVUELVE USUARIO, NAVEGAMOS AL HOME
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // SI NO HAY USUARIO, NAVEGAMOS AL LOGIN
          else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
