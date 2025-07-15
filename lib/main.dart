import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

const glbUrl = 'https://modelviewer.dev/shared-assets/models/Astronaut.glb';

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

class MyHomePage extends StatefulWidget {
  final String? title;
  const MyHomePage({Key? key, this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Converting model...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoader() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

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
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is only available on iOS.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    _showLoader();
    try {
      final apiUrl = Uri.parse(
          'https://dev.ahura.xyz:3003/convertglbtousdz?url=$glbUrl');
      final response = await http.get(apiUrl);

      if (response.statusCode != 200) {
        _hideLoader();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversion failed (API error).')),
        );
        return;
      }

      final map = jsonDecode(response.body);
      final usdzUrl = map['usdz_url'];

      _hideLoader();
      setState(() => _isLoading = false);

      if (usdzUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversion failed (No URL).')),
        );
        return;
      }

      await ARLauncher.launchARIosQuickLook(usdzUrl);
    } catch (e) {
      _hideLoader();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
                    widget.title ?? '',
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
        ],
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
