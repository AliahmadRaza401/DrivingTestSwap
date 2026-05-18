import 'package:flutter/material.dart';

import '../../../core/constants/uk_test_centres.dart';
import '../../../core/theme/app_colors.dart';

/// The result returned when a test centre is picked.
class SelectedTestCentre {
  const SelectedTestCentre({
    required this.name,
    required this.postcode,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String postcode;
  final String region;
  final double latitude;
  final double longitude;

  /// Full display string shown on the form field.
  String get displayName => '$name ($postcode)';
}

class TestCentrePickerSheet extends StatefulWidget {
  const TestCentrePickerSheet({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<TestCentrePickerSheet> createState() => _TestCentrePickerSheetState();
}

class _TestCentrePickerSheetState extends State<TestCentrePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UkTestCentre> _results = UkTestCentres.all;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
    _filter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _searchController.text.trim();
    setState(() {
      var list = query.isEmpty ? UkTestCentres.all : UkTestCentres.search(query);
      if (_selectedRegion != null) {
        list = list.where((c) => c.region == _selectedRegion).toList();
      }
      _results = list;
    });
  }

  void _onQueryChanged(String _) => _filter();

  void _selectCentre(UkTestCentre centre) {
    Navigator.of(context).pop(
      SelectedTestCentre(
        name: centre.name,
        postcode: centre.postcode,
        region: centre.region,
        latitude: centre.latitude,
        longitude: centre.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final regions = UkTestCentres.regions;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pick Test Centre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${UkTestCentres.all.length} official DVSA test centres — search by name, postcode or region.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search name, postcode or region…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filter();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _RegionChip(
                      label: 'All',
                      selected: _selectedRegion == null,
                      onTap: () {
                        setState(() => _selectedRegion = null);
                        _filter();
                      },
                    ),
                    ...regions.map(
                      (r) => _RegionChip(
                        label: r,
                        selected: _selectedRegion == r,
                        onTap: () {
                          setState(() => _selectedRegion =
                              _selectedRegion == r ? null : r);
                          _filter();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_results.length} result${_results.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching test centres found.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final centre = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              centre.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${centre.region} · ${centre.postcode}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => _selectCentre(centre),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
