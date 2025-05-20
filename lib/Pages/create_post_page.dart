import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _supabase = Supabase.instance.client;
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  String? _uploadedImageUrl;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      // Crop the image
      await _cropImage(image.path);
    }
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF123458),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: const Color(0xFF123458),
        ),
        IOSUiSettings(
          title: 'Crop Image',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  // Update the _createPost method to improve image URL handling
  Future<void> _createPost() async {
    final user = _supabase.auth.currentUser;
    print('Current user: ${user?.id}');
    print('Is authenticated: ${user != null}');

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image';
      });
      return;
    }

    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a title';
      });
      return;
    }

    if (_priceController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a price';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      if (user == null) {
        setState(() {
          _errorMessage = 'You need to be logged in to create a post';
          _isUploading = false;
        });
        return;
      }

      // Get user profile to get the name
      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .single();

      final userName =
          profileData['full_name'] ?? user.email?.split('@')[0] ?? 'Anonymous';

      // Create a unique file name with proper extension
      final fileExtension = path.extension(_selectedImage!.path).toLowerCase();
      final fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'posts/$fileName';

      print('Uploading to path: $filePath'); // Debug the file path

      // Read file as bytes
      final fileBytes = await _selectedImage!.readAsBytes();

      // Upload to Supabase Storage
      try {
        // Upload the file
        await _supabase.storage
            .from('images')
            .uploadBinary(filePath, fileBytes);

        // Get public URL after successful upload
        final imageUrl = _supabase.storage
            .from('images')
            .getPublicUrl(filePath);

        print('Generated image URL: $imageUrl'); // Debug log

        // Store the URL for display
        setState(() {
          _uploadedImageUrl = imageUrl;
        });

        // Create post in the posts table
        final postResponse =
            await _supabase.from('posts').insert({
              'user_id': user.id,
              'image_url': imageUrl,
              'description': _descriptionController.text.trim(),
              'user_name': userName,
              'created_at': DateTime.now().toIso8601String(),
              'title': _titleController.text.trim(),
              'price': _priceController.text.trim(),
            }).select();

        print('Post created with response: $postResponse');

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (storageError) {
        print('Storage error details: $storageError');
        throw Exception('Storage error: $storageError');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating post: ${e.toString()}';
        _isUploading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(color: Color(0xFF123458)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF123458)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Image selection
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child:
                      _selectedImage != null
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: InkWell(
                                  onTap: () => _cropImage(_selectedImage!.path),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.crop,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Crop',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to select an image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'You can crop the image after selecting',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              const SizedBox(height: 20),

              // Title field (styled like Vios)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Vios',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF123458),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Price field (styled like 1400 / day)
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 1400 / day',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF123458),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description field
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'e.g., Car for rent, good for outing, family use, airport transfer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF123458),
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // Create post button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123458),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Create Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              // Show uploaded image URL for debugging
              if (_uploadedImageUrl != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Uploaded Image URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _uploadedImageUrl!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
