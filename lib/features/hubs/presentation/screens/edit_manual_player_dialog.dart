import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog for editing manual player details
class EditManualPlayerDialog extends ConsumerStatefulWidget {
  final User player;
  final String hubId;

  const EditManualPlayerDialog({
    super.key,
    required this.player,
    required this.hubId,
  });

  @override
  ConsumerState<EditManualPlayerDialog> createState() =>
      _EditManualPlayerDialogState();
}

class _EditManualPlayerDialogState
    extends ConsumerState<EditManualPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _ratingController;
  late String _selectedPosition;
  bool _isLoading = false;

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _phoneController =
        TextEditingController(text: widget.player.phoneNumber ?? '');
    _emailController = TextEditingController(
      text:
          widget.player.email.startsWith('manual_') ? '' : widget.player.email,
    );
    _cityController = TextEditingController(text: widget.player.city ?? '');
    _ratingController = TextEditingController(
        text: widget.player.currentRankScore.toStringAsFixed(1));
    _selectedPosition = widget.player.preferredPosition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _updatePlayer() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(
          context, 'Firebase not available'); // This should be localized too
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersRepo = ref.read(usersRepositoryProvider);

      // Parse rating
      final ratingText = _ratingController.text.trim();
      final rating = double.tryParse(ratingText) ?? 3.3;
      final finalRating = rating.clamp(0.0, 10.0);

      // Update user
      final updatedUser = widget.player.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : widget.player.email, // Keep original if empty
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        preferredPosition: _selectedPosition,
        currentRankScore: finalRating,
      );

      await usersRepo.setUser(updatedUser);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      SnackbarHelper.showSuccess(
        context,
        l10n.playerDetailsUpdatedSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showErrorFromException(context, e);
    }
  }

  Future<void> _sendEmailInvitation() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      SnackbarHelper.showError(context, l10n.pleaseEnterValidEmail);
      return;
    }

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);

      if (!mounted) return;
      if (hub == null) {
        SnackbarHelper.showError(context, l10n.hubNotFound);
        return;
      }

      // Get invitation code or use hub ID
      final invitationCode = hub.settings.invitationCode ??
          widget.hubId.substring(0, 8).toUpperCase();
      final invitationLink = 'https://kattrick.app/invite/$invitationCode';

      // Create email subject and body
      final subject = l10n.hubInvitationEmailSubject(hub.name);
      final body = l10n.hubInvitationEmailBody(
        _nameController.text.trim(),
        hub.name,
        invitationLink,
        invitationCode,
      );

      // Open email client
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, l10n.emailClientOpened);
      } else {
        // Fallback: Copy invitation link to clipboard
        await Clipboard.setData(ClipboardData(text: invitationLink));
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, l10n.linkCopiedToClipboard);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showErrorFromException(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editManualPlayerTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.editManualPlayerSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullNameRequired,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailForInvitationLabel,
                    border: const OutlineInputBorder(),
                    hintText: 'player@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!value.contains('@') || !value.contains('.')) {
                        return l10n.invalidEmailAddress;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumberLabel,
                    border: const OutlineInputBorder(),
                    hintText: '050-1234567',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                // City field
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: l10n.cityLabel,
                    border: const OutlineInputBorder(),
                    hintText: 'חיפה',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                // Rating field
                TextFormField(
                  controller: _ratingController,
                  decoration: InputDecoration(
                    labelText: l10n.ratingLabel,
                    border: const OutlineInputBorder(),
                    hintText: '3.3',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final rating = double.tryParse(value);
                      if (rating == null || rating < 0 || rating > 10) {
                        return l10n.ratingRangeError;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Position dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPosition,
                  decoration: InputDecoration(
                    labelText: l10n.preferredPositionLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: _positions.map((position) {
                    return DropdownMenuItem(
                      value: position,
                      child: Text(_getPositionHebrew(position)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPosition = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Send email invitation button
                if (_emailController.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendEmailInvitation,
                        icon: const Icon(Icons.email),
                        label: Text(l10n.sendEmailInvitation),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePlayer,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveChanges),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPositionHebrew(String position) {
    final l10n = AppLocalizations.of(context)!;
    switch (position) {
      case 'Goalkeeper':
        return l10n.positionGoalkeeper;
      case 'Defender':
        return l10n.positionDefense;
      case 'Midfielder':
        return l10n.positionMidfielder;
      case 'Forward':
        return l10n.positionForward;
      default:
        return position;
    }
  }
}
