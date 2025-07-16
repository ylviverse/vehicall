import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({super.key, required this.child, this.fallback});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  Object? error;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return widget.fallback ?? _buildErrorWidget();
    }

    return widget.child;
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode ? error.toString() : 'Please restart the app',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasError = false;
                    error = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    if (hasError) {
      setState(() {
        hasError = false;
        error = null;
      });
    }
  }
}
