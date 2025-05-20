class Post {
  final int id;
  final String userId;
  final String imageUrl;
  final String description;
  final String userName;
  final DateTime createdAt;
  final String? title; // Added title field
  final String? price; // Added price field
  final String? message; // Added message field

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.description,
    required this.userName,
    required this.createdAt,
    this.title,
    this.price,
    this.message,
  });

  // Update the Post.fromJson factory method to handle URL issues better
  factory Post.fromJson(Map<String, dynamic> json) {
    // Get the image URL directly from the JSON
    String imageUrl = json['image_url'] ?? '';

    // Log the URL for debugging
    print('Post from JSON - Raw Image URL: $imageUrl');

    // Make sure the URL is properly formatted
    if (imageUrl.isNotEmpty) {
      // Fix common URL issues
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://$imageUrl';
      }

      // Remove any double slashes (except after protocol)
      imageUrl = imageUrl
          .replaceAll('://', '::TEMP::')
          .replaceAll('//', '/')
          .replaceAll('::TEMP::', '://');

      print('Processed URL: $imageUrl');
    }

    return Post(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: imageUrl,
      description: json['description'] ?? '',
      userName: json['user_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at']),
      title: json['title'],
      price: json['price'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'description': description,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'price': price,
      'message': message,
    };
  }
}
