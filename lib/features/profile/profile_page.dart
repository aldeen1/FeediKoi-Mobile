import 'dart:io';
import 'package:feedikoi/shared/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? 'Novy Sofyantoro';
      _emailController.text = prefs.getString('profile_email') ?? 'aksanabastala45@gmail.com';
      _phoneController.text = prefs.getString('profile_phone') ?? '+62881-0276-59304';
      String? imagePath = prefs.getString('profile_image');
      if (imagePath != null) {
        _image = File(imagePath);
      }
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_email', _emailController.text);
    await prefs.setString('profile_phone', _phoneController.text);
    if (_image != null) {
      await prefs.setString('profile_image', _image!.path);
    }
  }

  Future<void> _pickImage() async {
    try {
      if (!mounted) return;
      final selectedSource = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (selectedSource == null) return;

      bool permissionGranted = false;
      if (selectedSource == ImageSource.camera) {
        final status = await Permission.camera.request();
        permissionGranted = status.isGranted;
        if (!permissionGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to take a photo')),
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        permissionGranted = status.isGranted;
        if (!permissionGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photos permission is required to pick an image')),
          );
          return;
        }
      }

      final XFile? selectedFile = await _picker.pickImage(
        source: selectedSource,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (selectedFile != null) {
        setState(() {
          _image = File(selectedFile.path);
        });
        await _saveProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isEditing) {
              _saveProfile();
            }
            _isEditing = !_isEditing;
          });
        },
        child: Icon(_isEditing ? Icons.save : Icons.edit),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 164,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null
                      ? FileImage(_image!) as ImageProvider
                      : const AssetImage('assets/images/avatar_placeholder.png'),
                    child: _image == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            CustomCard(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                backgroundColor: Colors.grey[100],
                children: [
                  CustomCard(children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Rumah Singgah \nKoi Farm",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              )
                            ),
                          ),
                          const SizedBox(width: 56),
                          Expanded(
                            child: _isEditing
                              ? TextField(
                                  controller: _phoneController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    _phoneController.text,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                          )
                        ],
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _isEditing
                        ? TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          )
                        : Text(_nameController.text),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _isEditing
                        ? TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          )
                        : Text(_emailController.text),
                    ),
                  ]),
                  CustomCard(children: [
                    Padding(padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Lokasi Mitra :", style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        )
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded),
                          SizedBox(width: 8,),
                          Text("Jalan Jati, RT 008, rw 004, Dusun \nCempaka, Desa Pondokkelor, Kec. \nPaiton, Kab.Probolinggo")
                        ],
                      ),
                    )
                  ]),
                  CustomCard(children: [
                    Padding(padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Contact Person :", style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        )
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded),
                          SizedBox(width: 8,),
                          Text("Faris +62823-4055-2152")
                        ],
                      ),
                    )
                  ]),
            ])
          ],
        ),
      ),
    );
  }}