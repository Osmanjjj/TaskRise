import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildForm(),
                        const SizedBox(height: 24),
                        _buildActionButton(),
                        const SizedBox(height: 16),
                        _buildToggleButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialButtons(),
                        if (!_isSignUp) ...[
                          const SizedBox(height: 16),
                          _buildForgotPasswordButton(),
                        ],
                        const SizedBox(height: 24),
                        _buildDebugSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Character Quest',
          style: GoogleFonts.notoSansJp(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp ? 'アカウントを作成' : 'おかえりなさい',
          style: GoogleFonts.notoSansJp(
            fontSize: 16,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            _buildTextField(
              controller: _displayNameController,
              label: '表示名',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '表示名を入力してください';
                }
                if (value.length < 2) {
                  return '表示名は2文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'メールアドレス',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return '正しいメールアドレスを入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'パスワード',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください';
              }
              if (value.length < 6) {
                return 'パスワードは6文字以上で入力してください';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.notoSansJp(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
      ),
    );
  }

  Widget _buildActionButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUp ? 'アカウント作成' : 'ログイン',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignUp = !_isSignUp;
        });
      },
      child: Text(
        _isSignUp ? 'すでにアカウントをお持ちですか？ ログイン' : 'アカウントをお持ちでない方は こちら',
        style: GoogleFonts.notoSansJp(
          color: const Color(0xFF667eea),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'または',
            style: GoogleFonts.notoSansJp(
              color: const Color(0xFF718096),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            _buildSocialButton(
              onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
              icon: Icons.g_mobiledata,
              label: 'Googleでログイン',
              color: const Color(0xFFDB4437),
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              onPressed: authProvider.isLoading ? null : _handleAppleSignIn,
              icon: Icons.apple,
              label: 'Appleでログイン',
              color: const Color(0xFF000000),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: GoogleFonts.notoSansJp(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: _handleForgotPassword,
      child: Text(
        'パスワードを忘れた方はこちら',
        style: GoogleFonts.notoSansJp(
          color: const Color(0xFF718096),
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isSignUp) {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );
    } else {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (authProvider.errorMessage != null && mounted) {
      _showErrorDialog(authProvider.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (authProvider.errorMessage != null && mounted) {
      _showErrorDialog(authProvider.errorMessage!);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (authProvider.errorMessage != null && mounted) {
      _showErrorDialog(authProvider.errorMessage!);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('メールアドレスを入力してください');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      _showSuccessDialog('パスワードリセットメールを送信しました');
    } else if (authProvider.errorMessage != null && mounted) {
      _showErrorDialog(authProvider.errorMessage!);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'エラー',
          style: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSansJp(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.notoSansJp(color: const Color(0xFF667eea)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '成功',
          style: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSansJp(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.notoSansJp(color: const Color(0xFF667eea)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'デバッグ情報',
          style: GoogleFonts.notoSansJp(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            // 現在のセッション情報を表示
            final session = Supabase.instance.client.auth.currentSession;
            final user = Supabase.instance.client.auth.currentUser;
            
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'デバッグ情報',
                  style: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Session: ${session != null ? "Active" : "None"}'),
                      if (user != null) ...[
                        Text('User ID: ${user.id}'),
                        Text('Email: ${user.email ?? 'N/A'}'),
                        Text('Confirmed: ${user.emailConfirmedAt != null}'),
                      ],
                      const SizedBox(height: 16),
                      const Text('Supabase Configuration:'),
                      Text('URL: ${SupabaseConfig.url}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '閉じる',
                      style: GoogleFonts.notoSansJp(color: const Color(0xFF667eea)),
                    ),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 36),
          ),
          child: Text(
            '認証状態を確認',
            style: GoogleFonts.notoSansJp(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
