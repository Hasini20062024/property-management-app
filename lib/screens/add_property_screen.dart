import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final titleController = TextEditingController();
  final rentController = TextEditingController();
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();

  Uint8List? imageBytes;
  String? base64Image;

  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  String rentType = 'Per Month';

  final List<String> rentTypes = ['Per Month', 'Per Day', 'Per Year'];

  Widget _glassOrb({
    required double size,
    required List<Color> colors,
    required double top,
    required double right,
  }) {
    return Positioned(
      top: top,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();

      setState(() {
        imageBytes = bytes;
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> addProperty() async {
    final rentText = rentController.text.trim();
    final parsedRent = rentText.isEmpty ? null : int.tryParse(rentText);

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        contactController.text.isEmpty ||
        addressController.text.isEmpty ||
        cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (parsedRent == null && rentText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid rent')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('properties').add({
        'title': titleController.text.trim(),
        'rent': parsedRent,
        'rentType': parsedRent == null ? null : rentType,
        'description': descriptionController.text.trim(),
        'contact': contactController.text.trim(),
        'location': cityController.text.trim(),
        'address': addressController.text.trim(),
        'imageBase64': base64Image,
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available',
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    rentController.dispose();
    descriptionController.dispose();
    contactController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: Stack(
        children: [
          _glassOrb(
            size: 220,
            top: -90,
            right: -60,
            colors: [
              Color(0x4D38BDF8),
              Color(0x242563EB),
            ],
          ),
          _glassOrb(
            size: 180,
            top: 220,
            right: -80,
            colors: [
              Color(0x3814B8A6),
              Color(0x190EA5E9),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppPalette.background,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Property Title',
                            prefixIcon: Icon(Icons.home_work_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: rentController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Rent (Optional)',
                                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: rentType,
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: rentTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                onChanged: (value) {
                                  setState(() => rentType = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Full Address',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: pickImage,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(imageBytes!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppPalette.mutedText),
                                      SizedBox(height: 8),
                                      Text('Tap to select image', style: TextStyle(color: AppPalette.mutedText)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : addProperty,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Add Property', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
