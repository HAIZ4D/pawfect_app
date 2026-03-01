import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../models/pet_model.dart';
import '../../pawbook/providers/pet_provider.dart';
import 'illness_detector_camera_screen.dart';
import 'poisoning_detection_screen.dart';

class DetectorHomeScreen extends StatelessWidget {
  const DetectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const CustomAppBar(
        title: 'Detector',
        subtitle: 'AI-powered health analysis',
        icon: Icons.healing_rounded,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Feature Cards
            _buildIllnessDetectorCard(context),
            const SizedBox(height: 16),
            _buildPoisoningDetectorCard(context),
            const SizedBox(height: 24),

            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIllnessDetectorCard(BuildContext context) {
    return InkWell(
      onTap: () => _showPetSelector(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              PawfectColors.pawfectOrange,
              Color(0xFFFF8A00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.health_and_safety,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Illness Detector',
              style: PawfectTextStyles.h2.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze symptoms and get AI-powered health insights',
              style: PawfectTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: PawfectColors.pawfectOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '50+ Symptoms',
                        style: PawfectTextStyles.bodySmall.copyWith(
                          color: PawfectColors.pawfectOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoisoningDetectorCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PoisoningDetectionScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD32F2F),
              Color(0xFFC62828),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.error.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Poisoning Detection',
              style: PawfectTextStyles.h2.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search toxic substances and get emergency guidance',
              style: PawfectTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: PawfectColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '20+ Substances',
                        style: PawfectTextStyles.bodySmall.copyWith(
                          color: PawfectColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawfectColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PawfectColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: PawfectColors.info,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Important Information',
                style: PawfectTextStyles.h5.copyWith(
                  color: PawfectColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'AI-assisted analysis is not a substitute for professional veterinary care',
          ),
          _buildInfoItem(
            'Always consult a veterinarian for proper diagnosis and treatment',
          ),
          _buildInfoItem(
            'In case of emergency, contact your vet or emergency animal hospital immediately',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: PawfectColors.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: PawfectTextStyles.bodyMedium.copyWith(
                color: PawfectColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPetSelector(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (!petProvider.hasPets) {
      // No pets, go directly to AI illness detector
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IllnessDetectorCameraScreen(),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select a Pet',
                style: PawfectTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which pet you want to check',
                style: PawfectTextStyles.bodyMedium.copyWith(
                  color: PawfectColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              ...petProvider.pets.map((pet) => _buildPetOption(context, pet)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IllnessDetectorCameraScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: PawfectColors.borderLight),
                ),
                child: Text(
                  'Continue without selecting a pet',
                  style: PawfectTextStyles.bodyMedium.copyWith(
                    color: PawfectColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetOption(BuildContext context, PetModel pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IllnessDetectorCameraScreen(selectedPet: pet),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: pet.imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: pet.getDecodedImage(),
                      )
                    : const Icon(Icons.pets, color: PawfectColors.pawfectOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: PawfectTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${pet.breed} • ${pet.getAge()}',
                      style: PawfectTextStyles.bodySmall.copyWith(
                        color: PawfectColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: PawfectColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
