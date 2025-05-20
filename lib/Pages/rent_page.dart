import 'package:VehiCall/model/car.dart';
import 'package:VehiCall/model/car_tile.dart';
import 'package:VehiCall/model/fav.dart';
import 'package:VehiCall/model/post.dart';
import 'package:VehiCall/components/post_card.dart';
import 'package:VehiCall/Pages/create_post_page.dart';
import 'package:VehiCall/Pages/message_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:http/http.dart' as http;
import 'package:VehiCall/Pages/post_detail_page.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final _supabase = Supabase.instance.client;
  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  String? _errorMessage;
  bool _isDeletingPost = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _errorMessage = null;
    });

    try {
      // Fetch posts from Supabase
      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      print('Fetched ${response.length} posts from database');

      // Convert to Post objects
      final posts =
          response.map((post) {
            // Create post
            final postObj = Post.fromJson(post);

            // Log the image URL for debugging
            print('Post ID: ${postObj.id}, Image URL: ${postObj.imageUrl}');

            return postObj;
          }).toList();

      setState(() {
        _posts = List<Post>.from(posts);
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _errorMessage = 'Error loading posts: ${e.toString()}';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _deletePost(int postId) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
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

    if (shouldDelete != true) return;

    setState(() {
      _isDeletingPost = true;
    });

    try {
      // Delete the post from the database
      await _supabase.from('posts').delete().eq('id', postId);

      // Reload posts after deletion
      await _loadPosts();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingPost = false;
        });
      }
    }
  }

  void addCarToFav(Car car) {
    Provider.of<Fav>(context, listen: false).addItemToCart(car);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Successfully Added!'),
            content: Text('Check your Favorites'),
          ),
    );
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    // If post was created successfully, reload posts
    if (result == true) {
      _loadPosts();
    }
  }

  void _navigateToPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Fav>(
      builder:
          (context, value, child) => RefreshIndicator(
            onRefresh: _loadPosts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //search bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Here...',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Icon(Icons.search, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Create Post Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: ElevatedButton.icon(
                      onPressed: _navigateToCreatePost,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Create Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF123458),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Posts Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Posts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Posts list or loading indicator
                        _isLoadingPosts || _isDeletingPost
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : _errorMessage != null
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                            : _posts.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_album_outlined,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No posts yet. Be the first to share!',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : SizedBox(
                              height:
                                  MediaQuery.of(context).size.width *
                                  0.9, // Responsive height based on screen width
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  return PostCard(
                                    post: _posts[index],
                                    onDelete:
                                        () => _deletePost(_posts[index].id),
                                    onMessageTap: () {
                                      // Navigate to the message tab with recipient information
                                      setState(() {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => MessagePage(
                                                  recipientId:
                                                      _posts[index].userId,
                                                  recipientName:
                                                      _posts[index].userName,
                                                  postTitle:
                                                      _posts[index].title,
                                                ),
                                          ),
                                        );
                                      });
                                    },
                                    onTap:
                                        () => _navigateToPostDetail(
                                          _posts[index],
                                        ),
                                  );
                                },
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Available Cars',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height:
                        MediaQuery.of(context).size.width *
                        0.7, // Reduced and responsive height
                    child: ListView.builder(
                      itemCount: 4,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        Car car = value.getCarlist()[index];
                        return CarTile(car: car, onTap: () => addCarToFav(car));
                      },
                    ),
                  ),

                  const SizedBox(height: 10), // Reduced bottom padding
                ],
              ),
            ),
          ),
    );
  }
}
