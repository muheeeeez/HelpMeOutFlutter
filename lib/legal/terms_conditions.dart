import 'package:flutter/material.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Terms & Conditions'),
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
                'Terms and Conditions for HelpMeOut',
                'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              ),
              _buildSection(
                '1. Acceptance of Terms',
                'By accessing or using the HelpMeOut mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, you may not use the App.',
              ),
              _buildSection(
                '2. Description of Service',
                'HelpMeOut provides a platform for users to upload, store, and manage videos for the purpose of getting assistance and expert help. The App allows users to share videos and receive support from specialists in various fields.',
              ),
              _buildSection(
                '3. User Accounts',
                'To use certain features of the App, you must register and create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate information when registering and to update your information if it changes.',
              ),
              _buildSection(
                '4. User Content',
                'You retain ownership of the videos and content you upload to the App. By uploading content, you grant HelpMeOut a non-exclusive, worldwide license to use, store, and process your content solely for the purpose of providing and improving the service.\n\n'
                    'You agree not to upload content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable.',
              ),
              _buildSection(
                '5. Prohibited Activities',
                'You agree not to:\n'
                    '• Use the App for any illegal purpose\n'
                    '• Attempt to gain unauthorized access to the App or other users\' accounts\n'
                    '• Upload malicious code or content\n'
                    '• Impersonate any person or entity\n'
                    '• Interfere with the proper functioning of the App',
              ),
              _buildSection(
                '6. Termination',
                'We reserve the right to terminate or suspend your account and access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users of the App or third parties, or for any other reason.',
              ),
              _buildSection(
                '7. Intellectual Property',
                'The App and its original content, features, and functionality are owned by HelpMeOut and are protected by international copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws.',
              ),
              _buildSection(
                '8. Disclaimer of Warranties',
                'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE.',
              ),
              _buildSection(
                '9. Limitation of Liability',
                'IN NO EVENT SHALL HELPMEOUT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY.',
              ),
              _buildSection(
                '10. Changes to Terms',
                'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days\' notice prior to any new terms taking effect.',
              ),
              _buildSection(
                '11. Contact Us',
                'If you have any questions about these Terms, please contact us at abdulmuiz.olatunbosun@gmail.com.com.',
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
