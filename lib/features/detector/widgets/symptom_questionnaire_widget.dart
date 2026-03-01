import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/symptom_model.dart';
import '../data/symptoms_database.dart';

/// Dynamic symptom questionnaire widget
/// Allows users to select symptoms from categorized list
class SymptomQuestionnaireWidget extends StatefulWidget {
  final Function(List<SymptomModel>) onSymptomsChanged;
  final List<SymptomModel>? initialSymptoms;

  const SymptomQuestionnaireWidget({
    super.key,
    required this.onSymptomsChanged,
    this.initialSymptoms,
  });

  @override
  State<SymptomQuestionnaireWidget> createState() =>
      _SymptomQuestionnaireWidgetState();
}

class _SymptomQuestionnaireWidgetState
    extends State<SymptomQuestionnaireWidget> {
  final List<SymptomModel> _selectedSymptoms = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.initialSymptoms != null) {
      _selectedSymptoms.addAll(widget.initialSymptoms!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        _buildSymptomsList(),
      ],
    );
  }

  /// Category filter chips
  Widget _buildCategoryFilter() {
    final categories = SymptomsDatabase.getAllCategories();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _selectedCategory == null,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = null;
            });
          },
          selectedColor: PawfectColors.pawfectOrange.withOpacity(0.3),
          checkmarkColor: PawfectColors.pawfectOrange,
        ),
        ...categories.map((category) {
          return FilterChip(
            label: Text(category),
            selected: _selectedCategory == category,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? category : null;
              });
            },
            selectedColor: PawfectColors.pawfectOrange.withOpacity(0.3),
            checkmarkColor: PawfectColors.pawfectOrange,
          );
        }),
      ],
    );
  }

  /// Symptoms list with checkboxes
  Widget _buildSymptomsList() {
    final symptoms = _selectedCategory != null
        ? SymptomsDatabase.getSymptomsByCategory(_selectedCategory!)
        : SymptomsDatabase.getAllSymptoms();

    if (symptoms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No symptoms available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Group by category if showing all
    if (_selectedCategory == null) {
      final categories = SymptomsDatabase.getAllCategories();
      return Column(
        children: categories.map((category) {
          final categorySymptoms =
              SymptomsDatabase.getSymptomsByCategory(category);
          return _buildCategorySection(category, categorySymptoms);
        }).toList(),
      );
    }

    // Show single category
    return _buildSymptomItems(symptoms);
  }

  /// Category section with expandable list
  Widget _buildCategorySection(
    String category,
    List<SymptomModel> symptoms,
  ) {
    final selectedCount =
        symptoms.where((s) => _isSymptomSelected(s)).length;

    return ExpansionTile(
      title: Row(
        children: [
          _getCategoryIcon(category),
          const SizedBox(width: 8),
          Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (selectedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      children: [
        _buildSymptomItems(symptoms),
      ],
    );
  }

  /// Symptom items with checkboxes
  Widget _buildSymptomItems(List<SymptomModel> symptoms) {
    return Column(
      children: symptoms.map((symptom) {
        final isSelected = _isSymptomSelected(symptom);

        return CheckboxListTile(
          title: Text(symptom.name),
          subtitle: symptom.description != null
              ? Text(
                  symptom.description!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          value: isSelected,
          activeColor: PawfectColors.pawfectOrange,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.removeWhere((s) => s.id == symptom.id);
              }
            });
            widget.onSymptomsChanged(_selectedSymptoms);
          },
        );
      }).toList(),
    );
  }

  /// Check if symptom is selected
  bool _isSymptomSelected(SymptomModel symptom) {
    return _selectedSymptoms.any((s) => s.id == symptom.id);
  }

  /// Get category icon
  Icon _getCategoryIcon(String category) {
    IconData iconData;

    switch (category.toLowerCase()) {
      case 'behavioral':
        iconData = Icons.psychology;
        break;
      case 'digestive':
        iconData = Icons.restaurant;
        break;
      case 'respiratory':
        iconData = Icons.air;
        break;
      case 'skin & coat':
        iconData = Icons.pets;
        break;
      case 'urinary':
        iconData = Icons.water_drop;
        break;
      case 'neurological':
        iconData = Icons.psychology;
        break;
      case 'physical':
        iconData = Icons.accessibility_new;
        break;
      default:
        iconData = Icons.medical_services;
    }

    return Icon(iconData, size: 20, color: PawfectColors.pawfectOrange);
  }
}
