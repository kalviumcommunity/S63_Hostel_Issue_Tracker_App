import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
  String _selectedPriority = 'medium';
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final _priorities = [
    {'value': 'low', 'label': 'Low', 'color': Color(0xFF4CAF94)},
    {'value': 'medium', 'label': 'Medium', 'color': Color(0xFFFFB347)},
    {'value': 'high', 'label': 'High', 'color': Color(0xFFFF6B6B)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final issueProvider = context.read<IssueProvider>();

    final issue = IssueModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      status: 'open',
      reportedBy: auth.userModel?.uid ?? '',
      reporterName: auth.userModel?.name ?? '',
      roomNumber: auth.userModel?.roomNumber ?? '',
      hostelBlock: auth.userModel?.hostelBlock ?? '',
      imageUrls: [], // TODO: Upload images to Firebase Storage first
      createdAt: DateTime.now(),
    );

    final success = await issueProvider.createIssue(issue);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue reported successfully!'),
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
        title: const Text(
          'Report an Issue',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
              _buildLabel('Issue Title'),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Leaking tap in bathroom',
                  prefixIcon:
                      Icon(Icons.title, color: Color(0xFF6C63FF)),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Description'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  prefixIcon:
                      Icon(Icons.description_outlined, color: Color(0xFF6C63FF)),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined,
                      color: Color(0xFF6C63FF)),
                ),
                items: issueCategories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              _buildLabel('Priority'),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPriority = p['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (p['color'] as Color).withOpacity(0.2)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? p['color'] as Color
                                : const Color(0xFF2A2A3E),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              color: isSelected
                                  ? p['color'] as Color
                                  : const Color(0xFF9E9EBF),
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? p['color'] as Color
                                    : const Color(0xFF9E9EBF),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _buildLabel('Photos (Optional)'),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2A2A3E),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: Color(0xFF6C63FF), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImages.isEmpty
                            ? 'Tap to add photos'
                            : '${_selectedImages.length} photo(s) selected',
                        style: const TextStyle(color: Color(0xFF9E9EBF)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Issue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
