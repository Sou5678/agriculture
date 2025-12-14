import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../services/ml_service.dart';

class PerformanceOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    Key? key,
    required this.child,
    this.showOverlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 100,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Consumer<DetectionProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Performance Stats',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ML Cache: ${MLService.getCacheSize()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'History: ${provider.totalDetections}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Initialized: ${provider.isInitialized}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    if (provider.error != null)
                      Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}