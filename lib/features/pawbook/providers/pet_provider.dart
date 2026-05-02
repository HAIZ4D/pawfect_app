import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../models/pet_model.dart';
import '../repositories/pet_repository.dart';

/// Provider for managing pet state and operations
class PetProvider extends ChangeNotifier {
  final PetRepository _repository = PetRepository();

  // State variables
  List<PetModel> _pets = [];
  PetModel? _selectedPet;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<PetModel> get pets => _pets;
  PetModel? get selectedPet => _selectedPet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPets => _pets.isNotEmpty;

  /// Get pets count
  int get petsCount => _pets.length;

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Load all pets for the current user
  Future<void> loadPets() async {
    try {
      _setLoading(true);
      _setError(null);
      _pets = await _repository.getUserPets();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load pets: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to real-time pet updates
  Stream<List<PetModel>> getPetsStream() {
    return _repository.getUserPetsStream();
  }

  /// Add a new pet
  ///
  /// Takes a [PetModel] and optional [imageFile]
  /// Returns true if successful, false otherwise
  Future<bool> addPet(PetModel pet, {File? imageFile}) async {
    try {
      _setLoading(true);
      _setError(null);

      final petId = await _repository.addPet(pet, imageFile: imageFile);

      if (petId != null) {
        // Reload pets to get the updated list
        await loadPets();
        return true;
      } else {
        _setError('Failed to add pet');
        return false;
      }
    } catch (e) {
      _setError('Failed to add pet: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing pet
  ///
  /// Takes a [PetModel] and optional [imageFile]
  /// Returns true if successful, false otherwise
  Future<bool> updatePet(PetModel pet, {File? imageFile}) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _repository.updatePet(pet, imageFile: imageFile);

      if (success) {
        // Reload pets to get the updated list
        await loadPets();

        // Update selected pet if it's the one being edited
        if (_selectedPet?.id == pet.id) {
          _selectedPet = pet;
        }

        return true;
      } else {
        _setError('Failed to update pet');
        return false;
      }
    } catch (e) {
      _setError('Failed to update pet: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a pet
  ///
  /// Takes a [petId]
  /// Returns true if successful, false otherwise
  Future<bool> deletePet(String petId) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _repository.deletePet(petId);

      if (success) {
        // Remove from local list
        _pets.removeWhere((pet) => pet.id == petId);

        // Clear selected pet if it's the one being deleted
        if (_selectedPet?.id == petId) {
          _selectedPet = null;
        }

        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete pet');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete pet: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single pet by ID
  ///
  /// Takes a [petId]
  /// Returns [PetModel] if found, null otherwise
  Future<PetModel?> getPet(String petId) async {
    try {
      _setLoading(true);
      _setError(null);

      final pet = await _repository.getPet(petId);

      if (pet != null) {
        _selectedPet = pet;
        notifyListeners();
      }

      return pet;
    } catch (e) {
      _setError('Failed to load pet: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Set the selected pet
  void setSelectedPet(PetModel? pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  /// Search pets by name
  ///
  /// Takes a [query] string
  /// Updates the pets list with search results
  Future<void> searchPets(String query) async {
    try {
      _setLoading(true);
      _setError(null);

      if (query.isEmpty) {
        // If query is empty, load all pets
        await loadPets();
      } else {
        _pets = await _repository.searchPets(query);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to search pets: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter pets by species
  ///
  /// Takes a [species] string (e.g., 'Dog', 'Cat')
  /// Updates the pets list with filtered results
  Future<void> filterPetsBySpecies(String species) async {
    try {
      _setLoading(true);
      _setError(null);

      if (species.isEmpty || species.toLowerCase() == 'all') {
        // If no species filter, load all pets
        await loadPets();
      } else {
        _pets = await _repository.filterPetsBySpecies(species);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to filter pets: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all state
  void clear() {
    _pets = [];
    _selectedPet = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get pets by species (read-only, doesn't modify state)
  List<PetModel> getPetsBySpecies(String species) {
    if (species.isEmpty || species.toLowerCase() == 'all') {
      return _pets;
    }
    return _pets.where((pet) => pet.species.toLowerCase() == species.toLowerCase()).toList();
  }

  /// Get pet statistics
  Map<String, int> getPetStatistics() {
    final stats = <String, int>{};

    for (var pet in _pets) {
      final species = pet.species;
      stats[species] = (stats[species] ?? 0) + 1;
    }

    return stats;
  }
}
