import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pet_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../services/poison_database_service.dart';
import '../../pawbook/providers/pet_provider.dart';
import 'poisoning_risk_assessment_screen.dart';

class PoisoningDetectionInputScreen extends StatefulWidget {
  const PoisoningDetectionInputScreen({Key? key}) : super(key: key);

  @override
  State<PoisoningDetectionInputScreen> createState() =>
      _PoisoningDetectionInputScreenState();
}

class _PoisoningDetectionInputScreenState
    extends State<PoisoningDetectionInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _substanceController = TextEditingController();
  final _amountController = TextEditingController();
  final _poisonService = PoisonDatabaseService();

  PetModel? _selectedPet;
  PoisonSubstanceModel? _selectedPoison;
  List<PoisonSubstanceModel> _searchResults = [];
  List<String> _selectedSymptoms = [];
  DateTime _incidentTime = DateTime.now();
  bool _isSearching = false;

  final List<String> _commonSymptoms = [
    'Vomiting',
    'Diarrhea',
    'Drooling',
    'Lethargy',
    'Loss of appetite',
    'Difficulty breathing',
    'Seizures',
    'Tremors',
    'Weakness',
    'Pale gums',
    'Rapid heartbeat',
    'Collapse',
    'Hyperactivity',
    'Confusion',
    'Abdominal pain',
    'Mouth burns',
    'Swelling',
  ];

  @override
  void dispose() {
    _substanceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _searchPoisons(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _poisonService.searchPoisons(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectPoison(PoisonSubstanceModel poison) {
    setState(() {
      _selectedPoison = poison;
      _substanceController.text = poison.name;
      _searchResults = [];
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _selectIncidentTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_incidentTime),
      );

      if (time != null) {
        setState(() {
          _incidentTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _proceedToAssessment() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    if (_selectedPoison == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and select a poison substance')),
      );
      return;
    }

    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoisoningRiskAssessmentScreen(
          pet: _selectedPet!,
          poison: _selectedPoison!,
          symptoms: _selectedSymptoms,
          amountIngested: _amountController.text,
          incidentTime: _incidentTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Poisoning Detection'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emergency Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[700]!, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If your pet is showing severe symptoms, call your vet immediately!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pet Selection
            _buildSectionHeader('Select Pet', Icons.pets),
            const SizedBox(height: 12),
            if (!petProvider.hasPets)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No pets found. Please add a pet first.'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: petProvider.pets.map((pet) {
                  final isSelected = _selectedPet?.id == pet.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPet = pet),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[700] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pet.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[800],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Poison Substance Search
            _buildSectionHeader('What Did Your Pet Ingest?', Icons.search),
            const SizedBox(height: 12),
            TextFormField(
              controller: _substanceController,
              decoration: InputDecoration(
                labelText: 'Search poison substance',
                hintText: 'e.g., Chocolate, Grapes, Ibuprofen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _selectedPoison != null
                    ? Icon(Icons.check_circle, color: Colors.green[700])
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (value) => _searchPoisons(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a substance name';
                }
                return null;
              },
            ),

            // Search Results
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final poison = _searchResults[index];
                    return ListTile(
                      leading: Icon(
                        _getCategoryIcon(poison.category),
                        color: _getRiskColor(poison.defaultRiskLevel),
                      ),
                      title: Text(poison.name),
                      subtitle: Text(poison.categoryName),
                      trailing: _getRiskBadge(poison.defaultRiskLevel),
                      onTap: () => _selectPoison(poison),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Amount Ingested
            _buildSectionHeader('How Much Was Ingested?', Icons.scale),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g., Small piece, 2 tablets, Entire bar...',
                prefixIcon: const Icon(Icons.scale),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please specify the amount ingested';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Incident Time
            _buildSectionHeader('When Did This Happen?', Icons.access_time),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectIncidentTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_incidentTime.toString().substring(0, 16)} (${_getTimeSinceIncident()})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symptoms Selection
            _buildSectionHeader('What Symptoms Are You Seeing?', Icons.medical_services),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () => _toggleSymptom(symptom),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red[700] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      symptom,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_selectedSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${_selectedSymptoms.length} symptom(s) selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _proceedToAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Assess Risk & Get First Aid Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.red[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(PoisonCategory category) {
    switch (category) {
      case PoisonCategory.toxicFoods:
        return Icons.fastfood;
      case PoisonCategory.plants:
        return Icons.local_florist;
      case PoisonCategory.medicines:
        return Icons.medication;
      case PoisonCategory.chemicals:
        return Icons.science;
      case PoisonCategory.householdItems:
        return Icons.home;
    }
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green[700]!;
      case RiskLevel.moderate:
        return Colors.orange[700]!;
      case RiskLevel.high:
        return Colors.deepOrange[700]!;
      case RiskLevel.emergency:
        return Colors.red[700]!;
    }
  }

  Widget _getRiskBadge(RiskLevel level) {
    String text;
    switch (level) {
      case RiskLevel.low:
        text = 'LOW';
        break;
      case RiskLevel.moderate:
        text = 'MOD';
        break;
      case RiskLevel.high:
        text = 'HIGH';
        break;
      case RiskLevel.emergency:
        text = 'EMERG';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRiskColor(level),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTimeSinceIncident() {
    final duration = DateTime.now().difference(_incidentTime);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }
}
