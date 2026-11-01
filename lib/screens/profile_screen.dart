import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../services/profile_photo_service.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _photoService = const ProfilePhotoService();
  bool _isPickingPhoto = false;

  AppState get appState => widget.appState;

  @override
  Widget build(BuildContext context) {
    final initial = appState.userName.isEmpty
        ? 'S'
        : appState.userName.substring(0, 1).toUpperCase();
    final avatarPath = appState.userAvatarPath;
    final avatarFile = avatarPath == null ? null : File(avatarPath);
    final hasAvatar = avatarFile?.existsSync() ?? false;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppTheme.primary,
                        backgroundImage: hasAvatar
                            ? FileImage(avatarFile!)
                            : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: IconButton.filled(
                          tooltip: 'Choose profile photo',
                          onPressed: _isPickingPhoto ? null : _pickPhoto,
                          iconSize: 18,
                          constraints: const BoxConstraints.tightFor(
                            width: 34,
                            height: 34,
                          ),
                          padding: EdgeInsets.zero,
                          icon: _isPickingPhoto
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          appState.userEmail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blueGrey.shade600),
                        ),
                        if (appState.userPhone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            appState.userPhone,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.blueGrey.shade600),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Text(
                          appState.isDemoAccount
                              ? 'Demonstration account'
                              : 'Local device account',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.manage_accounts_outlined,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Edit profile'),
                  subtitle: const Text('Change your name and phone number'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _editProfile,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.password_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Change password'),
                  subtitle: Text(
                    appState.isDemoAccount
                        ? 'Register an account to use this function'
                        : 'Verify your current password first',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _changePassword,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    hasAvatar ? 'Change profile photo' : 'Upload profile photo',
                  ),
                  subtitle: const Text('Choose an image smaller than 8 MB'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _isPickingPhoto ? null : _pickPhoto,
                ),
                if (hasAvatar) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Remove profile photo'),
                    onTap: _removePhoto,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  value: '${appState.bookings.length}',
                  label: 'Bookings',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileStat(
                  value: '${appState.favouriteIds.length}',
                  label: 'Favourites',
                  icon: Icons.favorite_border_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileStat(
                  value: '${appState.comparisonIds.length}',
                  label: 'Comparing',
                  icon: Icons.compare_arrows_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Favourite vehicles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (appState.favouriteVehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3E9E6)),
              ),
              child: const Text(
                'Tap the heart on a vehicle to save it here.',
                style: TextStyle(color: Colors.blueGrey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final vehicle in appState.favouriteVehicles)
                  InputChip(
                    avatar: const Icon(Icons.directions_car_rounded, size: 17),
                    label: Text(vehicle.name),
                    onDeleted: () => appState.toggleFavourite(vehicle.id),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          _InformationCard(
            icon: Icons.public_rounded,
            title: 'How SmartRent MY supports SDG 9',
            body:
                'SmartRent MY applies mobile technology and Malaysian government open data to improve transport decision-making, encourage cost-efficient mobility and increase awareness of emerging vehicle technologies.',
            color: AppTheme.primary,
            background: AppTheme.mint,
          ),
          const SizedBox(height: 12),
          const _InformationCard(
            icon: Icons.dataset_outlined,
            title: 'Government data sources',
            body:
                'Fuel prices: Ministry of Finance Malaysia.\nVehicle registrations: Road Transport Department and Ministry of Transport.\nAccessed through data.gov.my under CC BY 4.0.',
            color: Color(0xFF075985),
            background: Color(0xFFE9F5FF),
          ),
          const SizedBox(height: 12),
          const _InformationCard(
            icon: Icons.info_outline_rounded,
            title: 'About the prototype',
            body:
                'Version 1.0.0 · Built with Flutter\nAccount credentials are hashed and stored in this app’s private local storage for the assignment prototype.',
            color: Color(0xFF7C3AED),
            background: Color(0xFFF3EEFF),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your account will remain saved on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      appState.signOut();
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog<_ProfileEditData>(
      context: context,
      builder: (_) => _EditProfileDialog(
        currentName: appState.userName,
        currentPhone: appState.userPhone,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    final error = await appState.updateProfile(
      displayName: result.displayName,
      phone: result.phone,
    );
    if (mounted) {
      _showMessage(error ?? 'Profile updated successfully.');
    }
  }

  Future<void> _changePassword() async {
    if (appState.isDemoAccount) {
      _showMessage('Register a local account before changing its password.');
      return;
    }
    final result = await showDialog<_PasswordChangeData>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (!mounted || result == null) {
      return;
    }
    final error = await appState.changePassword(
      currentPassword: result.currentPassword,
      newPassword: result.newPassword,
    );
    if (mounted) {
      _showMessage(error ?? 'Password changed successfully.');
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final path = await _photoService.pickPhoto();
      if (path == null || !mounted) {
        return;
      }
      final error = await appState.updateAvatar(path);
      if (mounted) {
        _showMessage(error ?? 'Profile photo updated.');
      }
    } on ProfilePhotoException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    final previousPath = appState.userAvatarPath;
    final error = await appState.removeAvatar();
    if (error == null) {
      await _photoService.deletePhoto(previousPath);
    }
    if (mounted) {
      _showMessage(error ?? 'Profile photo removed.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ProfileEditData {
  const _ProfileEditData({required this.displayName, required this.phone});

  final String displayName;
  final String phone;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.currentName,
    required this.currentPhone,
  });

  final String currentName;
  final String currentPhone;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    AppValidators.personName(value, label: 'display name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: AppValidators.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.pop(
              context,
              _ProfileEditData(
                displayName: _nameController.text.trim(),
                phone: _phoneController.text.trim(),
              ),
            );
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}

class _PasswordChangeData {
  const _PasswordChangeData({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: _obscure,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'Enter your current password.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _newController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: AppValidators.password,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.password_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value != _newController.text) {
                    return 'Passwords do not match.';
                  }
                  if (value == _currentController.text) {
                    return 'Choose a different password.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.pop(
              context,
              _PasswordChangeData(
                currentPassword: _currentController.text,
                newPassword: _newController.text,
              ),
            );
          },
          child: const Text('Change password'),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 21, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: TextStyle(
                    color: Color.lerp(color, Colors.black, 0.25),
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
