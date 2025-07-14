import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('glb_to_usdz');

  Future<void> convertModel() async {
    try {
      final String? usdzPath = await _channel.invokeMethod('convertDuckSample');
      if (usdzPath != null) {
        print("✅ USDZ file saved at: $usdzPath");
      } else {
        print("⚠️ Conversion returned null");
      }
    } catch (e) {
      print("❌ Conversion error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GLB to USDZ Converter')),
        body: Center(
          child: ElevatedButton(
            onPressed: convertModel,
            child: const Text('Convert Duck.gltf to USDZ'),
          ),
        ),
      ),
    );
  }
}
