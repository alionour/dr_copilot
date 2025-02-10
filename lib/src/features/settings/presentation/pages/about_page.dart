import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollController.animateTo(
                _scrollController.offset + 50.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollController.animateTo(
                _scrollController.offset - 50.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dr. Copilot',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Dr. Copilot is a comprehensive app designed to assist healthcare professionals in managing their daily tasks efficiently. '
                  'With features like patient management, calendar scheduling, and more, Dr. Copilot aims to streamline your workflow and improve productivity. '
                  'Our goal is to provide a seamless experience that integrates all the essential tools you need in one place, allowing you to focus on what matters most - providing excellent care to your patients.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Key Features:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Patient Management: Easily manage patient information, including medical history, appointments, and treatment plans. '
                  'Our intuitive interface allows you to quickly access and update patient records, ensuring that you always have the most up-to-date information at your fingertips.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '2. Calendar Scheduling: Keep track of your appointments and important events with our integrated calendar. '
                  'Schedule new appointments, set reminders, and view your daily, weekly, or monthly schedule all in one place. '
                  'Our calendar feature helps you stay organized and ensures that you never miss an important appointment.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '3. Notifications: Stay informed with real-time notifications. Receive alerts for upcoming appointments, patient updates, and other important events. '
                  'Our notification system ensures that you are always aware of what\'s happening, allowing you to respond promptly and efficiently.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '4. Privacy and Security: We take the privacy and security of your data seriously. Dr. Copilot is built with robust security measures to protect your information. '
                  'All data is encrypted and securely stored, ensuring that your patient records and personal information are safe from unauthorized access.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '5. User-Friendly Interface: Our app is designed with a user-friendly interface that is easy to navigate. '
                  'Whether you are a tech-savvy professional or someone who prefers simplicity, Dr. Copilot offers an intuitive experience that caters to all users.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'About Us:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Dr. Copilot was developed by a team of healthcare professionals and software engineers who understand the unique challenges faced by medical practitioners. '
                  'Our mission is to create tools that enhance the efficiency and effectiveness of healthcare delivery. We are committed to continuous improvement and regularly update our app with new features and enhancements based on user feedback.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Support:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'For support or more information, please visit our website or contact our support team. We are here to help you make the most of Dr. Copilot and ensure that you have a positive experience using our app.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Thank you for choosing Dr. Copilot. We look forward to supporting you in your journey to provide exceptional care to your patients.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
