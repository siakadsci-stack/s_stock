import 'package:flutter/material.dart';
import 'auth_model.dart';
import 'magasin_model.dart';

class AdminPage extends StatefulWidget {
  final List<Magasin> magasins;
  final VoidCallback onLicenceModifiee;

  const AdminPage({
    Key? key,
    required this.magasins,
    required this.onLicenceModifiee,
  }) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Ensemble des IDs de magasins dont le code PIN est rendu visible à l'écran
  final Set<String> _pinsVisibles = {};

  void _modifierGerantDialog(Magasin magasin) {
    final nomController = TextEditingController(text: magasin.nomGerant);
    final pinController = TextEditingController(text: magasin.codePin);
    bool masquerPinSaisie = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Gérant - ${magasin.nomMagasin}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du Gérant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: masquerPinSaisie,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Nouveau Code PIN (4 chiffres)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(masquerPinSaisie ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        masquerPinSaisie = !masquerPinSaisie;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nomController.text.trim().isNotEmpty && pinController.text.length == 4) {
                  setState(() {
                    magasin.nomGerant = nomController.text.trim();
                    magasin.codePin = pinController.text;
                    if (magasin.utilisateurs.isNotEmpty) {
                      magasin.utilisateurs.first.nom = nomController.text.trim();
                      magasin.utilisateurs.first.codePin = pinController.text;
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Accès du gérant mis à jour avec succès !')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir un nom valide et un PIN à 4 chiffres.')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _modifierDateLicenceManuellement() async {
    final nouvelleDate = await showDatePicker(
      context: context,
      initialDate: GestionLicence.dateExpiration,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      helpText: 'Sélectionner la nouvelle date d\'expiration de la licence',
    );

    if (nouvelleDate != null) {
      setState(() {
        GestionLicence.dateExpiration = nouvelleDate;
        widget.onLicenceModifiee();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Licence mise à jour jusqu\'au ${nouvelleDate.day}/${nouvelleDate.month}/${nouvelleDate.year}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Espace Propriétaire - Gérants & Licence',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MODULE DE GESTION DES GÉRANTS ET MAGASINS
            const Text(
              'Gestion des Gérants & Codes PIN des Magasins',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Consultez ou réinitialisez les accès des gérants en cas d\'oubli.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.magasins.length,
              itemBuilder: (context, index) {
                final mag = widget.magasins[index];
                final bool pinEstVisible = _pinsVisibles.contains(mag.id);
                bool aConfigurer = mag.nomGerant.trim().isEmpty || mag.nomGerant == 'À configurer';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.shop, color: Colors.white),
                    ),
                    title: Text(
                      mag.nomMagasin,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aConfigurer ? 'Gérant : Non configuré' : 'Gérant : ${mag.nomGerant}',
                          style: TextStyle(
                            color: aConfigurer ? Colors.orange.shade800 : Colors.black87,
                            fontWeight: aConfigurer ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          aConfigurer
                              ? 'Code PIN : Non défini'
                              : 'Code PIN : ${pinEstVisible ? mag.codePin : "••••"}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!aConfigurer)
                          IconButton(
                            icon: Icon(
                              pinEstVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade700,
                            ),
                            tooltip: pinEstVisible ? 'Masquer le PIN' : 'Afficher le PIN (oubli)',
                            onPressed: () {
                              setState(() {
                                if (pinEstVisible) {
                                  _pinsVisibles.remove(mag.id);
                                } else {
                                  _pinsVisibles.add(mag.id);
                                }
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Modifier le gérant / mot de passe',
                          onPressed: () => _modifierGerantDialog(mag),
                        ),
                        if (widget.magasins.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer ce magasin',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer ce magasin ?'),
                                  content: Text('Voulez-vous supprimer définitivement le magasin "${mag.nomMagasin}" ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          widget.magasins.removeAt(index);
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // MODULE DE GESTION DE LA LICENCE
            const Text(
              'Gestion de la Licence du Logiciel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GestionLicence.estExpire ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: GestionLicence.estExpire ? Colors.red : Colors.green,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        GestionLicence.estExpire ? 'Licence Expirée' : 'Licence Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GestionLicence.estExpire ? Colors.red : Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date d\'expiration : ${GestionLicence.dateExpiration.day}/${GestionLicence.dateExpiration.month}/${GestionLicence.dateExpiration.year}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _modifierDateLicenceManuellement,
                    icon: const Icon(Icons.edit_calendar, color: Colors.white),
                    label: const Text('Changer la date', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}