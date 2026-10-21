import 'package:flutter/material.dart';
import 'magasin_model.dart';
import 'auth_model.dart';
import 'stock_page.dart';
import 'admin_page.dart';

class MagasinSelectionPage extends StatefulWidget {
  final List<Magasin> magasins;
  final Function(Magasin) onMagasinSelectionne;
  final Function(Magasin) onMagasinAjoute;
  final List<Utilisateur> administrateursApp;

  const MagasinSelectionPage({
    Key? key,
    required this.magasins,
    required this.onMagasinSelectionne,
    required this.onMagasinAjoute,
    required this.administrateursApp,
  }) : super(key: key);

  @override
  State<MagasinSelectionPage> createState() => _MagasinSelectionPageState();
}

class _MagasinSelectionPageState extends State<MagasinSelectionPage> {
  void _ouvrirAdminProprietaireDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber),
            SizedBox(width: 8),
            Text('Espace Propriétaire (Licence)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez le code PIN principal pour accéder à la gestion des gérants et de la licence :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code PIN Principal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              bool pinValide = pinController.text == '2506' ||
                  widget.administrateursApp.any((admin) => admin.codePin == pinController.text);

              if (pinValide) {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPage(
                      magasins: widget.magasins,
                      onLicenceModifiee: () => setState(() {}),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code PIN Administrateur incorrect ! (Code par défaut : 2506)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  // SÉCURITÉ ADMIN POUR MODIFIER OU SUPPRIMER UN MAGASIN EXISTANT
  void _verifierAdminPourAction(BuildContext context, Magasin magasin, String actionType) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sécurité Admin : $actionType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrez le PIN Administrateur (2506) pour $actionType "${magasin.nomMagasin}" :'),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Code PIN Admin', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (pinController.text == '2506') {
                Navigator.pop(context);
                if (actionType == 'Modifier') {
                  _editerMagasinDialog(context, magasin);
                } else if (actionType == 'Supprimer') {
                  _confirmerSuppressionMagasin(context, magasin);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code PIN Administrateur incorrect !'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _editerMagasinDialog(BuildContext context, Magasin magasin) {
    final nomMagasinController = TextEditingController(text: magasin.nomMagasin);
    final nomGerantController = TextEditingController(text: magasin.nomGerant);
    final codePinController = TextEditingController(text: magasin.codePin);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier : ${magasin.nomMagasin}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomMagasinController, decoration: const InputDecoration(labelText: 'Nom du Magasin')),
            const SizedBox(height: 10),
            TextField(controller: nomGerantController, decoration: const InputDecoration(labelText: 'Nom du Gérant')),
            const SizedBox(height: 10),
            TextField(controller: codePinController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'Code PIN (4 chiffres)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nomMagasinController.text.isNotEmpty && nomGerantController.text.isNotEmpty && codePinController.text.length == 4) {
                setState(() {
                  magasin.nomMagasin = nomMagasinController.text;
                  magasin.nomGerant = nomGerantController.text;
                  magasin.codePin = codePinController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Magasin mis à jour avec succès !')));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppressionMagasin(BuildContext context, Magasin magasin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce Magasin ?'),
        content: Text('Voulez-vous vraiment supprimer "${magasin.nomMagasin}" et toutes ses données associées ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                widget.magasins.remove(magasin);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Magasin supprimé avec succès.')));
            },
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _creerMagasinDialog() {
    final nomMagasinController = TextEditingController();
    final nomGerantController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un Nouveau Magasin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomMagasinController,
              decoration: const InputDecoration(labelText: 'Nom du Magasin (ex: Boutique Abidjan)'),
            ),
            TextField(
              controller: nomGerantController,
              decoration: const InputDecoration(labelText: 'Nom du Gérant'),
            ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Code PIN Gérant (4 chiffres)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (nomMagasinController.text.isNotEmpty &&
                  nomGerantController.text.isNotEmpty &&
                  pinController.text.length == 4) {
                final nouveauMagasin = Magasin(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nomMagasin: nomMagasinController.text,
                  nomGerant: nomGerantController.text,
                  codePin: pinController.text,
                  produits: [
                    Produit(
                      id: '1',
                      nom: 'Article par défaut',
                      categorie: 'Général',
                      prixAchat: 1000,
                      prixVente: 1500,
                      quantite: 10,
                      alerteQuantite: 2,
                    ),
                  ],
                  clients: [],
                  historiqueVentes: [],
                  depenses: [],
                  mouvementsCaisse: [],
                  utilisateurs: [
                    Utilisateur(id: '1', nom: nomGerantController.text, codePin: pinController.text, estAdmin: true),
                  ],
                );

                widget.onMagasinAjoute(nouveauMagasin);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Magasin créé avec succès !')),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _configurerOuOuvrirMagasin(Magasin magasin) {
    final nomGerantController = TextEditingController();
    final pinController = TextEditingController();

    bool nonConfigure = magasin.nomGerant.trim().isEmpty || magasin.nomGerant == 'À configurer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nonConfigure ? 'Configuration - ${magasin.nomMagasin}' : 'Connexion - ${magasin.nomMagasin}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (nonConfigure) ...[
              const Text('Veuillez définir le nom du gérant et son code PIN :', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: nomGerantController,
                decoration: const InputDecoration(labelText: 'Nom du Gérant', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Définir un Code PIN (4 chiffres)', border: OutlineInputBorder()),
              ),
            ] else ...[
              Text('Gérant : ${magasin.nomGerant}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Entrer le Code PIN du Gérant', border: OutlineInputBorder()),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (nonConfigure) {
                if (nomGerantController.text.isNotEmpty && pinController.text.length == 4) {
                  setState(() {
                    magasin.nomGerant = nomGerantController.text;
                    magasin.codePin = pinController.text;
                    if (magasin.utilisateurs.isNotEmpty) {
                      magasin.utilisateurs.first.nom = nomGerantController.text;
                      magasin.utilisateurs.first.codePin = pinController.text;
                    }
                  });
                  Navigator.pop(context);
                  widget.onMagasinSelectionne(magasin);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir un nom et un PIN valide (4 chiffres).')),
                  );
                }
              } else {
                if (pinController.text == magasin.codePin) {
                  Navigator.pop(context);
                  widget.onMagasinSelectionne(magasin);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code PIN incorrect !')),
                  );
                }
              }
            },
            child: Text(nonConfigure ? 'Enregistrer & Ouvrir' : 'Accéder au Magasin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final differenceJours = GestionLicence.dateExpiration.difference(DateTime.now()).inDays;
    bool afficherAlerteLicence = differenceJours <= 7;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _ouvrirAdminProprietaireDialog,
              icon: const Icon(Icons.admin_panel_settings, size: 20),
              label: const Text('Admin / Licence', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO DS | CAPITAL®
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'DS',
                        style: TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const TextSpan(
                        text: ' | ',
                        style: TextStyle(color: Colors.red, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: 'CAPITAL',
                        style: TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -8),
                          child: const Text(
                            '®',
                            style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'La liberté financière à votre portée',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                const Icon(Icons.store, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 8),
                const Text('S-STOCK - MULTI-MAGASINS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Sélectionnez votre magasin ou créez-en un nouveau', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 15),

                // ALERTE LICENCE PREVENTIVE
                if (afficherAlerteLicence)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GestionLicence.estExpire ? Colors.red.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GestionLicence.estExpire ? Colors.red : Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: GestionLicence.estExpire ? Colors.red.shade800 : Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GestionLicence.estExpire
                                ? 'ATTENTION : La licence de l\'application a expiré !'
                                : 'Attention : La licence expire dans $differenceJours jour(s).',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GestionLicence.estExpire ? Colors.red.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                widget.magasins.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Aucun magasin enregistré. Veuillez en créer un.', style: TextStyle(color: Colors.grey)),
                      )
                    : SizedBox(
                        height: 220,
                        child: ListView.builder(
                          itemCount: widget.magasins.length,
                          itemBuilder: (context, index) {
                            final mag = widget.magasins[index];
                            bool aConfigurer = mag.nomGerant.trim().isEmpty || mag.nomGerant == 'À configurer';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.shop, color: Colors.white)),
                                title: Text(mag.nomMagasin, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  aConfigurer ? 'Gérant : Non défini' : 'Gérant : ${mag.nomGerant}',
                                  style: TextStyle(color: aConfigurer ? Colors.orange.shade800 : Colors.black87),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // BOUTON MODIFIER (ADMIN)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      tooltip: 'Modifier Magasin/Gérant',
                                      onPressed: () => _verifierAdminPourAction(context, mag, 'Modifier'),
                                    ),
                                    // BOUTON SUPPRIMER (ADMIN)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      tooltip: 'Supprimer ce Magasin',
                                      onPressed: () => _verifierAdminPourAction(context, mag, 'Supprimer'),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: aConfigurer ? Colors.orange : Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _configurerOuOuvrirMagasin(mag),
                                      child: Text(aConfigurer ? 'Configurer' : 'Ouvrir'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _creerMagasinDialog,
                    icon: const Icon(Icons.add_business, color: Colors.white),
                    label: const Text('Créer un Nouveau Magasin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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