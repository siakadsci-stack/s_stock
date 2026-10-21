import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Produit {
  String id;
  String nom;
  String categorie;
  double prixAchat;
  double prixVente;
  int quantite;
  int alerteQuantite;

  Produit({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.prixAchat,
    required this.prixVente,
    required this.quantite,
    required this.alerteQuantite,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorie': categorie,
      'prixAchat': prixAchat,
      'prixVente': prixVente,
      'quantite': quantite,
      'alerteQuantite': alerteQuantite,
    };
  }

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      categorie: json['categorie'] ?? '',
      prixAchat: (json['prixAchat'] ?? 0).toDouble(),
      prixVente: (json['prixVente'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 0,
      alerteQuantite: json['alerteQuantite'] ?? 5,
    );
  }
}

class StockPage extends StatefulWidget {
  final List<Produit> produits;
  final Function(Produit) onProduitAjoute;
  final Function(Produit) onProduitModifie;
  final Function(String) onProduitSupprime;

  const StockPage({
    Key? key,
    required this.produits,
    required this.onProduitAjoute,
    required this.onProduitModifie,
    required this.onProduitSupprime,
  }) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _nomController = TextEditingController();
  final _catController = TextEditingController();
  final _paController = TextEditingController();
  final _pvController = TextEditingController();
  final _qteController = TextEditingController();
  final _alerteController = TextEditingController();
  String _recherche = '';

  Future<void> _imprimerStock() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÉTAT ACTUEL DU STOCK', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Nom', 'Catégorie', 'Stock', 'Prix Vente'],
              data: widget.produits.map((p) => [p.nom, p.categorie, p.quantite.toString(), '${p.prixVente} FCFA']).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _afficherFormulaire([Produit? produitExistant]) {
    if (produitExistant != null) {
      _nomController.text = produitExistant.nom;
      _catController.text = produitExistant.categorie;
      _paController.text = produitExistant.prixAchat.toString();
      _pvController.text = produitExistant.prixVente.toString();
      _qteController.text = produitExistant.quantite.toString();
      _alerteController.text = produitExistant.alerteQuantite.toString();
    } else {
      _nomController.clear();
      _catController.clear();
      _paController.clear();
      _pvController.clear();
      _qteController.clear();
      _alerteController.text = '5';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(produitExistant == null ? 'Ajouter un Produit' : 'Modifier le Produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: _catController, decoration: const InputDecoration(labelText: 'Catégorie')),
              TextField(controller: _paController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix d\'achat')),
              TextField(controller: _pvController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix de vente')),
              TextField(controller: _qteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité')),
              TextField(controller: _alerteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil Alerte')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_nomController.text.isNotEmpty) {
                if (produitExistant == null) {
                  widget.onProduitAjoute(Produit(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nom: _nomController.text,
                    categorie: _catController.text,
                    prixAchat: double.tryParse(_paController.text) ?? 0,
                    prixVente: double.tryParse(_pvController.text) ?? 0,
                    quantite: int.tryParse(_qteController.text) ?? 0,
                    alerteQuantite: int.tryParse(_alerteController.text) ?? 5,
                  ));
                } else {
                  produitExistant.nom = _nomController.text;
                  produitExistant.categorie = _catController.text;
                  produitExistant.prixAchat = double.tryParse(_paController.text) ?? 0;
                  produitExistant.prixVente = double.tryParse(_pvController.text) ?? 0;
                  produitExistant.quantite = int.tryParse(_qteController.text) ?? 0;
                  produitExistant.alerteQuantite = int.tryParse(_alerteController.text) ?? 5;
                  widget.onProduitModifie(produitExistant);
                }
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produitsFiltres = widget.produits.where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Stocks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.print), tooltip: 'Imprimer État du Stock', onPressed: _imprimerStock),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _recherche = val),
              decoration: const InputDecoration(labelText: 'Rechercher un produit en stock...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: produitsFiltres.length,
                itemBuilder: (context, index) {
                  final p = produitsFiltres[index];
                  bool alerte = p.quantite <= p.alerteQuantite;
                  return Card(
                    color: alerte ? Colors.red.shade50 : Colors.white,
                    child: ListTile(
                      title: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cat : ${p.categorie} | Stock : ${p.quantite} | Prix : ${p.prixVente} FCFA'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _afficherFormulaire(p)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => widget.onProduitSupprime(p.id)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _afficherFormulaire(),
      ),
    );
  }
}