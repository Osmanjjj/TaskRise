import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../models/subscription.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  const SubscriptionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final subscriptions = characterProvider.activeSubscriptions;
        final benefits = characterProvider.subscriptionBenefits;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'サブスクリプション',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showSubscriptionDialog(context, characterProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upgrade,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'アップグレード',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (subscriptions.isEmpty) 
                  _buildFreeUserStatus(context)
                else
                  _buildPremiumUserStatus(context, subscriptions, benefits),

                const SizedBox(height: 12),
                _buildBenefitsList(context, benefits),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreeUserStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'フリープラン',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '基本機能をご利用いただけます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUserStatus(
    BuildContext context,
    List<Subscription> subscriptions,
    SubscriptionBenefits? benefits,
  ) {
    return Column(
      children: subscriptions.map((subscription) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getSubscriptionColor(subscription.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getSubscriptionColor(subscription.type).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getSubscriptionIcon(subscription.type),
              color: _getSubscriptionColor(subscription.type),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.type.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getSubscriptionColor(subscription.type),
                    ),
                  ),
                  Text(
                    '有効期限: ${_formatDate(subscription.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpiringSoon(subscription.endDate))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '期限間近',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBenefitsList(BuildContext context, SubscriptionBenefits? benefits) {
    final List<_Benefit> benefitList = [
      _Benefit(
        icon: Icons.star,
        title: 'プレミアム機能',
        enabled: benefits?.hasBasic ?? false,
        color: Colors.amber,
      ),
      _Benefit(
        icon: Icons.groups,
        title: 'ギルド作成',
        enabled: benefits?.canCreateFixedGuild ?? false,
        color: Colors.green,
      ),
      _Benefit(
        icon: Icons.military_tech,
        title: 'バトルパス',
        enabled: benefits?.hasBattlePass ?? false,
        color: Colors.purple,
      ),
      _Benefit(
        icon: Icons.business,
        title: 'エンタープライズ',
        enabled: benefits?.hasEnterprise ?? false,
        color: Colors.blue,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '利用可能な機能',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: benefitList.map((benefit) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: benefit.enabled 
                    ? benefit.color.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: benefit.enabled 
                      ? benefit.color.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    benefit.enabled ? benefit.icon : Icons.lock,
                    size: 12,
                    color: benefit.enabled ? benefit.color : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    benefit.title,
                    style: TextStyle(
                      fontSize: 10,
                      color: benefit.enabled ? benefit.color : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, CharacterProvider characterProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブスクリプション'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('プランを選択してください：'),
              const SizedBox(height: 16),
              _buildPlanOption(
                context,
                'ベーシックプレミアム',
                '¥500/月',
                'プレミアム機能全般',
                Colors.amber,
                SubscriptionType.basic,
                characterProvider,
              ),
              const SizedBox(height: 8),
              _buildPlanOption(
                context,
                'ギルドプラン',
                '¥300/月',
                '固定ギルド作成・管理',
                Colors.green,
                SubscriptionType.guild,
                characterProvider,
              ),
              const SizedBox(height: 8),
              _buildPlanOption(
                context,
                'バトルパス',
                '¥800/月',
                '特別イベント・限定報酬',
                Colors.purple,
                SubscriptionType.battlePass,
                characterProvider,
              ),
              const SizedBox(height: 8),
              _buildPlanOption(
                context,
                'エンタープライズ',
                '¥1,000/ユーザー',
                '組織向け機能・分析',
                Colors.blue,
                SubscriptionType.enterprise,
                characterProvider,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(
    BuildContext context,
    String title,
    String price,
    String description,
    Color color,
    SubscriptionType type,
    CharacterProvider characterProvider,
  ) {
    final hasSubscription = characterProvider.activeSubscriptions
        .any((sub) => sub.type == type);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: hasSubscription ? null : () => _subscribe(context, type, characterProvider),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _getSubscriptionIcon(type),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSubscription)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '契約中',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    SubscriptionType type,
    CharacterProvider characterProvider,
  ) async {
    Navigator.of(context).pop(); // Close dialog

    final success = await characterProvider.subscribe(type, 1);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.displayName}にご契約いただきありがとうございます！'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('契約に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getSubscriptionColor(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.basic:
        return Colors.amber;
      case SubscriptionType.guild:
        return Colors.green;
      case SubscriptionType.battlePass:
        return Colors.purple;
      case SubscriptionType.enterprise:
        return Colors.blue;
    }
  }

  IconData _getSubscriptionIcon(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.basic:
        return Icons.star;
      case SubscriptionType.guild:
        return Icons.groups;
      case SubscriptionType.battlePass:
        return Icons.military_tech;
      case SubscriptionType.enterprise:
        return Icons.business;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  bool _isExpiringSoon(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference <= 7;
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final bool enabled;
  final Color color;

  _Benefit({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.color,
  });
}
