import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_clash/soravpn_ui/models/ticket.dart';
import 'package:fl_clash/soravpn_ui/models/ticket_message.dart';
import 'package:fl_clash/soravpn_ui/services/ticket_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TicketDetailDialog extends StatefulWidget {
  final int ticketId;

  const TicketDetailDialog({super.key, required this.ticketId});

  @override
  State<TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<TicketDetailDialog> {
  Ticket? _ticket;
  List<TicketMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await TicketService.getTicketDetail(widget.ticketId);
      setState(() {
        _ticket = detail['ticket'] as Ticket;
        _messages = detail['messages'] as List<TicketMessage>;
        
        if (_ticket != null && _ticket!.description.isNotEmpty) {
           final initialMessage = TicketMessage(
             id: 0,
             content: _ticket!.description,
             userId: _ticket!.userId,
             ticketId: _ticket!.id,
             isAdmin: false, 
             type: 1,
             createdAt: _ticket!.createdAt,
           );
           if (_messages.isEmpty || _messages.first.content != _ticket!.description) {
              _messages.insert(0, initialMessage);
           }
        }

        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    try {
      // 1. Send Image if selected
      if (_selectedImage != null) {
        await _processAndSendImage();
        setState(() => _selectedImage = null);
      }

      // 2. Send Text if exists
      if (content.isNotEmpty) {
        await _performReply(content, type: 1);
        _replyController.clear();
      }

      await _loadDetail();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if(mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _processAndSendImage() async {
      final bytes = await _selectedImage!.readAsBytes();
      
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
        _selectedImage!.absolute.path,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: 85, 
        format: CompressFormat.jpeg, 
      );

      if (compressedBytes == null) throw Exception('Compression failed');

      final imageUrl = await _uploadToImgBB(compressedBytes);
      await TicketService.replyTicket(widget.ticketId, imageUrl, type: 2);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<String> _uploadToImgBB(List<int> bytes) async {
      const apiKey = '65a3d42daa7f2a8458754344fa591cfa';
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = apiKey
        ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) return json['data']['url'];
      }
      throw Exception('Upload failed');
  }

  Future<void> _performReply(String content, {required int type}) async {
    setState(() => _isSending = true);
    try {
      await TicketService.replyTicket(widget.ticketId, content, type: type);
      if (type == 1) _replyController.clear();
      await _loadDetail();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if(mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Center(
      child: Padding(
        padding: isMobile 
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: size.height * 0.85,
        ),
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
             clipBehavior: Clip.hardEdge,
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
             ),
             child: Column(
               children: [
                 _buildHeader(),
                 Expanded(
                   child: _isLoading
                       ? const Center(child: CircularProgressIndicator())
                       : _errorMessage != null
                           ? Center(child: Text(_errorMessage!))
                           : Column(
                               children: [
                                 Expanded(
                                   child: ListView.builder(
                                     controller: _scrollController,
                                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                     itemCount: _messages.length,
                                     itemBuilder: (context, index) {
                                       final msg = _messages[index];
                                       final isLast = index == _messages.length - 1;
                                       return Padding(
                                         padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                         child: _buildMessageRow(msg),
                                       );
                                     },
                                   ),
                                 ),
                                 _buildInputArea(),
                               ],
                             ),
                 ),
               ],
             ),
          ),
        ),
      ),
    ));
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
          children: [
             IconButton(
               onPressed: () => Navigator.pop(context),
               icon: const Icon(Icons.arrow_back),
               splashRadius: 24,
             ),
             const SizedBox(width: 8),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                        Text(
                         _ticket?.title ?? '工单详情',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         overflow: TextOverflow.ellipsis,
                        ),
                        if (_ticket != null) ...[
                          const SizedBox(width: 8),
                          _buildStatusTag(),
                        ]
                     ],
                   ),
                   if (_ticket != null)
                    Text(
                      '#${_ticket!.id} · ${_formatDate(_ticket!.createdAt)}',
                      style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
                    ),
                 ],
               ),
             ),
             if (_ticket?.status != 2)
                TextButton(
                  onPressed: _closeTicket,
                  child: const Text('关闭工单', style: TextStyle(color: AppTheme.destructive)),
                ),
          ],
        ),
    );
  }
  
  Future<void> _closeTicket() async {
      try {
        await TicketService.closeTicket(widget.ticketId);
        _loadDetail();
      } catch (e) {/*...*/}
  }

  Widget _buildStatusTag() {
    var text = _ticket!.statusText;
    var color = _ticket!.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMessageRow(TicketMessage message) {
    final isMe = !message.isAdmin;
    
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: const Icon(Icons.support_agent, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primary : AppTheme.muted,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                child: message.isImage 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(message.content, width: 200, fit: BoxFit.cover),
                    )
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : AppTheme.foreground,
                          height: 1.5,
                        ),
                        a: TextStyle(
                          color: isMe ? Colors.white : AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        // Handle link tap if needed
                      },
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(message.createdAt).substring(11, 16), // HH:mm
                style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.muted,
            child: const Icon(Icons.person, size: 18, color: AppTheme.mutedForeground),
          ),
        ],
      ],
    );
  }

  Widget _buildInputArea() {
    if (_ticket?.status == 2) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: AppTheme.muted.withOpacity(0.3),
        width: double.infinity,
        child: const Text('此工单已关闭', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedForeground)),
      );
    }

    if (_ticket?.status == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: AppTheme.muted.withOpacity(0.3),
        width: double.infinity,
        child: const Text(
          '请等待客服回复后再次发送消息',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _isSending ? null : _pickImage,
                  icon: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: _selectedImage != null ? AppTheme.primary : AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.muted,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: TextField(
                      controller: _replyController,
                      maxLines: 5,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendReply,
                  icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send_rounded),
                  color: AppTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
