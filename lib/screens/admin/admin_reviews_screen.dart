import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/vehicle_review.dart';
import '../../state/app_state.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _searchController = TextEditingController();
  String _visibility = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews();
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
                  'Review management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reviews.length} of ${widget.appState.allReviews.length} reviews',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search vehicle, customer or review text',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Visible', label: Text('Visible')),
                    ButtonSegment(value: 'Hidden', label: Text('Hidden')),
                  ],
                  selected: {_visibility},
                  onSelectionChanged: (value) =>
                      setState(() => _visibility = value.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: reviews.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No reviews match the current filter. Customers can review completed rentals.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _AdminReviewCard(
                      review: reviews[index],
                      appState: widget.appState,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<VehicleReview> _reviews() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.appState.allReviews.where((review) {
      final matchesVisibility = switch (_visibility) {
        'Visible' => !review.isHidden,
        'Hidden' => review.isHidden,
        _ => true,
      };
      final searchable =
          '${review.vehicleName} ${review.customerName} ${review.customerEmail} ${review.comment}'
              .toLowerCase();
      return matchesVisibility && (query.isEmpty || searchable.contains(query));
    }).toList();
  }
}

class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard({required this.review, required this.appState});

  final VehicleReview review;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: review.isHidden ? const Color(0xFFF4F4F4) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.vehicleName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${review.customerName} · ${formatDate(review.createdAt)}',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var value = 1; value <= 5; value++)
                  Icon(
                    value <= review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(review.comment),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.isHidden
                        ? 'Hidden from customers'
                        : 'Visible to customers',
                    style: TextStyle(
                      color: review.isHidden
                          ? Colors.red.shade700
                          : AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final error = appState.setReviewHidden(
                      review.id,
                      !review.isHidden,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ??
                              (review.isHidden
                                  ? 'Review restored.'
                                  : 'Review hidden from customers.'),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    review.isHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                  label: Text(review.isHidden ? 'Restore' : 'Hide'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
