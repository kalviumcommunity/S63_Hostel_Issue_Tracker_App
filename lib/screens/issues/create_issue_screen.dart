import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../services/sla_service.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Mess Food';
  File? _imageFile;
  bool _isSaving = false;

  final List<String> _categories = [
    'Mess Food',
    'Water Problem',
    'Electricity',
    'Room Maintenance',
    'Cleanliness',
    'Internet / WiFi',
    'Security',
    'Other'
  ];

  String _selectedPriority = SLAService.priorityMedium;
  final List<String> _priorities = [
    SLAService.priorityHigh,
    SLAService.priorityMedium,
    SLAService.priorityLow,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final issueProvider = context.read<IssueProvider>();
    final user = auth.userModel;

    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await issueProvider.uploadImage(_imageFile!, user.uid);
    }

    final createdAt = DateTime.now();
    final deadline = SLAService.calculateDeadline(createdAt, _selectedPriority);

    final newIssue = IssueModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      imageUrl: imageUrl,
      location: '${user.hostelBlock} - Room ${user.roomNumber}',
      status: statusPending,
      createdBy: user.uid,
      createdByName: user.name,
      createdAt: createdAt,
      updatedAt: createdAt,
      priority: _selectedPriority,
      deadline: deadline,
      isDelayed: false,
    );

    final success = await issueProvider.createIssue(newIssue);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        if (context.canPop()) context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(issueProvider.error ?? 'Failed to submit issue'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _priorities.map((priority) {
          final isSelected = _selectedPriority == priority;
          Color pColor;
          if (priority == SLAService.priorityHigh) pColor = const Color(0xFFEF4444);
          else if (priority == SLAService.priorityMedium) pColor = const Color(0xFFF59E0B);
          else pColor = const Color(0xFF10B981);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? pColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? pColor : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: pColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Text(
                priority,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Report Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Title Section ---
                    const Text('What is the issue?',
                        style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Leaking tap in bathroom',
                        prefixIcon: Icon(Icons.title_rounded, color: Color(0xFF9CA3AF)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 28),

                    // --- Category Section ---
                    const Text('Category',
                        style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),
                    const SizedBox(height: 28),

                    // --- Priority Section ---
                    const Text('Priority (SLA)',
                        style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildPriorityChips(),
                    const SizedBox(height: 28),

                    // --- Description Section ---
                    const Text('Description',
                        style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'Please describe the problem in detail...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 76),
                          child: Icon(Icons.description_outlined, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please provide a description' : null,
                    ),
                    const SizedBox(height: 28),

                    // --- Photo Section ---
                    const Text('Attach Photo (Optional)',
                        style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    if (_imageFile != null)
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              image: DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF111827).withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              onPressed: () => setState(() => _imageFile = null),
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF111827).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickImage(ImageSource.camera),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.camera_alt_rounded, size: 36, color: Color(0xFF6C63FF)),
                                    SizedBox(height: 8),
                                    Text('Take Photo',
                                        style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickImage(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.photo_library_rounded, size: 36, color: Color(0xFF3ECFCF)),
                                    SizedBox(height: 8),
                                    Text('Upload Photo',
                                        style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    const SizedBox(height: 48),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _submitIssue,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Report', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
