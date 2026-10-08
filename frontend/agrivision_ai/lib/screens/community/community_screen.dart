import 'package:flutter/material.dart';
import '../../core/services/community_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/localization_service.dart';

const List<String> _kCropFilters = ['All Crops', 'Tomato', 'Rice', 'Potato', 'Wheat', 'Corn', 'Apple', 'Grape', 'Sugarcane', 'Citrus'];

/// Maps the English crop values used internally (Firestore filter values,
/// cropTag storage) to their display translation key.
String _cropLabelKey(String englishCrop) {
  switch (englishCrop) {
    case 'All Crops':
      return 'all_crops';
    case 'Tomato':
      return 'crop_tomato';
    case 'Rice':
      return 'crop_rice';
    case 'Potato':
      return 'crop_potato';
    case 'Wheat':
      return 'crop_wheat';
    case 'Corn':
      return 'crop_corn';
    case 'Apple':
      return 'crop_apple';
    case 'Grape':
      return 'crop_grape';
    case 'Sugarcane':
      return 'crop_sugarcane';
    case 'Citrus':
      return 'crop_citrus';
    default:
      return englishCrop; // unknown/legacy tag — show as-is
  }
}

/// Looks up [key] and substitutes `{name}`-style placeholders in [args].
String _trArgs(BuildContext context, String key, Map<String, String> args) {
  var text = context.tr(key);
  args.forEach((k, v) => text = text.replaceAll('{$k}', v));
  return text;
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  String _selectedFilter = 'All Crops';

  Future<void> _openCreatePostSheet() async {
    final textController = TextEditingController();
    String selectedCrop = _selectedFilter == 'All Crops' ? 'Tomato' : _selectedFilter;
    bool isPosting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('community_new_post'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCrop,
                    decoration: InputDecoration(labelText: context.tr('community_crop_label')),
                    items: _kCropFilters
                        .where((c) => c != 'All Crops')
                        .map((c) => DropdownMenuItem(value: c, child: Text(context.tr(_cropLabelKey(c)))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCrop = v ?? selectedCrop),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: context.tr('community_post_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isPosting
                        ? null
                        : () async {
                            if (textController.text.trim().isEmpty) return;
                            setSheetState(() => isPosting = true);
                            try {
                              await _communityService.createPost(
                                text: textController.text,
                                cropTag: selectedCrop,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            } catch (e) {
                              setSheetState(() => isPosting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_trArgs(context, 'community_failed_to_post', {'error': '$e'}))),
                                );
                              }
                            }
                          },
                    child: isPosting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(context.tr('community_post_button')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('community_filter_by_crop'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kCropFilters.map((crop) {
                  final selected = crop == _selectedFilter;
                  return ChoiceChip(
                    label: Text(context.tr(_cropLabelKey(crop))),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = crop);
                      Navigator.of(context).pop();
                    },
                    selectedColor: AppColors.greenMain,
                    labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await _confirmDelete(
      context.tr('community_delete_post_title'),
      context.tr('community_delete_post_message'),
    );
    if (!confirmed) return;
    try {
      await _communityService.deletePost(post.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_trArgs(context, 'community_failed_delete_post', {'error': '$e'}))),
        );
      }
    }
  }

  Future<void> _deleteComment(String postId, CommunityComment comment) async {
    final confirmed = await _confirmDelete(
      context.tr('community_delete_comment_title'),
      context.tr('community_delete_comment_message'),
    );
    if (!confirmed) return;
    try {
      await _communityService.deleteComment(postId, comment.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_trArgs(context, 'community_failed_delete_comment', {'error': '$e'}))),
        );
      }
    }
  }

  void _openCommentsSheet(CommunityPost post) {
    final textController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(context.tr('comments'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<CommunityComment>>(
                        stream: _communityService.streamComments(post.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text(_trArgs(context, 'something_went_wrong', {'error': '${snapshot.error}'})));
                          }
                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                context.tr('community_no_comments'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _CommentTile(
                              comment: comments[index],
                              currentUid: _communityService.currentUid,
                              onDelete: () => _deleteComment(post.id, comments[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(hintText: context.tr('community_write_reply_hint')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: isSending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Icon(Icons.send),
                          onPressed: isSending
                              ? null
                              : () async {
                                  final text = textController.text;
                                  if (text.trim().isEmpty) return;
                                  setSheetState(() => isSending = true);
                                  try {
                                    await _communityService.addComment(post.id, text);
                                    textController.clear();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(_trArgs(context, 'community_failed_reply', {'error': '$e'}))),
                                      );
                                    }
                                  } finally {
                                    setSheetState(() => isSending = false);
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('community')),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: _openFilterSheet),
          IconButton(icon: const Icon(Icons.add), onPressed: _openCreatePostSheet),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kCropFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final crop = _kCropFilters[index];
                  final selected = crop == _selectedFilter;
                  return ChoiceChip(
                    label: Text(context.tr(_cropLabelKey(crop))),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = crop),
                    selectedColor: AppColors.greenMain,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _communityService.streamPosts(cropFilter: _selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      _trArgs(context, 'something_went_wrong', {'error': '${snapshot.error}'}),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _trArgs(context, 'community_no_posts_for', {'crop': context.tr(_cropLabelKey(_selectedFilter))}),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PostCard(
                    post: posts[index],
                    currentUid: _communityService.currentUid,
                    onLike: () => _communityService.toggleLike(posts[index].id),
                    onComment: () => _openCommentsSheet(posts[index]),
                    onDelete: () => _deletePost(posts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String? currentUid;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;
  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = post.authorName.trim().isNotEmpty
        ? post.authorName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'F';
    final liked = post.isLikedBy(currentUid);
    final isOwner = currentUid != null && currentUid == post.uid;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.greenAccent,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(post.timeAgo, style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5)),
                  ],
                ),
              ),
              // post.cropTag is Firestore-stored data — intentionally left
              // untranslated per LocalizationService's scope (see its doc comment).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.greenLightBg, borderRadius: BorderRadius.circular(8)),
                child: Text(post.cropTag, style: const TextStyle(color: AppColors.greenMid, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text(context.tr('delete')),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.text, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10.5, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: liked ? AppColors.red : theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9.5,
                        color: liked ? AppColors.red : null,
                        fontWeight: liked ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              InkWell(
                onTap: onComment,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Icon(Icons.mode_comment_outlined, size: 14, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text('${post.replyCount} ${context.tr('community_replies_suffix')}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final String? currentUid;
  final VoidCallback onDelete;
  const _CommentTile({required this.comment, required this.currentUid, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = comment.authorName.trim().isNotEmpty
        ? comment.authorName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'F';
    final isOwner = currentUid != null && currentUid == comment.uid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.greenAccent,
          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(comment.authorName, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(comment.timeAgo, style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5)),
                ],
              ),
              const SizedBox(height: 2),
              Text(comment.text, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10.5, height: 1.4)),
            ],
          ),
        ),
        if (isOwner)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline, size: 15, color: AppColors.red),
            ),
          ),
      ],
    );
  }
}