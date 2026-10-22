import 'dart:convert';
import 'package:flutter/material.dart';
import 'stock_page.dart';
import 'clients_page.dart';
import 'magasin_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ArticleVendu {
  String produitId;
  String nomProduit;
  double prixVente;
  int quantite;

  ArticleVendu({
    required this.produitId,
    required this.nomProduit,
    required this.prixVente,
    required this.quantite,
  });

  double get total => prixVente * quantite;

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'nomProduit': nomProduit,
        'prixVente': prixVente,
        'quantite': quantite,
      };

  factory ArticleVendu.fromJson(Map<String, dynamic> json) => ArticleVendu(
        produitId: json['produitId'] ?? '',
        nomProduit: json['nomProduit'] ?? '',
        prixVente: (json['prixVente'] ?? 0).toDouble(),
        quantite: json['quantite'] ?? 0,
      );
}

class Vente {
  String id;
  DateTime date;
  List<ArticleVendu> articles;
  double total;
  String nomClient;
  String telephoneClient; // Ajout du téléphone pour l'affichage et les documents
  String modePaiement;

  Vente({
    required this.id,
    required this.date,
    required this.articles,
    required this.total,
    required this.nomClient,
    this.telephoneClient = '',
    required this.modePaiement,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'articles': articles.map((a) => a.toJson()).toList(),
        'total': total,
        'nomClient': nomClient,
        'telephoneClient': telephoneClient,
        'modePaiement': modePaiement,
      };

  factory Vente.fromJson(Map<String, dynamic> json) => Vente(
        id: json['id'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        articles: (json['articles'] as List? ?? []).map((a) => ArticleVendu.fromJson(a)).toList(),
        total: (json['total'] ?? 0).toDouble(),
        nomClient: json['nomClient'] ?? 'Client Divers',
        telephoneClient: json['telephoneClient'] ?? '',
        modePaiement: json['modePaiement'] ?? 'Espèces',
      );
}

class SalesPage extends StatefulWidget {
  final List<Produit> produits;
  final List<Client> clients;
  final List<Vente> historiqueVentes;
  final Magasin magasin;
  final Function(Vente) onNouvelleVente;
  final Function(String) onSupprimerVente;
  final Function(Client) onNouveauClientAuto;

  const SalesPage({
    Key? key,
    required this.produits,
    required this.clients,
    required this.historiqueVentes,
    required this.magasin,
    required this.onNouvelleVente,
    required this.onSupprimerVente,
    required this.onNouveauClientAuto,
  }) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<ArticleVendu> _panier = [];
  String _rechercheArticle = '';
  Client? _clientSelectionne;
  DateTime? _dateDebutHistorique;
  DateTime? _dateFinHistorique;

  Future<void> _selectionnerIntervalleDateHistorique(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateDebutHistorique = picked.start;
        _dateFinHistorique = picked.end;
      });
    }
  }

  List<Vente> get _historiqueVentesFiltre {
    return widget.historiqueVentes.where((v) {
      if (_dateDebutHistorique != null && _dateFinHistorique != null) {
        final debut = DateTime(_dateDebutHistorique!.year, _dateDebutHistorique!.month, _dateDebutHistorique!.day);
        final fin = DateTime(_dateFinHistorique!.year, _dateFinHistorique!.month, _dateFinHistorique!.day, 23, 59, 59);
        return v.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            v.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  // DIALOGUE DE CHOIX : IMPRIMER FACTURE CLIENT OU BON DE LIVRAISON
  void _proposerChoixImpression(Vente vente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de Document'),
        content: const Text('Que souhaitez-vous imprimer ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _imprimerDocument(vente, estBonDeLivraison: true);
            },
            child: const Text('Bon de Livraison'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _imprimerDocument(vente, estBonDeLivraison: false);
            },
            child: const Text('Facture Client'),
          ),
        ],
      ),
    );
  }

  // PRÉVISUALISATION PDF AVEC CHOIX FACTURE OU BON DE LIVRAISON
  void _imprimerDocument(Vente vente, {required bool estBonDeLivraison}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Scaffold(
          appBar: AppBar(
            title: Text(estBonDeLivraison ? 'Prévisualisation - Bon de Livraison' : 'Prévisualisation - Facture Client'),
            backgroundColor: Colors.blueAccent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PdfPreview(
            build: (format) async {
              final pdf = pw.Document();

              pw.ImageProvider? logoImage;
              if (widget.magasin.logo.isNotEmpty) {
                try {
                  final decodedBytes = base64Decode(widget.magasin.logo);
                  logoImage = pw.MemoryImage(decodedBytes);
                } catch (_) {}
              }

              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a5,
                  margin: const pw.EdgeInsets.all(20),
                  build: (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (logoImage != null)
                                pw.Container(width: 60, height: 40, child: pw.Image(logoImage))
                              else
                                pw.Text('LOGO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.SizedBox(height: 5),
                              pw.Text(widget.magasin.nomMagasin, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Tél : ${widget.magasin.contact}', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('Adresse : ${widget.magasin.adresse}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                estBonDeLivraison
                                    ? 'BON DE LIVRAISON'
                                    : 'FACTURE N° : ${vente.id.substring(vente.id.length > 5 ? vente.id.length - 5 : 0)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.Text('Date : ${vente.date.day}/${vente.date.month}/${vente.date.year}', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('Client : ${vente.nomClient}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              if (vente.telephoneClient.isNotEmpty)
                                pw.Text('Tél Client : ${vente.telephoneClient}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.SizedBox(height: 10),
                      if (estBonDeLivraison) ...[
                        pw.Center(
                          child: pw.Text('BON DE LIVRAISON (Articles & Quantités)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Table.fromTextArray(
                          headers: ['DESIGNATION ARTICLE', 'QUANTITÉ LIVRÉE'],
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          data: vente.articles
                              .map((a) => [
                                    a.nomProduit,
                                    a.quantite.toString(),
                                  ])
                              .toList(),
                        ),
                      ] else ...[
                        pw.Table.fromTextArray(
                          headers: ['ARTICLE', 'QTE', 'P. UNITAIRE', 'TOTAL'],
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          data: vente.articles
                              .map((a) => [
                                    a.nomProduit,
                                    a.quantite.toString(),
                                    '${a.prixVente.toStringAsFixed(0)} FCFA',
                                    '${a.total.toStringAsFixed(0)} FCFA',
                                  ])
                              .toList(),
                        ),
                      ],
                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 90,
                            height: 45,
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed)),
                            alignment: pw.Alignment.center,
                            child: pw.Text('CACHET', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ),
                          if (!estBonDeLivraison)
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                              child: pw.Text('NET À PAYER : ${vente.total.toStringAsFixed(0)} FCFA',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              return pdf.save();
            },
          ),
        ),
      ),
    );
  }

  void _ajouterArticlePersonnalise(Produit p) {
    final prixController = TextEditingController(text: p.prixVente.toString());
    final qteController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter : ${p.nom} (Stock dispo : ${p.quantite})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: prixController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix de vente')),
            TextField(controller: qteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              double prix = double.tryParse(prixController.text) ?? p.prixVente;
              int qte = int.tryParse(qteController.text) ?? 1;

              if (qte > p.quantite) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Stock insuffisant !', style: TextStyle(color: Colors.red)),
                    content: Text('Impossible de vendre ${qte} unité(s). Il ne reste que ${p.quantite} en stock pour "${p.nom}".'),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                  ),
                );
                return;
              }

              if (qte > 0) {
                setState(() {
                  _panier.add(ArticleVendu(produitId: p.id, nomProduit: p.nom, prixVente: prix, quantite: qte));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter au Panier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPanier = _panier.fold(0, (sum, item) => sum + item.total);
    final produitsFiltres = widget.produits.where((p) => p.nom.toLowerCase().contains(_rechercheArticle.toLowerCase())).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caisse & Historique Ventes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Caisse', icon: Icon(Icons.point_of_sale)),
              Tab(text: 'Historique Ventes', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (val) => setState(() => _rechercheArticle = val),
                          decoration: const InputDecoration(labelText: 'Rechercher un article...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: produitsFiltres.length,
                          itemBuilder: (context, index) {
                            final p = produitsFiltres[index];
                            return Card(
                              child: ListTile(
                                title: Text(p.nom),
                                subtitle: Text('Prix : ${p.prixVente} FCFA | Stock : ${p.quantite}'),
                                trailing: ElevatedButton(
                                  child: const Text('Sélectionner'),
                                  onPressed: () => _ajouterArticlePersonnalise(p),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
                        Autocomplete<Client>(
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) return const Iterable<Client>.empty();
                            return widget.clients.where((c) => c.nom.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          displayStringForOption: (option) => option.nom,
                          onSelected: (selection) => setState(() => _clientSelectionne = selection),
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(hintText: 'Rechercher client...', isDense: true, border: OutlineInputBorder()),
                            );
                          },
                        ),
                        const Divider(),
                        const Text('Panier Actuel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _panier.length,
                            itemBuilder: (context, index) {
                              final item = _panier[index];
                              return ListTile(
                                title: Text(item.nomProduit),
                                subtitle: Text('${item.quantite} x ${item.prixVente} FCFA'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _panier.removeAt(index)),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Text('Total : ${totalPanier.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: _panier.isEmpty
                                ? null
                                : () {
                                    for (var item in _panier) {
                                      final produitAssocie = widget.produits.firstWhere((p) => p.id == item.produitId);
                                      produitAssocie.quantite -= item.quantite;
                                    }

                                    final nouvelleVente = Vente(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      date: DateTime.now(),
                                      articles: List.from(_panier),
                                      total: totalPanier,
                                      nomClient: _clientSelectionne?.nom ?? 'Client Divers',
                                      telephoneClient: _clientSelectionne?.telephone ?? '',
                                      modePaiement: 'Espèces',
                                    );
                                    widget.onNouvelleVente(nouvelleVente);
                                    setState(() {
                                      _panier.clear();
                                      _clientSelectionne = null;
                                    });
                                  },
                            child: const Text('Valider la Vente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Historique avec suppression qui restaure le stock
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Historique des Ventes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: () => _selectionnerIntervalleDateHistorique(context),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: const Text('Dates'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _historiqueVentesFiltre.length,
                      itemBuilder: (context, index) {
                        final v = _historiqueVentesFiltre.reversed.toList()[index];
                        return Card(
                          child: ListTile(
                            title: Text('Vente #${v.id.substring(v.id.length > 5 ? v.id.length - 5 : 0)} - ${v.nomClient} (${v.telephoneClient})'),
                            subtitle: Text('Total : ${v.total} FCFA | Date : ${v.date.day}/${v.date.month}/${v.date.year}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print, color: Colors.blue),
                                  tooltip: 'Imprimer Facture ou Bon de livraison',
                                  onPressed: () => _proposerChoixImpression(v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Restauration de la quantité en stock à la suppression
                                    for (var art in v.articles) {
                                      try {
                                        final p = widget.produits.firstWhere((prod) => prod.id == art.produitId);
                                        p.quantite += art.quantite;
                                      } catch (_) {}
                                    }
                                    widget.onSupprimerVente(v.id);
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
          ],
        ),
      ),
    );
  }
}
