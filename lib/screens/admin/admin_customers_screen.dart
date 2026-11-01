import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/local_account.dart';
import '../../state/app_state.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer records',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${customers.length} searchable customer records',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search customer name, email or phone',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const Center(child: Text('No customer records match.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _CustomerCard(
                      account: customers[index],
                      appState: widget.appState,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<LocalAccount> _customers() {
    final values = <LocalAccount>[
      LocalAccount(
        displayName: 'Demo Student',
        email: 'student@smartrent.my',
        phone: '',
        passwordHash: '',
        passwordSalt: '',
        securityPhraseHash: '',
        securityPhraseSalt: '',
        createdAt: DateTime(2026, 7, 23),
      ),
      ...widget.appState.registeredAccounts.where(
        (account) => account.role == AccountRole.customer,
      ),
    ];
    final unique = <String, LocalAccount>{
      for (final account in values) account.email.toLowerCase(): account,
    }.values.toList();
    final query = _searchController.text.trim().toLowerCase();
    return unique.where((account) {
      final searchable =
          '${account.displayName} ${account.email} ${account.phone}'
              .toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.account, required this.appState});

  final LocalAccount account;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final bookings = appState.allBookings
        .where(
          (booking) =>
              booking.customerEmail.toLowerCase() ==
              account.email.toLowerCase(),
        )
        .toList();
    final spent = bookings
        .where((booking) => booking.status.name != 'cancelled')
        .fold<double>(0, (sum, booking) => sum + booking.cost.totalCost);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.mint,
          child: Text(
            account.displayName.isEmpty
                ? 'C'
                : account.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          account.displayName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(account.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: account.isActive ? AppTheme.mint : const Color(0xFFFFE4E4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            account.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: account.isActive ? AppTheme.primary : Colors.red.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        children: [
          const Divider(),
          _CustomerRow(
            label: 'Phone',
            value: account.phone.isEmpty ? 'Not provided' : account.phone,
          ),
          _CustomerRow(
            label: 'Registered',
            value: formatDate(account.createdAt),
          ),
          _CustomerRow(label: 'Bookings', value: '${bookings.length}'),
          _CustomerRow(label: 'Booking value', value: formatRinggit(spent)),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Colors.blueGrey,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Passwords and recovery phrases are never displayed to administrators.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
