import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';

class PawbookHomeScreen extends StatefulWidget {
  const PawbookHomeScreen({super.key});

  @override
  State<PawbookHomeScreen> createState() => _PawbookHomeScreenState();
}

class _PawbookHomeScreenState extends State<PawbookHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPets());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    await context.read<PetProvider>().loadPets();
  }

  Future<void> _handleSearch(String query) async {
    await context.read<PetProvider>().searchPets(query);
  }

  void _navigateToAddPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    if (result == true) _loadPets();
  }

  void _navigateToPetProfile(PetModel pet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
    );
    if (result == true) _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const CustomAppBar(
        title: 'PawBook',
        subtitle: 'Your pets, beautifully remembered',
        icon: Icons.book_rounded,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPet,
        backgroundColor: PawfectColors.pawfectOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pet'),
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _petListView()),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: TextField(
          controller: _searchController,
          onChanged: _handleSearch,
          decoration: InputDecoration(
            hintText: 'Search by pet name',
            prefixIcon:
                const Icon(Icons.search, color: PawfectColors.pawfectOrange),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PET LIST
  // ─────────────────────────────────────────────
  Widget _petListView() {
    return Consumer<PetProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: PawfectColors.pawfectOrange),
          );
        }

        if (!provider.hasPets) {
          return _emptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: provider.pets.length,
          itemBuilder: (_, i) => _premiumPetCard(provider.pets[i]),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 🌟 PREMIUM PET CARD (BIG PHOTO)
  // ─────────────────────────────────────────────
  Widget _premiumPetCard(PetModel pet) {
    return GestureDetector(
      onTap: () => _navigateToPetProfile(pet),
      child: Container(
        height: 280,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PET IMAGE
              pet.imageBase64 != null
                  ? pet.getDecodedImage()
                  : Container(
                      color: PawfectColors.pawfectCream,
                      child: const Icon(Icons.pets,
                          size: 80, color: PawfectColors.pawfectOrange),
                    ),

              // GRADIENT OVERLAY
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),

              // TEXT CONTENT
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: PawfectTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pet.breed} • ${pet.gender} • ${pet.getAge()}',
                      style: PawfectTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
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

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets,
                size: 90, color: PawfectColors.pawfectOrange),
            const SizedBox(height: 24),
            Text('No pets yet', style: PawfectTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Add your first pet and start their story',
              style: PawfectTextStyles.bodyLarge.copyWith(
                color: PawfectColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
