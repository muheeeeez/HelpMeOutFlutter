import 'package:flutter/material.dart';
import 'privacy_policy.dart';
import 'terms_conditions.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

class LegalCenterScreen extends StatelessWidget {
  const LegalCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Legal Information'),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'HelpMeOut Legal Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Review our legal policies and agreements to better understand how we handle your information and the terms of using our service.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Privacy Policy Card
              _buildLegalCard(
                context,
                'Privacy Policy',
                'Information about how we collect, use, and protect your personal data and uploaded videos.',
                Icons.privacy_tip_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Terms & Conditions Card
              _buildLegalCard(
                context,
                'Terms & Conditions',
                'The rules and guidelines that govern your use of the HelpMeOut application.',
                Icons.gavel_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsConditionsScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Copyright info
              Center(
                child: Text(
                  '© ${DateTime.now().year} HelpMeOut',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 42, color: primaryColor),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
