import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/main_layout.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth/oauth_buttons.dart';
import 'dart:async';

class RegisterForm extends StatefulWidget {
  final VoidCallback onLogin;

  const RegisterForm({
    super.key,
    required this.onLogin,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController(); // For domain whitelist mode
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  int _countdown = 0;
  Timer? _timer;
  
  // Domain Whitelist Logic
  String? _selectedDomain;
  List<String> _domainSuffixList = [];
  bool _enableDomainSuffix = false;
  bool _enableVerify = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    setState(() {
      _enableVerify = ConfigService.enableRegisterVerify || ConfigService.enableEmailVerify;
      _enableDomainSuffix = ConfigService.enableDomainSuffix;
      _domainSuffixList = ConfigService.domainSuffixList;
      
      if (_enableDomainSuffix && _domainSuffixList.isNotEmpty) {
        _selectedDomain = _domainSuffixList.first;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    _inviteCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Helper to get full email address based on mode
  String get _fullEmail {
    if (_enableDomainSuffix && _domainSuffixList.isNotEmpty) {
      if (_usernameController.text.trim().isEmpty || _selectedDomain == null) {
        return '';
      }
      return '${_usernameController.text.trim()}@$_selectedDomain';
    } else {
      return _emailController.text.trim();
    }
  }

  Future<void> _handleSendCode() async {
    final email = _fullEmail;
    
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = '请输入有效的邮箱地址';
      });
      return;
    }
    
    // Validate domain if not in whitelist mode (whitelist mode enforced by dropdown)
    if (!_enableDomainSuffix && ConfigService.enableDomainSuffix) {
       // Fallback check if config changed or logic inconsistent
       // Should ideally just rely on backend, but good to check locally too
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // type 1: Register
      await AuthService.sendEmailCode(email, type: 1);

      if (!mounted) return;

      setState(() {
        _countdown = ConfigService.codeExpire; // Use config expire time
        _isLoading = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _fullEmail;
    if (email.isEmpty) {
        setState(() => _errorMessage = '请输入邮箱地址');
        return;
    }

    // Verify code required check
    if (_enableVerify && _emailCodeController.text.isEmpty) {
      setState(() => _errorMessage = '请输入验证码');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '两次密码不一致';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.register(
        email: email,
        password: _passwordController.text,
        emailCode: _emailCodeController.text.trim().isNotEmpty
            ? _emailCodeController.text.trim()
            : null,
        inviteCode: _inviteCodeController.text.trim().isNotEmpty
            ? _inviteCodeController.text.trim()
            : null,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainLayout(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '注册账号',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '加入 Lray',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Email Input Logic (Domain Whitelist vs Regular)
          const Text('电邮', style: _labelStyle),
          const SizedBox(height: 4),
          if (_enableDomainSuffix && _domainSuffixList.isNotEmpty)
            // Username + Dropdown Layout
             Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration('用户名', Icons.mail_outline_rounded),
                      validator: (v) => v == null || v.isEmpty ? '请输入' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('@', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDomain,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        items: _domainSuffixList.map((String domain) {
                          return DropdownMenuItem<String>(
                            value: domain,
                            child: Text(
                              domain,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDomain = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Regular Email Input
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration('请输入邮箱地址', Icons.mail_outline_rounded),
                validator: (v) => v == null || !v.contains('@') ? '请输入有效的邮箱' : null,
              ),
            ),
            
          const SizedBox(height: 8),

          // Verification Code (Conditional)
          if (_enableVerify) ...[
            const Text('验证码', style: _labelStyle),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextFormField(
                      controller: _emailCodeController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration('验证码', Icons.verified_user_outlined),
                      validator: (v) => v == null || v.isEmpty ? '请输入' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _countdown > 0 || _isLoading ? null : _handleSendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _countdown > 0 ? '${_countdown}s' : '发送',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Password
          const Text('密码', style: _labelStyle),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _passwordController,
              style: const TextStyle(fontSize: 13),
              obscureText: _obscurePassword,
              decoration: _inputDecoration('请输入密码', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              validator: (v) => v == null || v.length < 6 ? '密码至少6位' : null,
            ),
          ),
          const SizedBox(height: 8),

          // Confirm Password
          const Text('确认密码', style: _labelStyle),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _confirmPasswordController,
              style: const TextStyle(fontSize: 13),
              obscureText: _obscureConfirmPassword,
              decoration: _inputDecoration('请再次输入密码', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              validator: (v) => v != _passwordController.text ? '两次密码不一致' : null,
            ),
          ),
          const SizedBox(height: 8),

          // Invite Code
          const Text('邀请码 (可选)', style: _labelStyle),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _inviteCodeController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDecoration('请输入邀请码', Icons.card_giftcard_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Register Button
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '注册',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ),
          
          // OAuth Registration
          const OAuthButtons(),
          
          const SizedBox(height: 12),

          // To Login Link
          Center(
            child: InkWell(
              onTap: widget.onLogin,
              child: RichText(
                text: const TextSpan(
                  text: '已有账号？ ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '立即登录',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF333333),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
      prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
