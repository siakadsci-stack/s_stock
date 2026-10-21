import 'package:flutter/material.dart';

class Client {
  final String id;
  String nom;
  String telephone;
  String adresse;

  Client({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.adresse,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] ?? '',
        nom: json['nom'] ?? '',
        telephone: json['telephone'] ?? '',
        adresse: json['adresse'] ?? '',
      );
}

class ClientsPage extends StatefulWidget {
  final List<Client> clients;
  final Function(Client) onClientAjoute;
  final Function(Client) onClientModifie;
  final Function(String) onClientSupprime;

  const ClientsPage({
    Key? key,
    required this.clients,
    required this.onClientAjoute,
    required this.onClientModifie,
    required this.onClientSupprime,
  }) : super(key: key);

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String _searchQuery = '';

  void _afficherFormulaireAjout(BuildContext context) {
    final nomController = TextEditingController();
    final telController = TextEditingController();
    final adrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              TextField(
                controller: telController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: adrController,
                decoration: const InputDecoration(labelText: 'Adresse / Lieu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomController.text.isNotEmpty) {
                final nouveau = Client(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nomController.text,
                  telephone: telController.text,
                  adresse: adrController.text,
                );
                widget.onClientAjoute(nouveau);
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _afficherFormulaireEdition(BuildContext context, Client client) {
    final nomController = TextEditingController(text: client.nom);
    final telController = TextEditingController(text: client.telephone);
    final adrController = TextEditingController(text: client.adresse);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              TextField(
                controller: telController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: adrController,
                decoration: const InputDecoration(labelText: 'Adresse / Lieu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              client.nom = nomController.text;
              client.telephone = telController.text;
              client.adresse = adrController.text;
              widget.onClientModifie(client);
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsFiltres = widget.clients.where((c) {
      return c.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.telephone.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Clients',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un client (nom ou téléphone)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: clientsFiltres.isEmpty
                  ? const Center(
                      child: Text('Aucun client trouvé',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: clientsFiltres.length,
                      itemBuilder: (context, index) {
                        final client = clientsFiltres[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                client.nom.isNotEmpty
                                    ? client.nom[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                            ),
                            title: Text(client.nom,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Tél : ${client.telephone} | Lieu : ${client.adresse}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _afficherFormulaireEdition(context, client),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    widget.onClientSupprime(client.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _afficherFormulaireAjout(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nouveau Client',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}