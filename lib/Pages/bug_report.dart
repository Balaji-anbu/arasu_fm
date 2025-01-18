import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BugReportingPage extends StatefulWidget {
  @override
  _BugReportingPageState createState() => _BugReportingPageState();
}

class _BugReportingPageState extends State<BugReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Bugreports').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'email': _emailController.text.isNotEmpty ? _emailController.text : null,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bug report submitted successfully!')),
        );
        // Clear the form
        _titleController.clear();
        _descriptionController.clear();
        _emailController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit bug report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Report Bug',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'metropolis',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Icon(
            Icons.bug_report,
            color: Colors.teal,
            size: 34,
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'We value your feedback!',
              content: 'If you encounter any issues, please let us know so we can improve your experience.',
            ),
            _buildTextFieldCard(
              title: 'Bug Title',
              controller: _titleController,
              hint: 'Enter the title of the bug',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title for the bug.';
                }
                return null;
              },
            ),
            _buildTextFieldCard(
              title: 'Bug Description',
              controller: _descriptionController,
              hint: 'Describe the bug in detail',
              maxLines: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the bug.';
                }
                return null;
              },
            ),
            _buildTextFieldCard(
              title: 'Your Email (optional)',
              controller: _emailController,
              hint: 'Enter your email (optional)',
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    !RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+\$").hasMatch(value)) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitBugReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Submit Bug Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'metropolis',
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, String? content, Widget? child}) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            if (content != null) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'metropolis',
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    int? maxLines,
    required String? Function(String?) validator,
  }) {
    return _buildSectionCard(
      title: title,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.greenAccent), // Green text color for input
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'metropolis', color: Colors.greenAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
