import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String rentType = "Per Month";

  final List<String> rentTypes = [
    "Per Month",
    "Per Day",
    "Per Year",
  ];

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
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

  /// ➕ ADD PROPERTY
  Future<void> addProperty() async {
    final rentText = rentController.text.trim();
    final parsedRent = rentText.isEmpty ? null : int.tryParse(rentText);

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        contactController.text.isEmpty ||
        addressController.text.isEmpty ||
        cityController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    if (parsedRent == null && rentText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid rent")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection("properties").add({
        "title": titleController.text.trim(),
        "rent": parsedRent,
        "rentType": parsedRent == null ? null : rentType,
        "description": descriptionController.text.trim(),
        "contact": contactController.text.trim(),
        "location": cityController.text.trim(),
        "address": addressController.text.trim(),
        "imageBase64": base64Image,
        "ownerId": FirebaseAuth.instance.currentUser!.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "status": "available",
      });

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🎨 COMMON INPUT STYLE
  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Add Property"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                /// 🏠 TITLE
                TextField(
                  controller: titleController,
                  decoration: inputDecoration("Property Title", Icons.home),
                ),

                const SizedBox(height: 15),

                /// 💰 RENT + TYPE
                Row(
                  children: [

                    Expanded(
                      child: TextField(
                        controller: rentController,
                        keyboardType: TextInputType.number,
                        decoration:
                        inputDecoration("Rent (Optional)", Icons.currency_rupee),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: rentType,
                        decoration: inputDecoration("Type", Icons.category),
                        items: rentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => rentType = value!);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                /// 📝 DESCRIPTION
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: inputDecoration("Description", Icons.description),
                ),

                const SizedBox(height: 15),

                /// 📍 CITY
                TextField(
                  controller: cityController,
                  decoration: inputDecoration("City", Icons.location_city),
                ),

                const SizedBox(height: 15),

                /// 🏡 ADDRESS
                TextField(
                  controller: addressController,
                  decoration: inputDecoration("Full Address", Icons.location_on),
                ),

                const SizedBox(height: 15),

                /// 📞 CONTACT
                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration("Contact Number", Icons.phone),
                ),

                const SizedBox(height: 20),

                /// 🖼 IMAGE BOX
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: imageBytes != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 40),
                        SizedBox(height: 8),
                        Text("Tap to select image"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// 🚀 BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : addProperty,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Add Property",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}