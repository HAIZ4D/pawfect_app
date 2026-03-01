import '../models/poison_substance_model.dart';
import '../models/pet_model.dart';

class RiskAssessmentResult {
  final RiskLevel assessedRiskLevel;
  final String riskDescription;
  final List<String> immediateActions;
  final bool requiresEmergencyVet;
  final String severityExplanation;

  const RiskAssessmentResult({
    required this.assessedRiskLevel,
    required this.riskDescription,
    required this.immediateActions,
    required this.requiresEmergencyVet,
    required this.severityExplanation,
  });
}

class RiskAssessmentEngine {
  /// Assess risk level based on poison substance, pet details, and symptoms
  RiskAssessmentResult assessRisk({
    required PoisonSubstanceModel poison,
    required PetModel pet,
    required List<String> observedSymptoms,
    required String amountIngested,
    required Duration timeSinceIngestion,
  }) {
    RiskLevel baseRisk = poison.defaultRiskLevel;
    List<String> actions = [];
    bool emergencyVet = poison.requiresImmediateVetVisit;

    // Adjust risk based on symptoms
    final int symptomCount = observedSymptoms.length;
    final bool hasSevereSymptoms = _hasSevereSymptoms(observedSymptoms);

    // Risk modifiers
    if (hasSevereSymptoms) {
      baseRisk = RiskLevel.emergency;
      emergencyVet = true;
    } else if (symptomCount >= 3 && baseRisk != RiskLevel.emergency) {
      baseRisk = _escalateRisk(baseRisk);
    }

    // Time-sensitive adjustments
    if (timeSinceIngestion.inMinutes < 30 && baseRisk == RiskLevel.emergency) {
      actions.add('ACT NOW - Within first 30 minutes, treatment is most effective');
    }

    // Pet-specific factors
    final String petSize = _categorizePetSize(pet.weight);
    if (petSize == 'small' && baseRisk != RiskLevel.low) {
      actions.add('Small pet - higher risk of severe effects');
    }

    // Amount ingested assessment
    final String amountRisk = _assessAmount(amountIngested);
    if (amountRisk == 'large' && baseRisk != RiskLevel.emergency) {
      baseRisk = _escalateRisk(baseRisk);
    }

    // Build immediate actions list
    actions.addAll(_getImmediateActions(baseRisk, poison, hasSevereSymptoms));

    // Generate descriptions
    final String riskDesc = _getRiskDescription(baseRisk);
    final String severityExp = _generateSeverityExplanation(
      poison: poison,
      symptoms: observedSymptoms,
      amount: amountIngested,
      petSize: petSize,
      timeSince: timeSinceIngestion,
    );

    return RiskAssessmentResult(
      assessedRiskLevel: baseRisk,
      riskDescription: riskDesc,
      immediateActions: actions,
      requiresEmergencyVet: emergencyVet,
      severityExplanation: severityExp,
    );
  }

  bool _hasSevereSymptoms(List<String> symptoms) {
    final severeSymptoms = [
      'seizures',
      'collapse',
      'difficulty breathing',
      'unconscious',
      'severe bleeding',
      'extreme weakness',
      'not responsive',
      'coma',
    ];

    return symptoms.any((symptom) =>
        severeSymptoms.any((severe) => symptom.toLowerCase().contains(severe)));
  }

  RiskLevel _escalateRisk(RiskLevel current) {
    switch (current) {
      case RiskLevel.low:
        return RiskLevel.moderate;
      case RiskLevel.moderate:
        return RiskLevel.high;
      case RiskLevel.high:
        return RiskLevel.emergency;
      case RiskLevel.emergency:
        return RiskLevel.emergency;
    }
  }

  String _categorizePetSize(double? weight) {
    if (weight == null) return 'unknown';
    if (weight < 10) return 'small';
    if (weight < 25) return 'medium';
    return 'large';
  }

  String _assessAmount(String amount) {
    final lowerAmount = amount.toLowerCase();
    if (lowerAmount.contains('large') || lowerAmount.contains('entire') || lowerAmount.contains('whole')) {
      return 'large';
    } else if (lowerAmount.contains('small') || lowerAmount.contains('tiny') || lowerAmount.contains('bit')) {
      return 'small';
    }
    return 'medium';
  }

  List<String> _getImmediateActions(
    RiskLevel risk,
    PoisonSubstanceModel poison,
    bool hasSevereSymptoms,
  ) {
    List<String> actions = [];

    if (hasSevereSymptoms) {
      actions.add('🚨 CALL EMERGENCY VET IMMEDIATELY - Life threatening');
      actions.add('Prepare to transport pet now');
      return actions;
    }

    switch (risk) {
      case RiskLevel.emergency:
        actions.add('🚨 EMERGENCY - Contact vet immediately');
        actions.add('Do not wait for symptoms to worsen');
        actions.add('Prepare to go to emergency vet now');
        break;
      case RiskLevel.high:
        actions.add('⚠️ HIGH RISK - Call vet immediately for guidance');
        actions.add('Prepare for immediate vet visit');
        actions.add('Monitor symptoms closely');
        break;
      case RiskLevel.moderate:
        actions.add('⚠️ Contact vet for advice');
        actions.add('Monitor pet closely for next 24 hours');
        actions.add('Prepare to visit vet if symptoms develop');
        break;
      case RiskLevel.low:
        actions.add('Monitor pet at home');
        actions.add('Contact vet if unusual symptoms appear');
        actions.add('Keep Pet Poison Helpline number ready');
        break;
    }

    return actions;
  }

  String _getRiskDescription(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return 'Low Risk - Monitor at home. Watch for any unusual behavior.';
      case RiskLevel.moderate:
        return 'Moderate Risk - Close monitoring required. Prepare for potential vet visit.';
      case RiskLevel.high:
        return 'High Risk - Immediate vet consultation required. Do not delay.';
      case RiskLevel.emergency:
        return 'EMERGENCY - Urgent veterinary care needed NOW. This is life-threatening.';
    }
  }

  String _generateSeverityExplanation({
    required PoisonSubstanceModel poison,
    required List<String> symptoms,
    required String amount,
    required String petSize,
    required Duration timeSince,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Risk Assessment:');
    buffer.writeln('');
    buffer.writeln('Substance: ${poison.name}');
    buffer.writeln('Base Risk Level: ${poison.riskLevelName}');
    buffer.writeln('');

    if (symptoms.isNotEmpty) {
      buffer.writeln('Observed Symptoms (${symptoms.length}):');
      for (var symptom in symptoms) {
        buffer.writeln('• $symptom');
      }
      buffer.writeln('');
    }

    buffer.writeln('Amount Ingested: $amount');
    buffer.writeln('Pet Size: $petSize');
    buffer.writeln('Time Since Ingestion: ${timeSince.inMinutes} minutes ago');
    buffer.writeln('');

    if (poison.requiresImmediateVetVisit) {
      buffer.writeln('⚠️ This substance REQUIRES immediate veterinary attention.');
    }

    if (poison.antidote != null) {
      buffer.writeln('');
      buffer.writeln('Antidote Available: ${poison.antidote}');
      buffer.writeln('(Must be administered by veterinarian)');
    }

    return buffer.toString();
  }
}
