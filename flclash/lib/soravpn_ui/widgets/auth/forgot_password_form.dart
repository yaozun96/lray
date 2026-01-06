import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback onLogin;

  const ForgotPasswordForm({
    super.key,
    required this.onLogin,
  });

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.sendEmailCode(_emailController.text.trim(), type: 2);

      if (!mounted) return;

      setState(() {
        _countdown = 60;
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.resetPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully')),
      );
      widget.onLogin(); // Go back to login
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
            '重置密码',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24, // Reduced from 28
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          const Text(
            '输入您的邮箱以重置密码',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13, // Reduced from 14
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24), // Reduced from 40

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8), // Reduced from 10
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12), // Reduced from 20
          ],

          // Email
          const Text('邮箱', style: _labelStyle),
          const SizedBox(height: 4), // Reduced from 8
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _emailController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDecoration('请输入邮箱地址', Icons.mail_outline_rounded),
              validator: (v) => v == null || !v.contains('@') ? '请输入有效的邮箱' : null,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16

          // Verification Code
          const Text('验证码', style: _labelStyle),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextFormField(
                    controller: _codeController,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration('请输入验证码', Icons.verified_user_outlined),
                    validator: (v) => v == null || v.isEmpty ? '请输入验证码' : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _countdown > 0 || _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _countdown > 0 ? '${_countdown}s' : '发送验证码',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // New Password
          const Text('新密码', style: _labelStyle),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _passwordController,
              style: const TextStyle(fontSize: 13),
              obscureText: _obscurePassword,
              decoration: _inputDecoration('请输入新密码 (至少8位)', Icons.lock_outline_rounded).copyWith(
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
              validator: (v) => v == null || v.length < 8 ? '密码至少8位' : null,
            ),
          ),
          const SizedBox(height: 24), // Reduced from 32

          // Reset Button
          SizedBox(
            height: 40, // Reduced from 48
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
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
                        Icon(Icons.refresh_rounded, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '重置密码',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16), // Reduced from 24

          // To Login Link
          Center(
            child: InkWell(
              onTap: widget.onLogin,
              child: RichText(
                text: const TextSpan(
                  text: '想起密码了？ ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '返回登录',
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }
}
