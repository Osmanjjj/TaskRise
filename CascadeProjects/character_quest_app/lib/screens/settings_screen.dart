import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // 設定セクション
          _buildSettingsSection(context),
          const SizedBox(height: 24),
          
          // サポートセクション
          _buildSupportSection(context),
          const SizedBox(height: 24),
          
          // ログアウトセクション
          _buildLogoutSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '設定',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('通知設定'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showNotificationSettings(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('プライバシー設定'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacySettings(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('言語設定'),
                  subtitle: const Text('日本語'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageSettings(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('テーマ設定'),
                  subtitle: const Text('システム設定に従う'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showThemeSettings(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'サポート',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('ヘルプ・サポート'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showHelpSupport(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback),
                  title: const Text('フィードバック'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showFeedback(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('アプリについて'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAppInfo(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTermsOfService(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: ListTile(
          leading: Icon(Icons.logout, color: Colors.red[600]),
          title: Text(
            'ログアウト',
            style: TextStyle(color: Colors.red[600]),
          ),
          onTap: () => _handleLogout(context),
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知設定'),
        content: const Text('通知設定は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシー設定'),
        content: const Text('プライバシー設定は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('言語設定'),
        content: const Text('言語設定は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: const Text('テーマ設定は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルプ・サポート'),
        content: const Text(
          'Character Questについてご不明な点がございましたら、\n'
          'support@characterquest.comまでお気軽にお問い合わせください。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィードバック'),
        content: const Text('フィードバック機能は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Character Quest について'),
        content: const Text(
          'Character Quest v1.0.0\n\n'
          '習慣を育てて、キャラクターと一緒に成長しよう！\n'
          'ゲーミフィケーション習慣管理アプリです。\n\n'
          '© 2024 Character Quest Team'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('利用規約'),
        content: const Text('利用規約は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: const Text('プライバシーポリシーは開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }
}