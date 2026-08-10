import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/responsive_content.dart';
import '../webview/policy_webview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audio = AudioManager.instance;
  final _profile = ProfileService.instance;
  bool _pickingPhoto = false;

  Future<void> _showPhotoOptions() async {
    final photo = _profile.photoFile;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PhotoPickerSheet(
        hasPhoto: photo != null,
        onCamera: () {
          Navigator.pop(ctx);
          _pickPhoto(fromCamera: true);
        },
        onGallery: () {
          Navigator.pop(ctx);
          _pickPhoto(fromCamera: false);
        },
        onRemove: photo != null
            ? () {
                Navigator.pop(ctx);
                _removePhoto();
              }
            : null,
      ),
    );
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      await _profile.pickPhoto(fromCamera: fromCamera);
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    await _profile.removePhoto();
    if (mounted) setState(() {});
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final photo = _profile.photoFile;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/kitchen_manor.webp',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.42)),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const GlassPanel(
                          padding: EdgeInsets.all(10),
                          borderRadius: 30,
                          child: Icon(Icons.arrow_back, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Settings', style: AppTextStyles.h2),
                    ],
                  ),
                ),

                // ── Content ─────────────────────────────────────────
                Expanded(
                  child: ResponsiveContent(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      children: [
                        // Chef Profile card
                        _ChefProfileCard(
                          photo: photo,
                          loading: _pickingPhoto,
                          onTap: _showPhotoOptions,
                        ),
                        const SizedBox(height: 16),

                        // Sound Effects toggle
                        GlassPanel(
                          child: _ToggleRow(
                            label: 'Sound Effects',
                            icon: Icons.volume_up_rounded,
                            value: _audio.sfxEnabled,
                            onChanged: (v) =>
                                setState(() => _audio.setSfxEnabled(v)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _LinkTile(
                          label: 'Privacy Policy',
                          icon: Icons.privacy_tip_outlined,
                          onTap: () => _push(const PolicyWebViewScreen(
                            title: 'Privacy Policy',
                            url: 'https://henhavendash.com/privacy-policy.html',
                          )),
                        ),
                        const SizedBox(height: 12),

                        _LinkTile(
                          label: 'Support',
                          icon: Icons.support_agent_rounded,
                          onTap: () => _push(const PolicyWebViewScreen(
                            title: 'Support',
                            url: 'https://henhavendash.com/support.html',
                          )),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            'Henhaven Dash  ·  v1.0.0',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
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

// ── Chef Profile card ────────────────────────────────────────────────────────

class _ChefProfileCard extends StatelessWidget {
  const _ChefProfileCard({
    required this.photo,
    required this.loading,
    required this.onTap,
  });

  final File? photo;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          Text(
            'Chef Profile',
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: AppTextStyles.heading,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Avatar circle
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                    border: Border.all(color: AppColors.accent, width: 2.5),
                    image: photo != null
                        ? DecorationImage(
                            image: FileImage(photo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photo == null
                      ? loading
                          ? const Padding(
                              padding: EdgeInsets.all(26),
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.accent,
                              size: 44,
                            )
                      : null,
                ),

                // Camera badge in the bottom-right corner of the circle
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border:
                          Border.all(color: AppColors.accent, width: 1.8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            photo != null ? 'Tap to change your chef photo' : 'Add your chef photo',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Photo picker bottom sheet ─────────────────────────────────────────────────

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet({
    required this.hasPhoto,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  final bool hasPhoto;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 10),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              _SheetRow(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: onCamera,
              ),
              _SheetRow(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Library',
                onTap: onGallery,
              ),

              if (onRemove != null) ...[
                Divider(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _SheetRow(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  onTap: onRemove!,
                  color: AppColors.cta,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textOnDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Existing reusable row widgets ─────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textOnDark),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.primaryDark,
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textOnDark),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
