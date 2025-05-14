import 'package:flutter/material.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSection(
                'Privacy Policy for HelpMeOut',
                'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              ),
              _buildSection(
                'Information We Collect',
                'We collect the following personal information when you register and use our service:\n'
                    '• Full Name (First and Last Name)\n'
                    '• Email Address\n'
                    '• Videos you upload\n'
                    '• Device information and usage data',
              ),
              _buildSection(
                'How We Use Your Information',
                'We use your information to:\n'
                    '• Create and manage your account\n'
                    '• Store and process your uploaded videos\n'
                    '• Provide assistance and support\n'
                    '• Improve our services\n'
                    '• Send important notifications about the service',
              ),
              _buildSection(
                'Video Storage and Sharing',
                'Videos you upload are stored securely in our cloud storage. These videos are associated with your account and are only accessible to you unless you choose to share them. We do not use your videos for any purpose other than providing the service to you.',
              ),
              _buildSection(
                'Data Security',
                'We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing, accidental loss, destruction, or damage. We use Firebase Authentication, Storage, and Firestore to secure your data.',
              ),
              _buildSection(
                'Your Rights',
                'You have the right to:\n'
                    '• Access your personal data\n'
                    '• Correct inaccurate data\n'
                    '• Delete your data (videos and account information)\n'
                    '• Withdraw consent at any time\n'
                    '• Request a copy of your data',
              ),
              _buildSection(
                'Third-Party Services',
                'Our app uses Firebase services provided by Google for authentication, data storage, and analytics. Your use of these services is also governed by their respective privacy policies.',
              ),
              _buildSection(
                'Children\'s Privacy',
                'Our services are not directed to individuals under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information.',
              ),
              _buildSection(
                'Changes to This Policy',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              ),
              _buildSection(
                'Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at abdulmuiz.olatunbosun@gmail.com.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
