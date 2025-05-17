import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../utils/local_db.dart';
import '../utils/utils.dart';
import 'face_recognition/camera_page.dart';

class LoginPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const LoginPage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    final currentUser = LocalDB.getCurrentUser();
    printIfDebug(currentUser?.name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text("Authentification Faciale",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          )),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.deepPurple[800],
    ),
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 100,
              color: Colors.deepPurple[600],
            ),
            const SizedBox(height: 40),
            Text(
              "Bienvenue sur QuizPro",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Authentifiez-vous pour accéder à votre compte",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            buildButton(
              text: 'S\'inscrire',
              icon: Icons.app_registration_rounded,
              color: Colors.deepPurple[600]!,
              onClicked: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceScanScreen(
                      cameras: widget.cameras,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            buildButton(
              text: 'Se connecter',
              icon: Icons.login,
              color: Colors.deepPurple[400]!,
              onClicked: () async {
                final users = LocalDB.getAllUsers();
                if (users.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Aucun utilisateur trouvé. Veuillez vous inscrire d'abord."),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.deepPurple[300],
                      elevation: 6,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceScanScreen(
                      cameras: widget.cameras,
                      user: users.first,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget buildButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onClicked,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shadowColor: Colors.deepPurple.withOpacity(0.3),
          ),
          icon: Icon(icon, size: 24),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onClicked,
        ),
      );
}