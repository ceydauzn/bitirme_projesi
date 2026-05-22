import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'role_selection_screen.dart';

void main() async {
  // Widget'ların yüklenmesini garanti altına al
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat (Hatanın olduğu yer burasıydı)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rehberlik Sistemi',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki o çirkin debug yazısını kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Daha modern bir görünüm sağlar
      ),
      home:
          const RoleSelectionScreen(), // Uygulama açılınca bizim şık giriş ekranı gelsin
    );
  }
}
