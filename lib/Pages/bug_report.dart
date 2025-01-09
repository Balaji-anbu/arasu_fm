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
          'email':
              _emailController.text.isNotEmpty ? _emailController.text : null,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bug report submitted successfully!')),
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
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: Text(
          'Report Bug',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'metropolis',
              fontWeight: FontWeight.bold),
        ),
        actions: [
          Icon(
            Icons.bug_report,
            color: Colors.teal,
            size: 34,
          ),
          SizedBox(
            width: 20,
          )
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 2, 15, 27), // Dark background
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'We value your feedback!',
                content:
                    'If you encounter any issues, please let us know so we can improve your experience.',
              ),
              _buildSectionCard(
                title: 'Bug Title',
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter the title of the bug',
                    hintStyle: TextStyle(fontFamily: 'metropolis'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title for the bug.';
                    }
                    return null;
                  },
                ),
              ),
              _buildSectionCard(
                title: 'Bug Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Describe the bug in detail',
                    hintStyle: TextStyle(fontFamily: 'metropolis'),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe the bug.';
                    }
                    return null;
                  },
                ),
              ),
              _buildSectionCard(
                title: 'Your Email (optional)',
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email (optional)',
                    hintStyle: TextStyle(fontFamily: 'metropolis'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+\$")
                            .hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: _submitBugReport,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text('Submit Bug Report',
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'metropolis',
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, String? content, Widget? child}) {
    return Card(
      color: Colors.grey[900], // Light color card for contrast
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            if (content != null) ...[
              SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'metropolis',
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ],
            if (child != null) ...[
              SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
