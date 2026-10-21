import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'magasin_model.dart';

class MagasinSettingsPage extends StatefulWidget {
  final Magasin magasin;
  final VoidCallback onMagasinModifie;

  const MagasinSettingsPage({Key? key, required this.magasin, required this.onMagasinModifie}) : super(key: key);

  @override
  State<MagasinSettingsPage> createState() => _MagasinSettingsPageState();
}

class _MagasinSettingsPageState extends State<MagasinSettingsPage> {
  late TextEditingController _nomController;
  late TextEditingController _contactController;
  late TextEditingController _adresseController;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.magasin.nomMagasin);
    _contactController = TextEditingController(text: widget.magasin.contact);
    _adresseController = TextEditingController(text: widget.magasin.adresse);
    _logoBase64 = widget.magasin.logo;
  }

  Future<void> _selectionnerLogoOrdinateur() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List bytesImage = result.files.single.bytes!;
      setState(() {
        _logoBase64 = base64Encode(bytesImage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo chargé avec succès depuis l\'ordinateur !'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres du Magasin & Logo'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom du Magasin')),
            TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact / Téléphone')),
            TextField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse')),
            const SizedBox(height: 20),
            const Text('Logo du Magasin (depuis l\'ordinateur)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  onPressed: _selectionnerLogoOrdinateur,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choisir une image...'),
                ),
                const SizedBox(width: 15),
                if (_logoBase64 != null && _logoBase64!.isNotEmpty)
                  const Text('Logo sélectionné ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else
                  const Text('Aucun logo choisi', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                setState(() {
                  widget.magasin.nomMagasin = _nomController.text;
                  widget.magasin.contact = _contactController.text;
                  widget.magasin.adresse = _adresseController.text;
                  widget.magasin.logo = _logoBase64 ?? '';
                });
                widget.onMagasinModifie();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres enregistrés avec succès !')));
              },
              child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}