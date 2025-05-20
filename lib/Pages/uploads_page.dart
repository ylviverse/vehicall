import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});

  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _userImages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserImages();
  }

  Future<void> _loadUserImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You need to be logged in to view your uploads';
          _isLoading = false;
        });
        return;
      }

      // Fetch user images from the database
      final response = await _supabase
          .from('user_images')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _userImages = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading images: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteImage(String imageUrl, int imageId) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Image'),
              content: const Text(
                'Are you sure you want to delete this image?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (shouldDelete != true) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Delete from database first
      await _supabase.from('user_images').delete().eq('id', imageId);

      // Extract the path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments
          .sublist(pathSegments.indexOf('object') + 1)
          .join('/');

      // Delete from storage
      await _supabase.storage.from('images').remove([storagePath]);

      // Refresh the list
      await _loadUserImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Uploads',
          style: TextStyle(color: Color(0xFF123458)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF123458)),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              )
              : _userImages.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.grey,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No uploads yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the + button on the home screen to upload images',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF123458),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _userImages.length,
                  itemBuilder: (context, index) {
                    final image = _userImages[index];
                    return _buildImageCard(image['image_url'], image['id']);
                  },
                ),
              ),
    );
  }

  Widget _buildImageCard(String imageUrl, int imageId) {
    return GestureDetector(
      onTap: () {
        // Show full-screen image view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _FullScreenImageView(imageUrl: imageUrl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteImage(imageUrl, imageId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
