import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roomController = TextEditingController();
  final _adminCodeController = TextEditingController();
  String _selectedBlock = 'Block A';
  String _selectedRole = 'student';
  String _selectedCategory = 'Electricity';
  bool _obscurePassword = true;

  final List<String> _blocks = [
    'Block A', 'Block B', 'Block C', 'Block D', 'Block E'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roomController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    
    String finalRole = 'student';
    final secretCode = _adminCodeController.text.trim();

    // 🛡️ ROLE VALIDATION LOGIC 🛡️
    if (secretCode == 'ADMIN123') {
      finalRole = 'admin';
    } else if (secretCode == 'STAFF123') {
      finalRole = 'staff';
    } else {
      // 🛑 BLOCK IF NO SECRET PROVIDED FOR STAFF/ADMIN ROLES
      if (_selectedRole == 'staff') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need the Staff Secret Code to register as staff!'),
            backgroundColor: Color(0xFFEF4444), // Scarlet red 
          ),
        );
        return; // Stop registration
      }
      finalRole = 'student';
    }

    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      roomNumber: _roomController.text.trim(),
      hostelBlock: _selectedBlock,
      role: finalRole,
      staffCategory: finalRole == 'staff' ? _selectedCategory : null,
    );
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join to start tracking hostel issues',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- HIGH VISIBILITY ROLE SELECTION ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACCOUNT TYPE',
                            style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              labelText: 'I am a...',
                              prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF6C63FF)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'student', child: Text('Student')),
                              DropdownMenuItem(value: 'staff', child: Text('Staff / Maintenance')),
                            ],
                            onChanged: (val) => setState(() => _selectedRole = val!),
                          ),
                          if (_selectedRole == 'staff') ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                labelText: 'Specialization Category',
                                prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF6C63FF)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Electricity', child: Text('Electricity')),
                                DropdownMenuItem(value: 'Water Problem', child: Text('Water Problem')),
                                DropdownMenuItem(value: 'Mess Food', child: Text('Mess Food')),
                                DropdownMenuItem(value: 'Room Maintenance', child: Text('Room Maintenance')),
                                DropdownMenuItem(value: 'Cleanliness', child: Text('Cleanliness')),
                                DropdownMenuItem(value: 'Internet / WiFi', child: Text('Internet / WiFi')),
                                DropdownMenuItem(value: 'Security', child: Text('Security')),
                              ],
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedRole == 'student') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _roomController,
                              label: 'Room No.',
                              icon: Icons.meeting_room_outlined,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBlock,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                              decoration: const InputDecoration(
                                labelText: 'Block',
                                prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF9CA3AF)),
                              ),
                              items: _blocks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                              onChanged: (val) => setState(() => _selectedBlock = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    _buildField(
                      controller: _adminCodeController,
                      label: 'Secret Code (Required for Admin/Staff)',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 32),

                    if (auth.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Color(0xFF6B7280))),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Sign In',
                            style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
      ),
      validator: validator,
    );
  }
}
