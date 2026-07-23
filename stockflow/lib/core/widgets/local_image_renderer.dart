import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LocalImageRenderer extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const LocalImageRenderer({
    super.key, 
    required this.imagePath, 
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, image paths provided by image_picker are usually blob URIs
      return Image.network(
        imagePath, 
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
      );
    } else {
      // On native, we safely load from the file system
      return Image.file(
        File(imagePath), 
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
      );
    }
  }
}
