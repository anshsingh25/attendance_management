import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricAuth = false;
  bool _autoLock = true;
  bool _dataEncryption = true;
  bool _locationTracking = true;
  bool _analyticsCollection = false;
  bool _crashReporting = true;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _sessionTimeout = '30 minutes';
  String _passwordComplexity = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Header
            _buildSecurityHeader(),
            
            const SizedBox(height: 24),
            
            // Authentication Settings
            _buildAuthenticationSection(),
            
            const SizedBox(height: 24),
            
            // Privacy Settings
            _buildPrivacySection(),
            
            const SizedBox(height: 24),
            
            // Notification Settings
            _buildNotificationSection(),
            
            const SizedBox(height: 24),
            
            // Data Management
            _buildDataManagementSection(),
            
            const SizedBox(height: 24),
            
            // Security Actions
            _buildSecurityActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
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
                Icons.security,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy & Security',
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account security and privacy preferences',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication',
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face recognition to unlock the app',
              value: _biometricAuth,
              onChanged: (value) => setState(() => _biometricAuth = value),
              icon: Icons.fingerprint,
            ),
            _buildSwitchTile(
              title: 'Auto Lock',
              subtitle: 'Automatically lock the app when inactive',
              value: _autoLock,
              onChanged: (value) => setState(() => _autoLock = value),
              icon: Icons.lock,
            ),
            _buildDropdownTile(
              title: 'Session Timeout',
              subtitle: 'How long to keep the session active',
              value: _sessionTimeout,
              options: ['15 minutes', '30 minutes', '1 hour', '2 hours', 'Never'],
              onChanged: (value) => setState(() => _sessionTimeout = value!),
              icon: Icons.timer,
            ),
            _buildDropdownTile(
              title: 'Password Complexity',
              subtitle: 'Minimum password requirements',
              value: _passwordComplexity,
              options: ['Low', 'Medium', 'High'],
              onChanged: (value) => setState(() => _passwordComplexity = value!),
              icon: Icons.password,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Location Tracking',
              subtitle: 'Allow the app to track your location for attendance',
              value: _locationTracking,
              onChanged: (value) => setState(() => _locationTracking = value),
              icon: Icons.location_on,
            ),
            _buildSwitchTile(
              title: 'Analytics Collection',
              subtitle: 'Help improve the app by sharing usage analytics',
              value: _analyticsCollection,
              onChanged: (value) => setState(() => _analyticsCollection = value),
              icon: Icons.analytics,
            ),
            _buildSwitchTile(
              title: 'Crash Reporting',
              subtitle: 'Automatically report crashes to help fix issues',
              value: _crashReporting,
              onChanged: (value) => setState(() => _crashReporting = value),
              icon: Icons.bug_report,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive push notifications for important updates',
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
              icon: Icons.notifications,
            ),
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
              icon: Icons.email,
            ),
            _buildSwitchTile(
              title: 'SMS Notifications',
              subtitle: 'Receive notifications via SMS',
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
              icon: Icons.sms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Data Encryption',
              subtitle: 'Encrypt sensitive data stored on device',
              value: _dataEncryption,
              onChanged: (value) => setState(() => _dataEncryption = value),
              icon: Icons.security,
            ),
            _buildActionTile(
              title: 'Export Data',
              subtitle: 'Download a copy of your data',
              icon: Icons.download,
              onTap: _exportData,
            ),
            _buildActionTile(
              title: 'Clear Cache',
              subtitle: 'Remove temporary files and cached data',
              icon: Icons.clear_all,
              onTap: _clearCache,
            ),
            _buildActionTile(
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              icon: Icons.delete_forever,
              onTap: _deleteAccount,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Actions',
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              title: 'Change Password',
              subtitle: 'Update your account password',
              icon: Icons.lock_reset,
              onTap: _changePassword,
            ),
            _buildActionTile(
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              icon: Icons.security,
              onTap: _setupTwoFactor,
            ),
            _buildActionTile(
              title: 'Active Sessions',
              subtitle: 'View and manage active login sessions',
              icon: Icons.devices,
              onTap: _viewActiveSessions,
            ),
            _buildActionTile(
              title: 'Security Log',
              subtitle: 'View recent security events',
              icon: Icons.history,
              onTap: _viewSecurityLog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: AppTheme.titleMedium),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: AppTheme.titleMedium),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Your data will be exported and sent to your registered email address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export initiated')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all temporary files and cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: const Text('Type "DELETE" to confirm account deletion'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deletion initiated')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }

  void _setupTwoFactor() {
    showDialog(
      context: context,
      builder: (context) => _TwoFactorSetupDialog(),
    );
  }

  void _viewActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => _ActiveSessionsDialog(),
    );
  }

  void _viewSecurityLog() {
    showDialog(
      context: context,
      builder: (context) => _SecurityLogDialog(),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (value) => value?.isEmpty == true ? 'Current password is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (value) => value?.isEmpty == true ? 'New password is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'Please confirm your password';
                if (value != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            }
          },
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

class _TwoFactorSetupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Two-Factor Authentication'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Add an extra layer of security to your account'),
          SizedBox(height: 16),
          Text('You can use an authenticator app like Google Authenticator or Authy to generate verification codes.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Two-factor authentication setup initiated')),
            );
          },
          child: const Text('Setup'),
        ),
      ],
    );
  }
}

class _ActiveSessionsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Active Sessions'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text('Device ${index + 1}'),
              subtitle: Text('Last active: ${DateTime.now().subtract(Duration(hours: index)).toString()}'),
              trailing: index == 0 
                ? const Text('Current', style: TextStyle(color: Colors.green))
                : TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Session terminated')),
                      );
                    },
                    child: const Text('Terminate'),
                  ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SecurityLogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Security Log'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.security),
              title: Text('Security Event ${index + 1}'),
              subtitle: Text('${DateTime.now().subtract(Duration(days: index)).toString()}'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
