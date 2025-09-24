import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General';
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  void _loadFAQs() {
    // Mock data - in real app, this would come from API
    _faqs = [
      {
        'id': '1',
        'question': 'How do I mark attendance using QR code?',
        'answer': 'To mark attendance using QR code, go to the Scan QR tab, point your camera at the QR code displayed by your teacher, and wait for the confirmation message.',
        'category': 'Attendance',
        'tags': ['qr', 'attendance', 'scanning'],
      },
      {
        'id': '2',
        'question': 'What should I do if I can\'t scan the QR code?',
        'answer': 'If you can\'t scan the QR code, try the following: 1) Ensure good lighting, 2) Clean your camera lens, 3) Try manual entry option, 4) Contact your teacher for assistance.',
        'category': 'Troubleshooting',
        'tags': ['qr', 'scanning', 'troubleshooting'],
      },
      {
        'id': '3',
        'question': 'How can I view my attendance history?',
        'answer': 'You can view your attendance history by going to the Attendance tab. It shows your recent attendance records, statistics, and trends.',
        'category': 'Attendance',
        'tags': ['history', 'records', 'statistics'],
      },
      {
        'id': '4',
        'question': 'How do I update my profile information?',
        'answer': 'To update your profile, go to the Profile tab, tap on the edit button, make your changes, and save. Some information may require admin approval.',
        'category': 'Profile',
        'tags': ['profile', 'edit', 'update'],
      },
      {
        'id': '5',
        'question': 'What if I forget my password?',
        'answer': 'If you forget your password, tap on "Forgot Password" on the login screen, enter your email address, and follow the instructions sent to your email.',
        'category': 'Account',
        'tags': ['password', 'forgot', 'reset'],
      },
      {
        'id': '6',
        'question': 'How do I enable notifications?',
        'answer': 'To enable notifications, go to Settings > Notifications and toggle the notification types you want to receive. Make sure app notifications are enabled in your device settings.',
        'category': 'Settings',
        'tags': ['notifications', 'settings', 'alerts'],
      },
      {
        'id': '7',
        'question': 'Can I use the app offline?',
        'answer': 'Some features work offline, but you need an internet connection to sync attendance data and access real-time information.',
        'category': 'General',
        'tags': ['offline', 'internet', 'sync'],
      },
      {
        'id': '8',
        'question': 'How do I contact support?',
        'answer': 'You can contact support by using the Contact Us form in this help section, or email us at support@attendanceapp.com',
        'category': 'Support',
        'tags': ['contact', 'support', 'help'],
      },
    ];
    _filteredFaqs = List.from(_faqs);
  }

  void _filterFAQs() {
    setState(() {
      _filteredFaqs = _faqs.where((faq) {
        final matchesSearch = faq['question'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            faq['answer'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            faq['tags'].any((tag) => tag.toLowerCase().contains(_searchController.text.toLowerCase()));
        
        final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.help), text: 'FAQ'),
              Tab(icon: Icon(Icons.contact_support), text: 'Contact'),
              Tab(icon: Icon(Icons.info), text: 'About'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFAQTab(),
            _buildContactTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterFAQs();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => _filterFAQs(),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'General', 'Attendance', 'Account', 'Settings', 'Troubleshooting', 'Support'].map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _filterFAQs();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // FAQ List
        Expanded(
          child: _filteredFaqs.isEmpty
              ? _buildEmptyFAQState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = _filteredFaqs[index];
                    return _buildFAQCard(faq);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyFAQState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No FAQs found',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          faq['category'],
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer'],
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: (faq['tags'] as List).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: AppTheme.labelSmall,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.contact_support,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Contact Support',
                      style: AppTheme.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re here to help! Send us your questions or feedback.',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send us a message',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'General',
                      'Technical Issue',
                      'Account Problem',
                      'Feature Request',
                      'Bug Report',
                      'Other',
                    ].map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitContactForm,
                      child: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Ways to Reach Us',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfoItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@attendanceapp.com',
                    onTap: () => _sendEmail(),
                  ),
                  _buildContactInfoItem(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () => _makePhoneCall(),
                  ),
                  _buildContactInfoItem(
                    icon: Icons.chat,
                    title: 'Live Chat',
                    subtitle: 'Available 9 AM - 6 PM EST',
                    onTap: () => _startLiveChat(),
                  ),
                  _buildContactInfoItem(
                    icon: Icons.schedule,
                    title: 'Support Hours',
                    subtitle: 'Monday - Friday: 9 AM - 6 PM EST',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: AppTheme.titleMedium),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.school,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Manager',
                              style: AppTheme.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Version 1.0.0',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A comprehensive attendance management system designed for educational institutions. Track student attendance, generate reports, and manage classes efficiently.',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Features',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('QR Code Attendance', 'Quick and secure attendance marking'),
                  _buildFeatureItem('Real-time Analytics', 'Comprehensive attendance reports'),
                  _buildFeatureItem('Student Management', 'Complete student information system'),
                  _buildFeatureItem('Class Scheduling', 'Flexible class and schedule management'),
                  _buildFeatureItem('Notifications', 'Instant alerts and reminders'),
                  _buildFeatureItem('Offline Support', 'Work without internet connection'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Legal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Information',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildLegalItem('Privacy Policy', () => _showPrivacyPolicy()),
                  _buildLegalItem('Terms of Service', () => _showTermsOfService()),
                  _buildLegalItem('License Agreement', () => _showLicenseAgreement()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Credits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credits',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Developed with ❤️ for educational institutions worldwide.',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 Attendance Manager. All rights reserved.',
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: AppTheme.titleMedium),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _submitContactForm() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent successfully! We\'ll get back to you soon.'),
        backgroundColor: Colors.green,
      ),
    );
    
    _subjectController.clear();
    _messageController.clear();
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email client...')),
    );
  }

  void _makePhoneCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening phone dialer...')),
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting live chat...')),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This privacy policy explains how we collect, use, and protect your information when you use our attendance management app...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to our terms of service. Please read these terms carefully...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLicenseAgreement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('License Agreement'),
        content: const SingleChildScrollView(
          child: Text(
            'This software is licensed under the terms specified in this agreement...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
