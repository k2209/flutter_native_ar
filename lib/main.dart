
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const glbUrl = 'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
const usdzUrl = 'https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native AR Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Flutter Native AR Demo'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String? title;
  const MyHomePage({Key? key, this.title}) : super(key: key);

  void _handleAndroidAR(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        await ARLauncher.launchARAndroidIntent(glbUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to launch AR intent.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is only available on Android.')),
      );
    }
  }

  void _handleiOSAR(BuildContext context) async {
    if (Platform.isIOS) {
      try {
        await ARLauncher.launchARIosQuickLook(usdzUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open AR model on iOS.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is only available on iOS.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? '',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              _FancyButton(
                label: "AR Android",
                icon: Icons.android_rounded,
                color1: Colors.greenAccent,
                color2: Colors.teal,
                onPressed: () {
                  _handleAndroidAR(context);
                },
              ),
              const SizedBox(height: 24),
              _FancyButton(
                label: "AR iOS",
                icon: Icons.apple_rounded,
                color1: Colors.black87,
                color2: Colors.grey,
                onPressed: () {
                  _handleiOSAR(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FancyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onPressed;

  const _FancyButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        splashColor: Colors.white24,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color2.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 18),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ARLauncher {
  static const MethodChannel _channel = MethodChannel('ar_intent_channel');

  static Future<void> launchARAndroidIntent(String glbUrl) async {
    await _channel.invokeMethod('launchARIntent', {'url': glbUrl});
  }

  static Future<void> launchARIosQuickLook(String usdzUrl) async {
    await _channel.invokeMethod('launchARQuickLook', {'url': usdzUrl});
  }
}


// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'AR Quick Look Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const ARQuickLookScreen(),
//     );
//   }
// }

// class ARQuickLookScreen extends StatelessWidget {
//   const ARQuickLookScreen({super.key});

//   // The URL of the USDZ model for Apple Quick Look AR
//   // This is a direct link to the model on Apple's developer site.
//   final String usdzModelUrl =
//       'https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz';

//   /// Attempts to open the AR Quick Look experience.
//   /// On iOS, a direct link to a .usdz file is automatically handled by Quick Look.
//   Future<void> _openARQuickLook(BuildContext context) async {
//     final Uri url = Uri.parse(usdzModelUrl);

//     try {
//       // It's generally good practice to check if a URL can be launched,
//       // but for well-known schemes like https on iOS, it often isn't strictly necessary
//       // as launchUrl will attempt to open directly.
//       // The error you're seeing suggests the problem is deeper in the native bridge.
//       if (await canLaunchUrl(url)) {
//         // Attempt to launch the URL. iOS should automatically open Quick Look.
//         await launchUrl(url);
//       } else {
//         // Fallback if the URL somehow can't be launched (e.g., no app to handle it)
//         _showErrorSnackBar(context, 'Could not open AR view: No handler found for URL.');
//         print('Error: Could not launch $url');
//       }
//     } catch (e) {
//       // Catch any exceptions during the launch process, including PlatformException
//       _showErrorSnackBar(context, 'Failed to open AR view. Error: ${e.toString()}');
//       print('Caught exception: $e');
//     }
//   }

//   // Helper function to show a snackbar with an error message
//   void _showErrorSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AR Quick Look Demo'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Tap the button to launch the AR Quick Look experience for a teapot model.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: () => _openARQuickLook(context), // Pass context to the method
//               icon: const Icon(Icons.videocam),
//               label: const Text(
//                 'Open AR View',
//                 style: TextStyle(fontSize: 18),
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
