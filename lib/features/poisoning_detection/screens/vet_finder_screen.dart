import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VetFinderScreen extends StatefulWidget {
  const VetFinderScreen({Key? key}) : super(key: key);

  @override
  State<VetFinderScreen> createState() => _VetFinderScreenState();
}

class _VetFinderScreenState extends State<VetFinderScreen> {
  bool _isLoading = false;
  final List<VetClinic> _vetClinics = [
    VetClinic(
      name: 'Emergency Veterinary Hospital',
      address: '123 Main Street',
      phone: '(555) 123-4567',
      isOpen24Hours: true,
      distance: 1.2,
    ),
    VetClinic(
      name: 'City Animal Clinic',
      address: '456 Oak Avenue',
      phone: '(555) 234-5678',
      isOpen24Hours: false,
      distance: 2.5,
    ),
    VetClinic(
      name: '24/7 Pet Emergency Center',
      address: '789 Elm Road',
      phone: '(555) 345-6789',
      isOpen24Hours: true,
      distance: 3.1,
    ),
  ];

  void _showVetDetails(VetClinic vet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildVetDetailsSheet(vet),
    );
  }

  Widget _buildVetDetailsSheet(VetClinic vet) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_hospital, color: Colors.red[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vet.isOpen24Hours)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OPEN 24/7',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.location_on, vet.address),
          _buildDetailRow(Icons.phone, vet.phone),
          _buildDetailRow(Icons.directions, '${vet.distance} km away'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchPhone(vet.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red[700]!, width: 2),
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchDirections(),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _launchDirections() async {
    // Open Google Maps search for nearby vet
    final uri = Uri.parse('https://www.google.com/maps/search/emergency+vet+near+me');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Emergency Vet'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Web notice
          if (kIsWeb)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For the best experience finding nearby vets, please use the mobile app.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          // Search Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _launchDirections,
              icon: const Icon(Icons.search),
              label: const Text('Search Emergency Vets Near Me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const Divider(),
          // Vet List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Sample Emergency Vets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _vetClinics.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final vet = _vetClinics[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: vet.isOpen24Hours ? Colors.red[50] : Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: vet.isOpen24Hours ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                  title: Text(
                    vet.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vet.distance} km away'),
                      if (vet.isOpen24Hours)
                        Text(
                          'Open 24/7',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.phone, color: Colors.red[700]),
                    onPressed: () => _launchPhone(vet.phone),
                  ),
                  onTap: () => _showVetDetails(vet),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VetClinic {
  final String name;
  final String address;
  final String phone;
  final bool isOpen24Hours;
  final double distance;

  VetClinic({
    required this.name,
    required this.address,
    required this.phone,
    required this.isOpen24Hours,
    required this.distance,
  });
}
