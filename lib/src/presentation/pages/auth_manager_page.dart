// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';

/// A ready-to-use, premium post-login profile management page.
///
/// Displays the authenticated user's info and provides actions for:
/// - Editing display name
/// - Changing password (email/password users only)
/// - Signing out
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => BlocProvider.value(
///       value: authBloc,
///       child: const AuthManagerPage(),
///     ),
///   ),
/// );
/// ```
class AuthManagerPage extends StatefulWidget {
  const AuthManagerPage({
    super.key,
    this.onSignedOut,
    this.additionalActions,
    this.headerGradientColors,
  });

  /// Called after the user taps Sign Out and the state transitions.
  final VoidCallback? onSignedOut;

  /// Extra action tiles to display below the built-in ones.
  final List<AuthManagerAction>? additionalActions;

  /// Override the header gradient colors (defaults to a deep indigo/violet).
  final List<Color>? headerGradientColors;

  @override
  State<AuthManagerPage> createState() => _AuthManagerPageState();
}

/// Describes an extra action tile to show in the manager page.
class AuthManagerAction {
  const AuthManagerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;
}

class _AuthManagerPageState extends State<AuthManagerPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _headerController;

  bool _isEditingName = false;
  late final TextEditingController _nameController;

  static const _defaultGradient = [Color(0xFF1A1A2E), Color(0xFF16213E)];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _headerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          widget.onSignedOut?.call();
        }
        if (state is DisplayNameUpdatedState) {
          setState(() => _isEditingName = false);
          _showSnackBar('Display name updated', isSuccess: true);
        }
        if (state is PasswordUpdatedState) {
          _showSnackBar('Password updated successfully', isSuccess: true);
        }
        if (state is AuthErrorState) {
          _showSnackBar(state.message, isSuccess: false);
        }
      },
      builder: (context, state) {
        final user = state is AuthenticatedState ? state.user : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          body: Stack(
            children: [
              // Background particles
              AnimatedBuilder(
                animation: _headerController,
                builder:
                    (context, _) => CustomPaint(
                      painter: _ManagerBgPainter(
                        progress: _headerController.value,
                      ),
                      size: Size.infinite,
                    ),
              ),

              // Main content
              SafeArea(
                child:
                    user == null
                        ? _buildUnauthenticatedView()
                        : _buildProfileView(context, user, isLoading),
              ),

              // Loading overlay
              if (isLoading)
                const ColoredBox(
                  color: Color(0x44000000),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: Colors.white38, size: 48),
          SizedBox(height: 16),
          Text(
            'Not signed in',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(
    BuildContext context,
    AuthUser user,
    bool isLoading,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
              onPressed:
                  () => context.read<AuthBloc>().add(
                    const RefreshCurrentUserEvent(),
                  ),
              tooltip: 'Refresh user data',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Profile header card
                _buildProfileHeader(user),
                const SizedBox(height: 28),

                // Account details section
                _buildSectionTitle('Account'),
                const SizedBox(height: 12),
                _buildAccountCard(user),
                const SizedBox(height: 28),

                // Actions section
                _buildSectionTitle('Actions'),
                const SizedBox(height: 12),
                _buildActionsCard(context, user),
                const SizedBox(height: 28),

                // Extra actions from consumer
                if (widget.additionalActions != null &&
                    widget.additionalActions!.isNotEmpty) ...[
                  _buildSectionTitle('More'),
                  const SizedBox(height: 12),
                  _buildExtraActionsCard(),
                  const SizedBox(height: 28),
                ],

                // Sign out
                _staggered(8, child: _buildSignOutButton(context)),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(AuthUser user) {
    final gradientColors = widget.headerGradientColors ?? _defaultGradient;

    return _staggered(
      0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar + glow ring
            AnimatedBuilder(
              animation: _headerController,
              builder: (context, child) {
                final glow =
                    0.08 + 0.06 * sin(_headerController.value * 2 * pi);
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: glow),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child:
                    user.photoURL == null
                        ? Text(
                          _getInitials(user),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 16),

            // Name (editable)
            if (_isEditingName)
              _buildNameEditor()
            else
              GestureDetector(
                onTap: () {
                  _nameController.text = user.displayName ?? '';
                  setState(() => _isEditingName = true);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName ?? 'Set your name',
                        style: TextStyle(
                          color:
                              user.displayName != null
                                  ? Colors.white
                                  : Colors.white38,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Email
            Text(
              user.email.isNotEmpty ? user.email : 'Guest user',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 16),

            // Provider badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final provider in user.providerIds)
                  _ProviderBadge(provider: provider),
                if (user.isAnonymous)
                  const _ProviderBadge(provider: 'anonymous'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameEditor() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Enter display name',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _saveName(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check_circle, color: Color(0xFF7C3AED)),
          onPressed: _saveName,
        ),
        IconButton(
          icon: Icon(
            Icons.cancel_outlined,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          onPressed: () => setState(() => _isEditingName = false),
        ),
      ],
    );
  }

  Widget _buildAccountCard(AuthUser user) {
    return _staggered(
      2,
      child: _GlassCard(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email.isNotEmpty ? user.email : 'Not set',
          ),
          _divider(),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Email Verified',
            value: user.isEmailVerified ? 'Yes' : 'No',
            valueColor:
                user.isEmailVerified
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
          ),
          _divider(),
          _InfoTile(
            icon: Icons.fingerprint,
            label: 'User ID',
            value:
                user.id.length > 16 ? '${user.id.substring(0, 16)}…' : user.id,
          ),
          if (user.isAnonymous) ...[
            _divider(),
            _InfoTile(
              icon: Icons.person_off_outlined,
              label: 'Account Type',
              value: 'Anonymous',
              valueColor: const Color(0xFFF59E0B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, AuthUser user) {
    final hasPasswordProvider = user.providerIds.contains('password');

    return _staggered(
      4,
      child: _GlassCard(
        children: [
          _ActionTile(
            icon: Icons.person_outline,
            label: 'Edit Display Name',
            subtitle: user.displayName ?? 'Not set',
            onTap: () {
              _nameController.text = user.displayName ?? '';
              setState(() => _isEditingName = true);
            },
          ),
          if (hasPasswordProvider) ...[
            _divider(),
            _ActionTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
          if (!user.isEmailVerified && user.email.isNotEmpty) ...[
            _divider(),
            _ActionTile(
              icon: Icons.mark_email_read_outlined,
              label: 'Verify Email',
              subtitle: 'Send verification link',
              onTap: () {
                context.read<AuthBloc>().add(
                  const SendEmailVerificationEvent(),
                );
                _showSnackBar('Verification email sent', isSuccess: true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraActionsCard() {
    return _staggered(
      6,
      child: _GlassCard(
        children: [
          for (var i = 0; i < widget.additionalActions!.length; i++) ...[
            if (i > 0) _divider(),
            _ActionTile(
              icon: widget.additionalActions![i].icon,
              label: widget.additionalActions![i].label,
              subtitle: widget.additionalActions![i].subtitle,
              iconColor: widget.additionalActions![i].iconColor,
              onTap: widget.additionalActions![i].onTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
        color: const Color(0xFFEF4444).withValues(alpha: 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmSignOut(context),
          borderRadius: BorderRadius.circular(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return _staggered(
      title == 'Account'
          ? 1
          : title == 'Actions'
          ? 3
          : 5,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final delay = (index * 0.06).clamp(0.0, 0.5);
    final end = (delay + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.white.withValues(alpha: 0.06));

  // --- Dialogs & Helpers ---

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AuthBloc>().add(UpdateDisplayNameEvent(name: name));
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  context.read<AuthBloc>().add(const SignOutEvent());
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(
                  controller: currentPwCtrl,
                  label: 'Current password',
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: newPwCtrl,
                  label: 'New password',
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: confirmPwCtrl,
                  label: 'Confirm new password',
                  obscure: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (newPwCtrl.text != confirmPwCtrl.text) {
                    _showSnackBar('Passwords do not match', isSuccess: false);
                    return;
                  }
                  if (newPwCtrl.text.length < 6) {
                    _showSnackBar(
                      'Password must be at least 6 characters',
                      isSuccess: false,
                    );
                    return;
                  }
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(
                    UpdatePasswordEvent(
                      currentPassword: currentPwCtrl.text,
                      newPassword: newPwCtrl.text,
                    ),
                  );
                },
                child: const Text(
                  'Update',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getInitials(AuthUser user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (user.email.isNotEmpty) return user.email[0].toUpperCase();
    return '?';
  }
}

// ---------------------------------------------------------------------------
// Glass card container
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info tile (read-only)
// ---------------------------------------------------------------------------
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action tile (tappable)
// ---------------------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider badge chip
// ---------------------------------------------------------------------------
class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});
  final String provider;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (provider) {
      'password' => ('Email', Icons.email, const Color(0xFF3B82F6)),
      'google.com' => ('Google', Icons.g_mobiledata, const Color(0xFFEF4444)),
      'phone' => ('Phone', Icons.phone_android, const Color(0xFF10B981)),
      'anonymous' => ('Guest', Icons.person_off, const Color(0xFFF59E0B)),
      _ => (provider, Icons.security, const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog text field
// ---------------------------------------------------------------------------
class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    this.obscure = false,
  });
  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background particles painter
// ---------------------------------------------------------------------------
class _ManagerBgPainter extends CustomPainter {
  _ManagerBgPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;
    final rng = Random(99);

    // Subtle floating dots
    for (var i = 0; i < 20; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final phase = rng.nextDouble() * 2 * pi;

      final x = baseX + sin(t * speed + phase) * 20;
      final y = (baseY - progress * size.height * 0.15 * speed) % size.height;

      final alpha = 0.03 + rng.nextDouble() * 0.04;
      final color =
          i.isEven
              ? const Color(0xFF7C3AED).withValues(alpha: alpha)
              : const Color(0xFF3B82F6).withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(x, y),
        1.5 + rng.nextDouble() * 2,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_ManagerBgPainter old) => old.progress != progress;
}
