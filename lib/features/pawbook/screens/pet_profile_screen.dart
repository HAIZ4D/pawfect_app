import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_medical_history_screen.dart';
import 'poisoning_incidents_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final PetModel pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late PetModel _currentPet;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPetScreen(pet: _currentPet),
      ),
    );

    if (result == true && mounted) {
      // Reload pet data
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final updatedPet = await petProvider.getPet(_currentPet.id!);
      if (updatedPet != null && mounted) {
        setState(() {
          _currentPet = updatedPet;
        });
      }
    }
  }

  void _viewMedicalHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetMedicalHistoryScreen(pet: _currentPet),
      ),
    );
  }

  void _viewPoisoningIncidents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoisoningIncidentsScreen(pet: _currentPet),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Pet', style: PawfectTextStyles.h3),
        content: Text(
          'Are you sure you want to delete ${_currentPet.name}? This action cannot be undone.',
          style: PawfectTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: PawfectTextStyles.bodyLarge.copyWith(
                color: PawfectColors.textHint,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PawfectColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: PawfectTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final success = await petProvider.deletePet(_currentPet.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_currentPet.name} deleted successfully',
                style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: PawfectColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                petProvider.errorMessage ?? 'Failed to delete pet',
                style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: PawfectColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pet Name and Species
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),

                  // Basic Info Card
                  _buildInfoCard(
                    title: 'Basic Information',
                    children: [
                      _buildInfoRow(Icons.pets, 'Species', _currentPet.species),
                      _buildInfoRow(Icons.category, 'Breed', _currentPet.breed),
                      _buildInfoRow(Icons.wc, 'Gender', _currentPet.gender),
                      _buildInfoRow(Icons.cake, 'Age', _currentPet.getAge()),
                      if (_currentPet.color != null)
                        _buildInfoRow(Icons.palette, 'Color', _currentPet.color!),
                      if (_currentPet.weight != null)
                        _buildInfoRow(Icons.monitor_weight, 'Weight', '${_currentPet.weight} kg'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Additional Info Card
                  if (_currentPet.microchipId != null || _currentPet.notes != null)
                    _buildInfoCard(
                      title: 'Additional Information',
                      children: [
                        if (_currentPet.microchipId != null)
                          _buildInfoRow(Icons.qr_code, 'Microchip ID', _currentPet.microchipId!),
                        if (_currentPet.notes != null)
                          _buildInfoRow(Icons.notes, 'Notes', _currentPet.notes!),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Medical History Button
                  ElevatedButton.icon(
                    onPressed: _viewMedicalHistory,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('View Medical History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PawfectColors.pawfectOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Poisoning History Button
                  ElevatedButton.icon(
                    onPressed: _viewPoisoningIncidents,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('View Poisoning History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PawfectColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleEdit,
                          icon: const Icon(Icons.edit),
                          label: Text('Edit', style: PawfectTextStyles.button.copyWith(
                            color: PawfectColors.pawfectOrange,
                          )),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: PawfectColors.pawfectOrange, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleDelete,
                          icon: const Icon(Icons.delete),
                          label: Text('Delete', style: PawfectTextStyles.button.copyWith(
                            color: PawfectColors.error,
                          )),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: PawfectColors.error, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: PawfectColors.pawfectOrange,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _currentPet.imageBase64 != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _currentPet.getDecodedImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: PawfectColors.primaryGradient,
                ),
                child: const Center(
                  child: Icon(
                    Icons.pets,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentPet.name,
                  style: PawfectTextStyles.h1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentPet.species,
                  style: PawfectTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentPet.breed,
            style: PawfectTextStyles.h4.copyWith(
              color: PawfectColors.pawfectOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PawfectTextStyles.h4,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PawfectColors.pawfectCream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: PawfectColors.pawfectOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: PawfectTextStyles.bodySmall.copyWith(
                    color: PawfectColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: PawfectTextStyles.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medical Records',
                style: PawfectTextStyles.h4,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to add medical record screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Medical records coming soon!',
                        style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: PawfectColors.info,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add', style: PawfectTextStyles.buttonSmall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PawfectColors.pawfectOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 50,
                  color: PawfectColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  'No medical records yet',
                  style: PawfectTextStyles.bodyMedium.copyWith(
                    color: PawfectColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
