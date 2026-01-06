import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth_split_layout.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth/login_form.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth/register_form.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth/forgot_password_form.dart';

enum AuthMode { login, register, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget form;
    switch (_mode) {
      case AuthMode.login:
        form = LoginForm(
          onRegister: () => _switchMode(AuthMode.register),
          onForgotPassword: () => _switchMode(AuthMode.forgotPassword),
        );
        break;
      case AuthMode.register:
        form = RegisterForm(
          onLogin: () => _switchMode(AuthMode.login),
        );
        break;
      case AuthMode.forgotPassword:
        form = ForgotPasswordForm(
          onLogin: () => _switchMode(AuthMode.login),
        );
        break;
    }

    int? carouselIndex;
    switch (_mode) {
      case AuthMode.login:
        carouselIndex = null; // Auto-play
        break;
      case AuthMode.register:
        carouselIndex = 1; // Real-time sync
        break;
      case AuthMode.forgotPassword:
        carouselIndex = 2; // Secure
        break;
    }

    // AuthSplitLayout is stateless and contains the const AuthCarouselPanel.
    // Changing the formChild will rebuild the layout, but the carousel should preserve state 
    // if the tree structure remains consistent or if it's const.
    return AuthSplitLayout(
      formChild: form,
      carouselIndex: carouselIndex,
    );
  }
}
