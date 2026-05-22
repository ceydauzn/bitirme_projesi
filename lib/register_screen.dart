import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'role_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _studentIdController =
      TextEditingController(); // Veli için

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = false;
  String _errorMessage = '';

  // Rol ve Sınıf Seçimleri
  String _selectedRole = 'rehberlik'; // Varsayılan rol
  String? _selectedClass;

  final List<String> _classList = [
    '9-A',
    '9-B',
    '10-A',
    '10-B',
    '11-A',
    '11-B',
    '12-A',
    '12-B',
  ];

  Future<void> _registerUser() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Lütfen temel alanları doldurun.');
      return;
    }

    // Role özel boşluk kontrolü
    if (_selectedRole == 'ogretmen' && _selectedClass == null) {
      setState(() => _errorMessage = 'Lütfen sorumlu olduğunuz sınıfı seçin.');
      return;
    }
    if (_selectedRole == 'veli' && _studentIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Lütfen öğrenci numarasını girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        // Yeni Database servisimize verileri gönderiyoruz
        await _dbService.saveUserData(
          userCredential.user!.uid,
          _nameController.text.trim(),
          _emailController.text.trim(),
          _selectedRole,
          className: _selectedRole == 'ogretmen' ? _selectedClass : null,
          studentId: _selectedRole == 'veli'
              ? _studentIdController.text.trim()
              : null,
        );

        if (mounted) {
          // Başarılı kayıttan sonra giriş yapması için Rol Seçim ekranına yönlendir
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kayıt Başarılı! Lütfen giriş yapın."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const RoleSelectionScreen(),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Bir hata oluştu.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            child: _buildCircle(200, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildCircle(250, Colors.white.withValues(alpha: 0.12)),
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
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
                          Icons.person_add_alt_1_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Yeni Hesap Oluştur",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25),

                        _buildTextField(
                          _nameController,
                          "Ad Soyad",
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _emailController,
                          "E-posta",
                          Icons.email_outlined,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _passwordController,
                          "Şifre (En az 6 hane)",
                          Icons.lock_outline,
                          isObscure: true,
                        ),
                        const SizedBox(height: 20),

                        // YENİ: ROL SEÇİM ALANI
                        _buildRoleDropdown(),
                        const SizedBox(height: 15),

                        // YENİ: ROLE GÖRE AÇILAN DİNAMİK ALANLAR
                        if (_selectedRole == 'ogretmen') _buildClassDropdown(),
                        if (_selectedRole == 'veli')
                          _buildTextField(
                            _studentIdController,
                            "Öğrenci Numarası",
                            Icons.badge_outlined,
                          ),

                        const SizedBox(height: 15),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20),

                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : _buildRegisterButton(),
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

  // Rol Seçim Kutusu
  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          dropdownColor: const Color(0xFF2a5298),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: const [
            DropdownMenuItem(
              value: 'rehberlik',
              child: Text("Rehberlik Servisi"),
            ),
            DropdownMenuItem(value: 'ogretmen', child: Text("Sınıf Öğretmeni")),
            DropdownMenuItem(value: 'veli', child: Text("Öğrenci Velisi")),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
              _selectedClass = null; // Rol değişince sınıfı sıfırla
              _studentIdController.clear(); // Rol değişince no'yu sıfırla
            });
          },
        ),
      ),
    );
  }

  // Sınıf Seçim Kutusu
  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          isExpanded: true,
          hint: const Text(
            "Sorumlu Olduğunuz Sınıf",
            style: TextStyle(color: Colors.white60),
          ),
          dropdownColor: const Color(0xFF2a5298),
          icon: const Icon(Icons.class_, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: _classList.map((String className) {
            return DropdownMenuItem(value: className, child: Text(className));
          }).toList(),
          onChanged: (value) => setState(() => _selectedClass = value),
        ),
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

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF38EF7D), Color(0xFF11998E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "KAYIT OL",
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
