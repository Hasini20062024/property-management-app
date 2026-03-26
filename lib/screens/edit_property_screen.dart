import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    descriptionController =
        TextEditingController(text: widget.description);
    contactController = TextEditingController(text: widget.contact);
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

  /// 🔄 UPDATE PROPERTY
  Future<void> updateProperty() async {

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        contactController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection("properties")
          .doc(widget.propertyId)
          .update({
        "title": titleController.text.trim(),
        "rent": rentController.text.trim(),
        "description": descriptionController.text.trim(),
        "contact": contactController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated Successfully ✅")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Edit Property"),
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

                /// 💰 RENT
                TextField(
                  controller: rentController,
                  keyboardType: TextInputType.number,
                  decoration:
                      inputDecoration("Rent (Optional)", Icons.currency_rupee),
                ),

                const SizedBox(height: 15),

                /// 📝 DESCRIPTION
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: inputDecoration("Description", Icons.description),
                ),

                const SizedBox(height: 15),

                /// 📞 CONTACT
                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration("Contact Number", Icons.phone),
                ),

                const SizedBox(height: 25),

                /// 🚀 UPDATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : updateProperty,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Update Property",
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