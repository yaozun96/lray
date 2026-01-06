import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/services/user_service.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_user_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

class AccountSecurityScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const AccountSecurityScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // OAuth Settings
  List<String> _oauthMethods = [];
  Map<String, bool> _oauthBindings = {}; 
  Map<String, bool> _oauthLoading = {}; 

  // Account Settings
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadOAuthMethods();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getUserInfo();
      if (mounted) {
        setState(() {
          // Extract OAuth Bindings
          _oauthBindings.clear();
          if (user['auth_methods'] != null) {
            final authMethods = user['auth_methods'] as List;
            for (var m in authMethods) {
               if (m['auth_type'] != null) {
                 _oauthBindings[m['auth_type']] = true;
               }
            }
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOAuthMethods() async {
     try {
       final methods = await UserService.getOAuthMethods();
       if (mounted) {
         setState(() {
           _oauthMethods = methods;
         });
       }
     } catch (e) {
       print('Failed to load OAuth methods: $e');
     }
  }

  Future<void> _bindOAuth(String method) async {
    setState(() => _oauthLoading[method] = true);
    try {
      final url = await UserService.bindOAuth(method);
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('无法打开浏览器');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('绑定失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _oauthLoading[method] = false);
    }
  }

  Future<void> _unbindOAuth(String method) async {
    setState(() => _oauthLoading[method] = true);
    try {
      await UserService.unbindOAuth(method);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('解绑成功'), backgroundColor: AppTheme.success),
        );
        _loadData(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解绑失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _oauthLoading[method] = false);
    }
  }

  Future<void> _savePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入当前密码'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_passwordController.text.isEmpty) return;
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新密码长度至少8位'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      // Use XboardUserService instead
      await XboardUserService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码修改成功'), backgroundColor: AppTheme.success),
        );
        _oldPasswordController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.isEmbedded) {
          return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        backgroundColor: AppTheme.bgLightSecondary,
        appBar: AppBar(
          title: const Text('账户安全', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppTheme.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      if (widget.isEmbedded) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppTheme.bgLightSecondary,
        appBar: AppBar(
          title: const Text('账户安全', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppTheme.textPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEmbedded) ...[
               _buildSectionHeader('修改密码', '保障您的账户安全'),
               const SizedBox(height: 24),
            ],
            // Header with Back button for embedded mode
            if (widget.isEmbedded && widget.onBack != null)
               Padding(
                 padding: const EdgeInsets.only(bottom: 24),
                 child: IntrinsicHeight(
                   child: Row(
                     children: [
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: widget.onBack,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('修改密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                     ],
                   ),
                 ),
               ),

            _buildAccountSecurityCard(),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
       return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLightSecondary,
      appBar: AppBar(
        title: const Text('修改密码', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: content)),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAccountSecurityCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          TextField(
            controller: _oldPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_open, size: 18),
              hintText: '当前密码',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              hintText: '新密码(至少8位)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              hintText: '确认新密码',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSavingPassword ? null : _savePassword,
              icon: _isSavingPassword
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.key_rounded, size: 16),
              label: Text(_isSavingPassword ? '更新中...' : '更新密码'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          
          if (_oauthMethods.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            const Text('绑定第三方账户', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            for (var i = 0; i < _oauthMethods.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildOAuthTile(_oauthMethods[i]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOAuthTile(String method) {
    final isBound = _oauthBindings[method] == true;
    final isLoading = _oauthLoading[method] == true;
    final name = method.isNotEmpty ? method[0].toUpperCase() + method.substring(1) : method;
    String? logoUrl;
    if (method.toLowerCase() == 'google') {
      logoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png';
    } else if (method.toLowerCase() == 'telegram') {
      logoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Telegram_logo.svg/480px-Telegram_logo.svg.png';
    } else if (method.toLowerCase() == 'github') {
      logoUrl = 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: logoUrl != null
                    ? Image.network(logoUrl)
                    : Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: AppTheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isBound ? AppTheme.primary : AppTheme.textSecondary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isBound ? '已绑定' : '未绑定', 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w500,
                        color: isBound ? AppTheme.primary : AppTheme.textSecondary
                      )
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: isLoading ? null : () => isBound ? _unbindOAuth(method) : _bindOAuth(method),
              style: OutlinedButton.styleFrom(
                foregroundColor: isBound ? AppTheme.primary : AppTheme.primary,
                side: BorderSide(
                  color: (isBound ? AppTheme.primary : AppTheme.primary).withOpacity(isBound ? 0.8 : 0.3)
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isBound ? '解绑' : '绑定'),
            ),
          ),
        ],
      ),
    );
  }
}
