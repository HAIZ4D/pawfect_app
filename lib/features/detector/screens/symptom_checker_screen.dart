import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/pet_model.dart';
import '../../../models/symptom_model.dart';
import '../data/symptoms_database.dart';
import 'diagnosis_result_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  final PetModel? selectedPet;

  const SymptomCheckerScreen({super.key, this.selectedPet});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selectedSymptoms = {};
  String _selectedCategory = 'All';
  final List<SymptomModel> _allSymptoms = SymptomsDatabase.getAllSymptoms();

  List<SymptomModel> get _filteredSymptoms {
    if (_selectedCategory == 'All') {
      return _allSymptoms;
    }
    return _allSymptoms
        .where((symptom) => symptom.category == _selectedCategory)
        .toList();
  }

  void _toggleSymptom(String symptomId) {
    setState(() {
      if (_selectedSymptoms.contains(symptomId)) {
        _selectedSymptoms.remove(symptomId);
      } else {
        _selectedSymptoms.add(symptomId);
      }
    });
  }

  void _analyzeSymptoms() {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one symptom',
            style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: PawfectColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosisResultScreen(
          selectedSymptomIds: _selectedSymptoms.toList(),
          petName: widget.selectedPet?.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text(
          'Symptom Checker',
          style: PawfectTextStyles.h3,
        ),
        backgroundColor: PawfectColors.pawfectOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Pet Info Header (if pet selected)
          if (widget.selectedPet != null) _buildPetHeader(),

          // Category Filter
          _buildCategoryFilter(),

          // Selected Symptoms Count
          _buildSelectedCount(),

          // Symptoms List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSymptoms.length,
              itemBuilder: (context, index) {
                final symptom = _filteredSymptoms[index];
                return _buildSymptomCard(symptom);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAnalyzeButton(),
    );
  }

  Widget _buildPetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: PawfectColors.primaryGradient,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.selectedPet!.imageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.selectedPet!.getDecodedImage(),
                  )
                : const Icon(Icons.pets, color: PawfectColors.pawfectOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checking symptoms for:',
                  style: PawfectTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedPet!.name,
                  style: PawfectTextStyles.h4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...SymptomsDatabase.getAllCategories()];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              backgroundColor: Colors.white,
              selectedColor: PawfectColors.pawfectOrange,
              labelStyle: PawfectTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : PawfectColors.textBody,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? PawfectColors.pawfectOrange
                    : PawfectColors.borderLight,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _selectedSymptoms.isEmpty
          ? Colors.transparent
          : PawfectColors.pawfectOrange.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedSymptoms.length} symptom${_selectedSymptoms.length != 1 ? 's' : ''} selected',
            style: PawfectTextStyles.bodyMedium.copyWith(
              color: _selectedSymptoms.isEmpty
                  ? PawfectColors.textHint
                  : PawfectColors.pawfectOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_selectedSymptoms.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _selectedSymptoms.clear());
              },
              child: Text(
                'Clear All',
                style: PawfectTextStyles.bodyMedium.copyWith(
                  color: PawfectColors.pawfectOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(SymptomModel symptom) {
    final isSelected = _selectedSymptoms.contains(symptom.id);

    Color severityColor;
    switch (symptom.severity) {
      case SeverityLevel.emergency:
        severityColor = PawfectColors.error;
        break;
      case SeverityLevel.severe:
        severityColor = const Color(0xFFF57C00);
        break;
      case SeverityLevel.moderate:
        severityColor = PawfectColors.warning;
        break;
      default:
        severityColor = PawfectColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? PawfectColors.pawfectOrange
              : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: isSelected ? 4 : 0,
      child: InkWell(
        onTap: () => _toggleSymptom(symptom.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PawfectColors.pawfectOrange
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? PawfectColors.pawfectOrange
                        : PawfectColors.borderLight,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Symptom Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            symptom.name,
                            style: PawfectTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? PawfectColors.pawfectOrange
                                  : PawfectColors.textBody,
                            ),
                          ),
                        ),
                        // Severity indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      symptom.description,
                      style: PawfectTextStyles.bodySmall.copyWith(
                        color: PawfectColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _selectedSymptoms.isEmpty ? null : _analyzeSymptoms,
          style: ElevatedButton.styleFrom(
            backgroundColor: PawfectColors.pawfectOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: PawfectColors.borderLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            'Analyze Symptoms',
            style: PawfectTextStyles.button,
          ),
        ),
      ),
    );
  }
}
