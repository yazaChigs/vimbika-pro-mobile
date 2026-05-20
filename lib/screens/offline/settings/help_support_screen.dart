import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/screens/offline/settings/help_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/invite_friend_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'feedback_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchAboutUsUrl(BuildContext context) async {
    final Uri url = Uri.parse('https://www.vimbika.co.zw/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Help & Support', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSupportItem(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Read FAQs and guides',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          _buildSupportItem(
            context,
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Tell us what you think',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
          _buildSupportItem(
            context,
            icon: Icons.group_add_outlined,
            title: 'Invite a Friend',
            subtitle: 'Share Vimbika with others',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InviteFriend()),
              );
            },
          ),
          _buildSupportItem(
            context,
            icon: Icons.star_outline,
            title: 'Rate this App',
            subtitle: 'Love it? Let us know!',
            onTap: () {
              // TODO: Implement rating logic
            },
          ),
          _buildSupportItem(
            context,
            icon: Icons.info_outline,
            title: 'About Us',
            subtitle: 'Learn more about Vimbika',
            onTap: () => _launchAboutUsUrl(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.vimbikaBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppTheme.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.grey),
        onTap: onTap,
      ),
    );
  }
}
