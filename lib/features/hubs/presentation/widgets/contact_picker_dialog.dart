import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/features/hubs/presentation/screens/add_manual_player_dialog.dart';

/// Dialog for selecting a contact to add as a player
class ContactPickerDialog extends ConsumerStatefulWidget {
  final String hubId;

  const ContactPickerDialog({super.key, required this.hubId});

  @override
  ConsumerState<ContactPickerDialog> createState() =>
      _ContactPickerDialogState();
}

class _ContactPickerDialogState extends ConsumerState<ContactPickerDialog> {
  List<Contact>? _contacts;
  List<Contact>? _filteredContacts;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Request permission
      final status = await Permission.contacts.request();

      if (!status.isGranted) {
        setState(() {
          _error = 'נדרשת הרשאה לגישה לאנשי קשר';
          _isLoading = false;
        });
        return;
      }

      // Fetch contacts with phone numbers only
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter contacts that have phone numbers
      final contactsWithPhones = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      setState(() {
        _contacts = contactsWithPhones;
        _filteredContacts = contactsWithPhones;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() {
        _error = 'שגיאה בטעינת אנשי הקשר: $e';
        _isLoading = false;
      });
    }
  }

  void _filterContacts(String query) {
    if (_contacts == null) return;

    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredContacts = _contacts!
            .where((contact) =>
                contact.displayName.toLowerCase().contains(lowerQuery) ||
                contact.phones.any(
                    (phone) => phone.number.replaceAll(RegExp(r'\D'), '').contains(query)))
            .toList();
      }
    });
  }

  Future<void> _selectContact(Contact contact) async {
    // Close the contact picker
    Navigator.pop(context);

    // Get the first phone number
    final phoneNumber = contact.phones.first.number;
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Show the add manual player dialog pre-filled with contact info
    await showDialog(
      context: context,
      builder: (context) => AddManualPlayerDialog(
        hubId: widget.hubId,
        initialName: contact.displayName,
        initialPhone: normalizedPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PremiumColors.accent.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.contacts,
                    color: PremiumColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'בחר איש קשר',
                          style: PremiumTypography.heading3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'בחר שחקן מרשימת אנשי הקשר שלך',
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            if (!_isLoading && _contacts != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'חפש איש קשר...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterContacts('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _filterContacts,
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: KineticLoadingAnimation(size: 60))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: PremiumTypography.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _loadContacts,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('נסה שוב'),
                                ),
                                if (_error!.contains('הרשאה')) ...[
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await openAppSettings();
                                    },
                                    icon: const Icon(Icons.settings),
                                    label: const Text('פתח הגדרות'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : _filteredContacts!.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'לא נמצאו אנשי קשר עם מספרי טלפון'
                                          : 'לא נמצאו תוצאות',
                                      style: PremiumTypography.heading3,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredContacts!.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts![index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PremiumCard(
                                    elevation: PremiumCardElevation.sm,
                                    onTap: () => _selectContact(contact),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: PremiumColors.accent
                                              .withOpacity(0.1),
                                          child: Text(
                                            contact.displayName.isNotEmpty
                                                ? contact.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style:
                                                PremiumTypography.heading3.copyWith(
                                              color: PremiumColors.accent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.displayName,
                                                style: PremiumTypography.bodyLarge
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                contact.phones.first.number,
                                                style: PremiumTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      PremiumColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
