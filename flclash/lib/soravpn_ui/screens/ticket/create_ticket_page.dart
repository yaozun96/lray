import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fl_clash/soravpn_ui/services/ticket_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}



class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _selectedLevel = 1; // Default to Medium (1)
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String content = _contentController.text.trim();
      
      // Handle Image Upload if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImage(_selectedImage!);
        content += '\n\n![]($imageUrl)';
      }

      await TicketService.createTicket(
        _titleController.text.trim(),
        content,
        _selectedLevel,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工单创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('创建失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _uploadImage(File file) async {
    final bytes = await file.readAsBytes();
    
    // Compression Logic
    var decodedImage = await decodeImageFromList(bytes);
    int width = decodedImage.width;
    int height = decodedImage.height;
    int targetWidth = width;
    int targetHeight = height;

    if (width > 1920 || height > 1920) {
      if (width > height) {
        targetWidth = 1920;
        targetHeight = (height * 1920 / width).round();
      } else {
        targetHeight = 1920;
        targetWidth = (width * 1920 / height).round();
      }
    }

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: 85, 
      format: CompressFormat.jpeg, 
    );
     
    if (compressedBytes == null) throw Exception('Compression failed');

    // ImgBB Upload
    const apiKey = '65a3d42daa7f2a8458754344fa591cfa';
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['key'] = apiKey
      ..files.add(http.MultipartFile.fromBytes('image', compressedBytes, filename: 'upload.jpg'));
      
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) return json['data']['url'];
    }
    throw Exception('Image upload failed');
  }

  Future<void> _pickImage() async {
     try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine specific height or let it act natural. Dialogs should be flexible.
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('标题'),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.muted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: '请输入工单标题',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return '请输入标题';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildLabel('工单级别'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.muted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedLevel,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 0, child: Text('低')),
                                    DropdownMenuItem(value: 1, child: Text('中')),
                                    DropdownMenuItem(value: 2, child: Text('高')),
                                  ],
                                  onChanged: (val) => setState(() => _selectedLevel = val ?? 1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
    
                            _buildLabel('问题描述'),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.muted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  hintText: '请详细描述您遇到的问题...',
                                  contentPadding: EdgeInsets.all(16),
                                  border: InputBorder.none,
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return '请输入问题描述';
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Image Upload Preview
                            if (_selectedImage != null)
                              Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 120, // Reduced height
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImage!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                                  label: const Text('添加截图'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: AppTheme.primary,
                                    backgroundColor: AppTheme.primary.withOpacity(0.05),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
    
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 44, // Reduced height
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('提交工单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '创建工单',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLightPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: AppTheme.textLightSecondary),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildBackButton as it is replaced by Close button

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textLightPrimary,
        ),
      ),
    );
  }
}
