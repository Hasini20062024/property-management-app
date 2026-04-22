import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPropertyScreen extends StatefulWidget {
  final String propertyId;
  final String title;
  final String rent;
  final String description;
  final String contact;

  const EditPropertyScreen({
    super.key,
    required this.propertyId,
    required this.title,
    required this.rent,
    required this.description,
    required this.contact,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late TextEditingController titleController;
  late TextEditingController rentController;
  late TextEditingController descriptionController;
  late TextEditingController contactController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    rentController = TextEditingController(text: widget.rent);
    descriptionController = TextEditingController(text: widget.description);
    contactController = TextEditingController(text: widget.contact);
  }

  Future<void> updateProperty() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty || contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).update({
        'title': titleController.text.trim(),
        'rent': rentController.text.trim(),
        'description': descriptionController.text.trim(),
        'contact': contactController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
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
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
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
              color: Color(0xFFF1F5F9),
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
                        TextField(
                          controller: rentController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Rent (Optional)',
                            prefixIcon: Icon(Icons.currency_rupee_rounded),
                          ),
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
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : updateProperty,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Update Property', style: TextStyle(fontSize: 16)),
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
