import '../../../services/poison_database_service.dart';

/// Helper function to seed the poison database with default substances
/// Call this once during initial app setup
Future<void> seedPoisonDatabase() async {
  final service = PoisonDatabaseService();

  print('🌱 Starting poison database seeding...');

  try {
    await service.seedPoisonDatabase();
    print('✅ Poison database seeded successfully!');
    print('📊 Added default poison substances:');
    print('   • Toxic Foods: Chocolate, Grapes, Onions, Xylitol');
    print('   • Plants: Lilies, Sago Palm');
    print('   • Medicines: Ibuprofen, Paracetamol');
    print('   • Chemicals: Antifreeze, Bleach');
    print('   • Household Items: Batteries');
  } catch (e) {
    print('❌ Error seeding poison database: $e');
  }
}
