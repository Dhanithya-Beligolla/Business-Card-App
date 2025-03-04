import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String username = '';
  String contactName = '';
  String email = '';
  List<Map<String, String>> phoneNumbers = []; // List for multiple phone numbers
  List<Map<String, String>> socialProfiles = [];
  String newPhoneNumber = '';
  String newPhoneLabel = 'Mobile'; // Default label
  String newSocialName = '';
  String newSocialUrl = '';
  bool showQR = false;

  final List<String> phoneLabels = ['Mobile', 'Work', 'Home', 'Custom'];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
      });
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          username = doc['username'] ?? '';
          contactName = doc['contactName'] ?? '';
          phoneNumbers = List<Map<String, String>>.from(doc['phoneNumbers'] ?? []);
          socialProfiles = List<Map<String, String>>.from(doc['social'] ?? []);
        });
      }
    }
  }

  void saveProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (email != user.email) {
        await reauthenticateAndUpdateEmail(user);
      } else {
        await updateFirestore(user);
      }
    }
  }

  Future<void> reauthenticateAndUpdateEmail(User user) async {
    TextEditingController passwordController = TextEditingController();
    bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reauthenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your current password to proceed:'),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email update cancelled')),
      );
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'A verification email has been sent to $email. Please verify it to complete the update.'),
        ),
      );
      await _auth.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to proceed: $e')),
      );
    }
  }

  Future<void> updateFirestore(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'username': username,
      'contactName': contactName,
      'email': email,
      'phoneNumbers': phoneNumbers,
      'social': socialProfiles,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile Updated')),
    );
  }

  void addPhoneNumber() {
    if (newPhoneNumber.isNotEmpty) {
      setState(() {
        phoneNumbers.add({'number': newPhoneNumber, 'label': newPhoneLabel});
        newPhoneNumber = '';
        newPhoneLabel = 'Mobile'; // Reset to default
      });
      saveProfile();
    }
  }

  void deletePhoneNumber(int index) {
    setState(() => phoneNumbers.removeAt(index));
    saveProfile();
  }

  void addSocialProfile() {
    if (newSocialName.isNotEmpty && newSocialUrl.isNotEmpty) {
      setState(() {
        socialProfiles.add({'name': newSocialName, 'url': newSocialUrl});
        newSocialName = '';
        newSocialUrl = '';
      });
      saveProfile();
    }
  }

  void editSocialProfile(int index) async {
    TextEditingController urlController =
        TextEditingController(text: socialProfiles[index]['url']);
    String? newUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${socialProfiles[index]['name']} URL'),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(labelText: 'New URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (newUrl != null && newUrl.isNotEmpty) {
      setState(() {
        socialProfiles[index]['url'] = newUrl;
      });
      saveProfile();
    }
  }

  void deleteSocialProfile(int index) {
    setState(() => socialProfiles.removeAt(index));
    saveProfile();
  }

  String generateVCard() {
    String phoneLines = phoneNumbers
        .map((p) => 'TEL;TYPE=${p['label']?.toUpperCase()}:${p['number']}')
        .join('\n');
    return 'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'N:$contactName\n'
        'EMAIL:$email\n'
        '$phoneLines\n'
        '${socialProfiles.map((s) => 'URL:${s['url']}').join('\n')}\n'
        'END:VCARD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username Field
            TextField(
              onChanged: (value) => username = value,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: username),
            ),
            SizedBox(height: 20),

            // Contact Name Field
            TextField(
              onChanged: (value) => contactName = value,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: contactName),
            ),
            SizedBox(height: 20),

            // Email Field
            TextField(
              onChanged: (value) => email = value,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: email),
            ),
            SizedBox(height: 20),

            // Phone Numbers
            Text('Phone Numbers', style: TextStyle(fontSize: 18)),
            ...phoneNumbers.asMap().entries.map((entry) {
              int idx = entry.key;
              var phone = entry.value;
              return ListTile(
                title: Text('${phone['label']}: ${phone['number']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deletePhoneNumber(idx),
                ),
              );
            }),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => newPhoneNumber = value,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: newPhoneLabel,
                  onChanged: (value) {
                    setState(() => newPhoneLabel = value!);
                  },
                  items: phoneLabels
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ))
                      .toList(),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addPhoneNumber,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Social Profiles
            Text('Social Profiles', style: TextStyle(fontSize: 18)),
            ...socialProfiles.asMap().entries.map((entry) {
              int idx = entry.key;
              var profile = entry.value;
              return ListTile(
                title: Text(profile['name']!),
                subtitle: GestureDetector(
                  onTap: () => launch(profile['url']!),
                  child: Text(profile['url']!, style: TextStyle(color: Colors.blue)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => editSocialProfile(idx),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => deleteSocialProfile(idx),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => newSocialName = value,
                    decoration: InputDecoration(labelText: 'Social Name'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) => newSocialUrl = value,
                    decoration: InputDecoration(labelText: 'URL'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addSocialProfile,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Save Button
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                  CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Curves.easeInOut)),
              child: ElevatedButton(
                onPressed: saveProfile,
                child: Text('Save Profile'),
              ),
            ),
            SizedBox(height: 20),

            // Generate QR Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showQR = !showQR;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                showQR ? 'Hide QR' : 'Generate QR',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            if (showQR)
              Center(
                child: QrImageView(
                  data: generateVCard(),
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}