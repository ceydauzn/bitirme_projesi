import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_panel.dart';
import 'register_screen.dart';
import 'parent_panel.dart';

class LoginScreen extends StatefulWidget {
  final String roleTitle;
  final String roleCode;

  const LoginScreen({
    super.key,
    required this.roleTitle,
    required this.roleCode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Asenkron işlem: Giriş yap
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- KONTROL 1 ---
      if (!mounted) return;

      User? user = userCredential.user;

      if (user != null && user.email != null) {
        // 2. Asenkron işlem: Firestore'dan veri çek
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();

        if (!mounted) return;

        if (userDoc.exists) {
          String dbRole = userDoc.get('role');

          // 👇 ASLA HATA VERMEYECEK AKILLI YETKİ KONTROLÜ 👇
          bool yetkiVar = false;

          if (widget.roleCode == 'veli' && dbRole == 'veli') {
            yetkiVar = true;
          } else if (widget.roleCode != 'veli' &&
              (dbRole == 'rehberlik' || dbRole == 'ogretmen')) {
            // Arayüzden ne gelirse gelsin, veritabanında rehberlik olan kişiyi içeri alıyoruz
            yetkiVar = true;
          }

          if (!yetkiVar) {
            // 3. Asenkron işlem: Yetki yoksa çıkış yap
            await _auth.signOut();

            if (!mounted) return;

            setState(() {
              _errorMessage =
                  'Hata: Bu panel için yetkiniz bulunmuyor! (Sistem: ${widget.roleCode}, DB: $dbRole)';
            });
            return;
          }

          // 👇 YÖNLENDİRME MANTIĞI 👇
          if (dbRole == 'rehberlik' || dbRole == 'ogretmen') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TeacherPanel()),
            );
          } else if (dbRole == 'veli') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ParentPanel()),
            );
          }
        } else {
          // 4. Asenkron işlem: Veritabanında rol yoksa çıkış yap
          await _auth.signOut();

          if (!mounted) return;

          setState(() {
            _errorMessage = 'Kullanıcı rolü veritabanında bulunamadı!';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _errorMessage = 'E-posta veya şifre hatalı!';
        } else {
          _errorMessage = e.message ?? 'Bir hata oluştu';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1e3c72),
                  Color(0xFF2a5298),
                  Color(0xFF2193b0),
                ],
              ),
            ),
          ),

          Positioned(
            top: -50,
            right: -50,
            child: _buildCircle(200, Colors.white10),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildCircle(250, Colors.white12),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Rehberlik Sistemi",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        Text(
                          "${widget.roleTitle} Girişi",
                          style: const TextStyle(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 40),
                        _buildTextField(
                          _emailController,
                          "E-posta",
                          Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          _passwordController,
                          "Şifre",
                          Icons.lock_outline,
                          isObscure: true,
                        ),
                        if (widget.roleCode == 'rehberlik')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _emailController.text =
                                        "rehberlik1@gmail.com";
                                    _passwordController.text = "123456";
                                  },
                                  child: const Text(
                                    "Rehberlik 1\n(12-A)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _emailController.text =
                                        "rehberlik2@gmail.com";
                                    _passwordController.text = "123456";
                                  },
                                  child: const Text(
                                    "Rehberlik 2\n(12-B)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 5),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : _buildLoginButton(),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Hesabınız yok mu? Kayıt Olun",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "GİRİŞ YAP",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
