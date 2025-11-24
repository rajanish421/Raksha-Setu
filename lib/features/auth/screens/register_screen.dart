import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../custom_widgets/primary_button.dart';
import '../../../utils/route_names.dart';

import '../../upload/cloudinary_upload_service.dart';
import '../../upload/upload_service.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceNoController = TextEditingController();
  final _rankController = TextEditingController();
  final _unitController = TextEditingController();
  final _referenceServiceController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'soldier';
  File? _selfieFile;
  File? _documentFile;

  bool _obscurePassword = true;
  bool _isLoading = false;

  final UploadService _uploadService = CloudinaryUploadService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _serviceNoController.dispose();
    _rankController.dispose();
    _unitController.dispose();
    _referenceServiceController.dispose();
    _relationshipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() => _selfieFile = File(picked.path));
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      type: FileType.custom,
    );
    if (result != null) {
      setState(() => _documentFile = File(result.files.first.path!));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selfieFile == null) {
      _showMsg("Please capture a selfie.");
      return;
    }
    if (_documentFile == null) {
      _showMsg("Please upload your ID proof.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Upload files
      final selfieUrl = await _uploadService.uploadSelfie(
        file: _selfieFile!,
        userId: _phoneController.text.trim(),
      );

      final docUrl = await _uploadService.uploadDocument(
        file: _documentFile!,
        userId: _phoneController.text.trim(),
      );

      // Call AuthService
      await AuthService.instance.registerUser(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        serviceNumber: _role == 'family' ? null : _serviceNoController.text.trim(),
        rank: _role == 'family' ? null : _rankController.text.trim(),
        unit: _role == 'family' ? null : _unitController.text.trim(),
        referenceServiceNumber:
        _role == 'family' ? _referenceServiceController.text.trim() : null,
        relationship: _role == 'family' ? _relationshipController.text.trim() : null,
        password: _passwordController.text.trim(),
        selfieUrl: selfieUrl,
        documentUrl: docUrl,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.pendingApproval,
            (route) => false,
      );
    } catch (e) {
      _showMsg(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create an account", style: text.headlineSmall),
                const SizedBox(height: 16),

                // role selector
                Row(
                  children: [
                    _roleChip("Soldier", "soldier"),
                    const SizedBox(width: 8),
                    _roleChip("Family", "family"),
                    const SizedBox(width: 8),
                    _roleChip("Veteran", "veteran"),
                  ],
                ),
                const SizedBox(height: 24),

                _textField(_fullNameController, "Full Name"),
                const SizedBox(height: 12),
                _textField(_phoneController, "Phone Number", keyboard: TextInputType.phone),

                if (_role != 'family') ...[
                  const SizedBox(height: 12),
                  _textField(_serviceNoController, "Service Number"),
                  const SizedBox(height: 12),
                  _textField(_rankController, "Rank"),
                  const SizedBox(height: 12),
                  _textField(_unitController, "Unit"),
                ],

                if (_role == 'family') ...[
                  const SizedBox(height: 12),
                  _textField(_referenceServiceController, "Reference Service Number"),
                  const SizedBox(height: 12),
                  _textField(_relationshipController, "Relationship (spouse/father etc.)"),
                ],

                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text("Selfie (Camera)", style: text.bodyLarge),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickSelfie,
                  child: _fileContainer(_selfieFile, "Capture Selfie"),
                ),

                const SizedBox(height: 14),
                Text("ID Proof (Image or PDF)", style: text.bodyLarge),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDocument,
                  child: _fileContainer(_documentFile, "Upload ID Proof"),
                ),

                const SizedBox(height: 30),
                PrimaryButton(
                  label: "Submit for Approval",
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, String value) {
    final bool selected = _role == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _role = value),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.surface,
    );
  }

  Widget _textField(
      TextEditingController controller,
      String label, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
    );
  }

  Widget _fileContainer(File? file, String label) {
    final text = Theme.of(context).textTheme;
    return Container(
      height: 60,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      child: Text(
        file != null ? file.path.split('/').last : label,
        style: text.bodyMedium,
      ),
    );
  }
}
