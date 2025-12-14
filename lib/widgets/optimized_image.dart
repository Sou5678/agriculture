import 'dart:io';
import 'package:flutter/material.dart';
import '../core/utils/image_utils.dart';

class OptimizedImage extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showThumbnail;

  const OptimizedImage({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showThumbnail = false,
  }) : super(key: key);

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  Widget? _imageWidget;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      Widget imageWidget;
      
      if (widget.showThumbnail) {
        // Load thumbnail for better performance in lists
        final thumbnailBytes = await ImageUtils.getImageThumbnail(widget.imagePath);
        if (thumbnailBytes != null) {
          imageWidget = Image.memory(
            thumbnailBytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        } else {
          imageWidget = Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }
      } else {
        imageWidget = Image.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.width?.toInt(),
          cacheHeight: widget.height?.toInt(),
        );
      }

      if (mounted) {
        setState(() {
          _imageWidget = imageWidget;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_hasError) {
      child = Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 32,
        ),
      );
    } else {
      child = _imageWidget!;
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return child;
  }
}