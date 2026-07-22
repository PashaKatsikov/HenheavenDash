import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';
import '../webview/policy_webview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audio = AudioManager.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_manor.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.42)),
          SafeArea(
            child: Column(
              children: [
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    children: [
                      GlassPanel(
                        child: Column(
                          children: [
                            _ToggleRow(
                              label: 'Sound Effects',
                              icon: Icons.volume_up_rounded,
                              value: _audio.sfxEnabled,
                              onChanged: (v) => setState(() => _audio.setSfxEnabled(v)),
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            _ToggleRow(
                              label: 'Music',
                              icon: Icons.music_note_rounded,
                              value: _audio.musicEnabled,
                              onChanged: (v) => setState(() => _audio.setMusicEnabled(v)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LinkTile(
                        label: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PolicyWebViewScreen(
                              title: 'Privacy Policy',
                              url: 'https://henhavendash.com/privacy-policy.html',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LinkTile(
                        label: 'Support',
                        icon: Icons.support_agent_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PolicyWebViewScreen(
                              title: 'Support',
                              url: 'https://henhavendash.com/support.html',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Henhaven Dash  ·  v1.0.0',
                          style: AppTextStyles.caption.copyWith(color: Colors.white54),
                        ),
                      ),
                    ],
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
          child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark)),
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
  const _LinkTile({required this.label, required this.icon, required this.onTap});

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
              child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark)),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
