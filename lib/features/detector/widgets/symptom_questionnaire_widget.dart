import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/symptom_model.dart';
import '../data/symptoms_database.dart';

/// Dynamic symptom questionnaire widget
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

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _peach = Color(0xFFFFEAD5);

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
        const SizedBox(height: 14),
        _buildSymptomsList(),
      ],
    );
  }

  // ─────────────────────────── Category filter ───────────────────────────
  Widget _buildCategoryFilter() {
    final categories = SymptomsDatabase.getAllCategories();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _categoryChip(label: 'All', category: null, icon: Icons.apps_rounded),
          const SizedBox(width: 8),
          ...categories.expand((c) => [
                _categoryChip(
                  label: c,
                  category: c,
                  icon: _getCategoryIcon(c),
                ),
                const SizedBox(width: 8),
              ]),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required String? category,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _ink : _hairline,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _ink.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? PawfectColors.pawfectOrange
                  : _inkSoft,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _ink,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Symptoms list ───────────────────────────
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
            style: TextStyle(color: _inkSoft),
          ),
        ),
      );
    }

    if (_selectedCategory == null) {
      final categories = SymptomsDatabase.getAllCategories();
      return Column(
        children: categories
            .map((category) => _buildCategorySection(
                  category,
                  SymptomsDatabase.getSymptomsByCategory(category),
                ))
            .toList(),
      );
    }

    return _buildSymptomChips(symptoms);
  }

  Widget _buildCategorySection(
    String category,
    List<SymptomModel> symptoms,
  ) {
    final selectedCount = symptoms.where(_isSymptomSelected).length;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: PawfectColors.pawfectCream.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hairline),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: _inkSoft,
            collapsedIconColor: _inkSoft,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: PawfectColors.pawfectOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (selectedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            children: [_buildSymptomChips(symptoms)],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomChips(List<SymptomModel> symptoms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map(_buildSymptomChip).toList(),
    );
  }

  Widget _buildSymptomChip(SymptomModel symptom) {
    final isSelected = _isSymptomSelected(symptom);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSymptoms.removeWhere((s) => s.id == symptom.id);
          } else {
            _selectedSymptoms.add(symptom);
          }
        });
        widget.onSymptomsChanged(_selectedSymptoms);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PawfectColors.pawfectOrange : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? PawfectColors.pawfectOrange
                : _hairline,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : _inkSoft.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: PawfectColors.pawfectOrange,
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              symptom.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _ink,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSymptomSelected(SymptomModel symptom) {
    return _selectedSymptoms.any((s) => s.id == symptom.id);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'behavioral':
        return Icons.psychology_rounded;
      case 'digestive':
        return Icons.restaurant_rounded;
      case 'respiratory':
        return Icons.air_rounded;
      case 'skin & coat':
        return Icons.pets_rounded;
      case 'urinary':
        return Icons.water_drop_rounded;
      case 'neurological':
        return Icons.auto_awesome_rounded;
      case 'physical':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }
}
