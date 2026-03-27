import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = issueCategories.first;
  XFile? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final issueProvider = context.read<IssueProvider>();
    final user = auth.userModel!;

    // Upload photo if one was picked
    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await issueProvider.uploadImage(
        File(_pickedImage!.path),
        user.uid,
      );
    }

    final issue = IssueModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      status: statusPending,
      createdBy: user.uid,
      createdByName: user.name,
      location: '${user.hostelBlock} · Room ${user.roomNumber}',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    final success = await issueProvider.createIssue(issue);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Issue reported successfully!'),
          backgroundColor: Color(0xFF4CAF94),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chips
              _label('Category'),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: issueCategories.length,
                  itemBuilder: (context, i) {
                    final cat = issueCategories[i];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF2A2A3E),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9E9EBF),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Title
              _label('Issue Title'),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Food was stale in mess today',
                  prefixIcon:
                      Icon(Icons.title, color: Color(0xFF6C63FF)),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 16),

              // Description
              _label('Description'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  prefixIcon: Icon(Icons.description_outlined,
                      color: Color(0xFF6C63FF)),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please describe the issue' : null,
              ),

              const SizedBox(height: 20),

              // Photo upload
              _label('Photo Evidence (Optional)'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A3E)),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _pickedImage = null),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: Color(0xFF6C63FF), size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(color: Color(0xFF9E9EBF)),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Issue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
      );
}
