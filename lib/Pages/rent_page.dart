import 'package:VehiCall/model/post.dart';
import 'package:VehiCall/components/post_card.dart';
import 'package:VehiCall/Pages/create_post_page.dart';
import 'package:VehiCall/Pages/message_page.dart';
import 'package:VehiCall/Pages/post_detail_page.dart';
import 'package:VehiCall/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoadingPosts = true;
  bool _isDeletingPost = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      // Check if Supabase is initialized
      final client = _supabase;
      if (client == null) {
        throw Exception('Database connection not available');
      }

      final response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      final posts =
          response
              .map((post) {
                try {
                  return Post.fromJson(post);
                } catch (e) {
                  print('Error parsing post: $e');
                  return null;
                }
              })
              .where((post) => post != null)
              .cast<Post>()
              .toList();

      setState(() {
        _posts = posts;
        _filteredPosts = List<Post>.from(posts);
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _posts = [];
          _filteredPosts = [];
          _isLoadingPosts = false;
        });

        // Only show error snackbar for network/server errors, not for empty results
        if (e.toString().contains('network') ||
            e.toString().contains('server') ||
            e.toString().contains('connection')) {
          ErrorHandler.showErrorSnackBar(
            context,
            'Error loading posts: ${e.toString()}',
          );
        }
      }
    }
  }

  void _filterPosts() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = List<Post>.from(_posts);
      } else {
        _filteredPosts =
            _posts.where((post) {
              final title = post.title?.toLowerCase() ?? '';
              // FIX: Handle null description safely
              final description = post.description?.toLowerCase() ?? '';
              final userName = post.userName.toLowerCase();
              final price = post.price?.toLowerCase() ?? '';

              return title.contains(query) ||
                  description.contains(query) ||
                  userName.contains(query) ||
                  price.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _deletePost(int postId) async {
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

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isDeletingPost = true;
    });

    try {
      await _supabase.from('posts').delete().eq('id', postId);
      await _loadPosts();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Post deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Error deleting post: ${e.toString()}',
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

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result == true && mounted) {
      _loadPosts();
    }
  }

  void _navigateToPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
    );
  }

  void _navigateToMessage(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MessagePage(
              recipientId: post.userId,
              recipientName: post.userName,
              postTitle: post.title,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vehicles, users, or prices...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF123458),
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF123458),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Create Post Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToCreatePost,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Create New Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF123458),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Posts Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Vehicles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Color(0xFF123458),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _filteredPosts.length == 1
                                ? '${_filteredPosts.length} vehicle available'
                                : '${_filteredPosts.length} vehicles available',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          child: const Text(
                            'Clear Search',
                            style: TextStyle(
                              color: Color(0xFF123458),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Posts content
          if (_isLoadingPosts || _isDeletingPost)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFF123458)),
                ),
              ),
            )
          else if (_filteredPosts.isEmpty && _searchController.text.isNotEmpty)
            SliverToBoxAdapter(child: _buildEmptySearchResults())
          else if (_filteredPosts.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _filteredPosts.length) return null;

                final post = _filteredPosts[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 25,
                    right: 25,
                    bottom: 16,
                  ),
                  child: PostCard(
                    post: post,
                    onDelete: () => _deletePost(post.id),
                    onTap: () => _navigateToPostDetail(post),
                  ),
                );
              }, childCount: _filteredPosts.length),
            ),

          // Extra space for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123458),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your vehicle for rent!',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Create First Post'),
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
      ),
    );
  }
}
