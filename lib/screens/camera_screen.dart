
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      _showPermissionDialog();
      return;
    }

    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to capture plant images for disease detection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      
      if (mounted) {
        context.go('/result', extra: {
          'imageUri': image.path,
        });
      }
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to take picture. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        context.go('/result', extra: {
          'imageUri': image.path,
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
          ),
        );
      }
    }
  }

  void _flipCamera() {
    if (widget.cameras.length < 2) return;

    final currentCamera = _controller!.description;
    final newCamera = widget.cameras.firstWhere(
      (camera) => camera != currentCamera,
      orElse: () => widget.cameras[0],
    );

    _controller?.dispose();
    _controller = CameraController(newCamera, ResolutionPreset.high);
    
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Plant Image'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: !_isInitialized
          ? _buildLoadingView()
          : AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 600),
              child: FadeInAnimation(
                child: Stack(
                  children: [
                    // Camera Preview
                    SizedBox.expand(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: CameraPreview(_controller!),
                      ),
                    ),
                    
                    // Gradient Overlays
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content Overlay
                    SafeArea(
                      child: Column(
                        children: [
                          // Top Instructions
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: Container(
                                  margin: EdgeInsets.all(isTablet ? 32 : 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.center_focus_strong,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Capture Tips',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        '• Position the plant leaf in the center\n• Ensure good lighting\n• Keep the camera steady\n• Fill the frame with the leaf',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Focus Area
                          Expanded(
                            child: Center(
                              child: AnimationConfiguration.staggeredList(
                                position: 2,
                                duration: const Duration(milliseconds: 800),
                                child: ScaleAnimation(
                                  child: Container(
                                    width: screenSize.width * (isTablet ? 0.6 : 0.8),
                                    height: screenSize.width * (isTablet ? 0.6 : 0.8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF4CAF50),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Corner indicators
                                        ...List.generate(4, (index) {
                                          final positions = [
                                            {'top': 8.0, 'left': 8.0}, // Top-left
                                            {'top': 8.0, 'right': 8.0}, // Top-right
                                            {'bottom': 8.0, 'left': 8.0}, // Bottom-left
                                            {'bottom': 8.0, 'right': 8.0}, // Bottom-right
                                          ];
                                          final pos = positions[index];
                                          
                                          return Positioned(
                                            top: pos['top'] as double?,
                                            left: pos['left'] as double?,
                                            right: pos['right'] as double?,
                                            bottom: pos['bottom'] as double?,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          );
                                        }),
                                        
                                        // Center crosshair
                                        Center(
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFF4CAF50),
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.add,
                                                color: Color(0xFF4CAF50),
                                                size: 16,
                                              ),
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
                          
                          // Bottom Controls
                          AnimationConfiguration.staggeredList(
                            position: 3,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 60 : 40,
                                    vertical: isTablet ? 50 : 40,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Gallery Button
                                      _buildControlButton(
                                        icon: Icons.photo_library,
                                        onPressed: _pickImage,
                                        tooltip: 'Choose from Gallery',
                                      ),
                                      
                                      // Capture Button
                                      GestureDetector(
                                        onTap: _isLoading ? null : () {
                                          HapticFeedback.mediumImpact();
                                          _takePicture();
                                        },
                                        child: Container(
                                          width: isTablet ? 90 : 80,
                                          height: isTablet ? 90 : 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF4CAF50),
                                              width: 4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: _isLoading
                                              ? const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(0xFF4CAF50),
                                                    strokeWidth: 3,
                                                  ),
                                                )
                                              : Container(
                                                  margin: const EdgeInsets.all(12),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF4CAF50),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      
                                      // Flip Camera Button
                                      _buildControlButton(
                                        icon: Icons.flip_camera_android,
                                        onPressed: widget.cameras.length > 1 ? _flipCamera : null,
                                        tooltip: 'Flip Camera',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF4CAF50),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 800),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Initializing Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we prepare the camera for you',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed != null ? () {
              HapticFeedback.lightImpact();
              onPressed();
            } : null,
            borderRadius: BorderRadius.circular(28),
            child: Icon(
              icon,
              color: onPressed != null ? Colors.black87 : Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}