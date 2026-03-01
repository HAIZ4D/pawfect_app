import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/toxic_substance_model.dart';
import '../data/toxic_substances_database.dart';
import 'substance_detail_screen.dart';
import 'report_poisoning_incident_screen.dart';
import '../../poisoning_detection/screens/vet_finder_screen.dart';

class PoisoningDetectionScreen extends StatefulWidget {
  const PoisoningDetectionScreen({super.key});

  @override
  State<PoisoningDetectionScreen> createState() =>
      _PoisoningDetectionScreenState();
}

class _PoisoningDetectionScreenState extends State<PoisoningDetectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<ToxicSubstanceModel> get _filteredSubstances {
    List<ToxicSubstanceModel> substances;

    // Filter by category
    if (_selectedCategory == 'All') {
      substances = ToxicSubstancesDatabase.getAllSubstances();
    } else {
      substances =
          ToxicSubstancesDatabase.getSubstancesByCategory(_selectedCategory);
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      substances = substances.where((substance) {
        return substance.name.toLowerCase().contains(queryLower) ||
            substance.keywords
                .any((keyword) => keyword.toLowerCase().contains(queryLower)) ||
            substance.alternativeNames
                .any((name) => name.toLowerCase().contains(queryLower));
      }).toList();
    }

    return substances;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text(
          'Poisoning Detection',
          style: PawfectTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: PawfectColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Emergency Banner
          _buildEmergencyBanner(),

          // Search Bar
          _buildSearchBar(),

          // Category Filter
          _buildCategoryFilter(),

          // Results Count
          _buildResultsCount(),

          // Substances List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSubstances.length,
              itemBuilder: (context, index) {
                final substance = _filteredSubstances[index];
                return _buildSubstanceCard(substance);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Pet Poisoning Emergency?',
            style: PawfectTextStyles.h4.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Find the nearest veterinary clinic immediately',
            style:
                PawfectTextStyles.bodyMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetFinderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Find Nearest Vet Clinic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: PawfectColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search toxic substances (e.g., chocolate, lily...)',
          hintStyle: PawfectTextStyles.bodyMedium.copyWith(
            color: PawfectColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, color: PawfectColors.error),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: PawfectColors.pawfectCream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...ToxicSubstancesDatabase.getAllCategories()];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: PawfectColors.pawfectCream,
              selectedColor: PawfectColors.error,
              labelStyle: PawfectTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : PawfectColors.textBody,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? PawfectColors.error
                    : PawfectColors.borderLight,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        '${_filteredSubstances.length} substance${_filteredSubstances.length != 1 ? 's' : ''} found',
        style: PawfectTextStyles.bodyMedium.copyWith(
          color: PawfectColors.textHint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubstanceCard(ToxicSubstanceModel substance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Go directly to report incident form
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ReportPoisoningIncidentScreen(substance: substance),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Warning Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: PawfectColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: PawfectColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Substance Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      substance.name,
                      style: PawfectTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      substance.category,
                      style: PawfectTextStyles.bodySmall.copyWith(
                        color: PawfectColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: PawfectColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _showFatalSubstancesDialog() {
    final fatalSubstances = ToxicSubstancesDatabase.getFatalSubstances();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: PawfectColors.error),
            const SizedBox(width: 8),
            Text('Fatal Substances', style: PawfectTextStyles.h4),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These substances are extremely dangerous and can be fatal:',
                style: PawfectTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...fatalSubstances.map(
                (substance) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: PawfectColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          substance.name,
                          style: PawfectTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
