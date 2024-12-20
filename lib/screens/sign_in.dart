import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // الشاشة الرئيسية
import 'admin_panel.dart'; // شاشة لوحة التحكم
import 'sign_up.dart'; // شاشة التسجيل

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // تحميل البريد المحفوظ
  }

  // تحميل البريد الإلكتروني المحفوظ
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('saved_email') ?? '';
      rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  // دالة تسجيل الدخول والتحقق من الدور
  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      // تسجيل الدخول باستخدام Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // جلب بيانات المستخدم من Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'user'; // التحقق من الدور

        if (rememberMe) {
          // حفظ البريد الإلكتروني في Shared Preferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('saved_email', emailController.text.trim());
          prefs.setBool('remember_me', true);
        }

        // توجيه المستخدم بناءً على الدور
        if (role == 'admin') {
          // توجيه إلى لوحة التحكم للأدمن
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanel()),
          );
        } else {
          // توجيه إلى الصفحة الرئيسية للمستخدم العادي
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login Failed!')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // دالة استعادة كلمة المرور
  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error sending email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (value) {
                    setState(() {
                      rememberMe = value!;
                    });
                  },
                ),
                const Text('Remember Me'),
                const Spacer(),
                TextButton(
                  onPressed: resetPassword,
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: signIn,
                    child: const Text('Sign In'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
