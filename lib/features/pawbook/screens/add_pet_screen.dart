import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';

class AddPetScreen extends StatefulWidget {
  final PetModel? pet; // If provided, this is an edit operation

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String _selectedGender = 'Male';
  DateTime? _selectedBirthdate;
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _speciesList = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];
  final List<String> _genderList = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _initializeWithPet(widget.pet!);
    }
  }

  void _initializeWithPet(PetModel pet) {
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _colorController.text = pet.color ?? '';
    _weightController.text = pet.weight?.toString() ?? '';
    _microchipController.text = pet.microchipId ?? '';
    _notesController.text = pet.notes ?? '';
    _selectedSpecies = pet.species;
    _selectedGender = pet.gender;
    _selectedBirthdate = pet.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: PawfectColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Image Source',
                style: PawfectTextStyles.h4,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: PawfectColors.pawfectOrange),
                title: Text('Camera', style: PawfectTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: PawfectColors.pawfectOrange),
                title: Text('Gallery', style: PawfectTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PawfectColors.pawfectOrange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select pet birthdate',
            style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: PawfectColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final petProvider = Provider.of<PetProvider>(context, listen: false);

    final pet = PetModel(
      id: widget.pet?.id,
      userId: widget.pet?.userId ?? '',
      name: _nameController.text.trim(),
      species: _selectedSpecies,
      breed: _breedController.text.trim(),
      gender: _selectedGender,
      birthdate: _selectedBirthdate!,
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      weight: _weightController.text.trim().isEmpty ? null : double.tryParse(_weightController.text.trim()),
      microchipId: _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageBase64: widget.pet?.imageBase64,
      createdAt: widget.pet?.createdAt,
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.pet != null) {
      // Update existing pet
      success = await petProvider.updatePet(pet, imageFile: _selectedImage);
    } else {
      // Add new pet
      success = await petProvider.addPet(pet, imageFile: _selectedImage);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pet != null ? 'Pet updated successfully!' : 'Pet added successfully!',
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
              petProvider.errorMessage ?? 'Failed to save pet',
              style: PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: PawfectColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pet != null;

    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: LiquidAppBar(
        title: isEdit ? 'Edit Pet' : 'Add New Pet',
        subtitle: isEdit ? 'Update profile' : 'Welcome a new companion',
        icon: Icons.pets_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topInset + 132, 20, 32),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker
                _buildImagePicker(),
                const SizedBox(height: 24),

                // Form Card
                GlassCard(
                  radius: 24,
                  blur: 20,
                  tintOpacity: 0.55,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Pet Name *', 'e.g., Max'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter pet name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Species Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedSpecies,
                        decoration: _inputDecoration('Species *', null),
                        items: _speciesList.map((species) {
                          return DropdownMenuItem(
                            value: species,
                            child: Text(species),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSpecies = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Breed Field
                      TextFormField(
                        controller: _breedController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Breed *', 'e.g., Golden Retriever'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _inputDecoration('Gender *', null),
                        items: _genderList.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Birthdate Picker
                      InkWell(
                        onTap: _selectBirthdate,
                        child: InputDecorator(
                          decoration: _inputDecoration('Birthdate *', null),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedBirthdate == null
                                    ? 'Select birthdate'
                                    : '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}',
                                style: _selectedBirthdate == null
                                    ? PawfectTextStyles.hint
                                    : PawfectTextStyles.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today, color: PawfectColors.pawfectOrange),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Field
                      TextFormField(
                        controller: _colorController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Color', 'e.g., Brown'),
                      ),
                      const SizedBox(height: 16),

                      // Weight Field
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Weight (kg)', 'e.g., 25.5'),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (double.tryParse(value.trim()) == null) {
                              return 'Please enter valid weight';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Microchip ID Field
                      TextFormField(
                        controller: _microchipController,
                        decoration: _inputDecoration('Microchip ID', 'e.g., 123456789'),
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: _inputDecoration('Notes', 'Additional information...'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                GestureDetector(
                  onTap: _isLoading ? null : _handleSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          PawfectColors.pawfectOrange,
                          Color(0xFFFFB347),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: PawfectColors.pawfectOrange.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Pet' : 'Add Pet',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [PawfectColors.cardShadow],
          ),
          child: _selectedImage != null
              ? ClipOval(
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : widget.pet?.imageBase64 != null
                  ? ClipOval(
                      child: widget.pet!.getDecodedImage(),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: PawfectColors.pawfectOrange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: PawfectTextStyles.bodySmall.copyWith(
                            color: PawfectColors.pawfectOrange,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: PawfectTextStyles.label,
      hintStyle: PawfectTextStyles.hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawfectColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawfectColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawfectColors.pawfectOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PawfectColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
