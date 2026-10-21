import 'package:flutter/material.dart';
import 'sales_page.dart';
import 'expenses_page.dart';
import 'stock_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  final List<Vente> historiqueVentes;
  final List<Depense> depenses;
  final List<Produit> produits;

  const ReportsPage({
    Key? key,
    required this.historiqueVentes,
    required this.depenses,
    required this.produits,
  }) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _searchArticleQuery = '';

  Future<void> _selectionnerIntervalleDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _dateDebut != null && _dateFin != null
          ? DateTimeRange(start: _dateDebut!, end: _dateFin!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }

  List<Vente> get _ventesFiltrees {
    return widget.historiqueVentes.where((v) {
      if (_dateDebut != null && _dateFin != null) {
        final debut = DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day);
        final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
        return v.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            v.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  List<Depense> get _depensesFiltrees {
    return widget.depenses.where((d) {
      if (_dateDebut != null && _dateFin != null) {
        final debut = DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day);
        final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
        return d.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            d.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  double get totalCA => _ventesFiltrees.fold(0, (sum, v) => sum + v.total);
  double get totalDepenses => _depensesFiltrees.fold(0, (sum, d) => sum + d.montant);
  double get beneficeNet => totalCA - totalDepenses;

  Future<void> _imprimerBilanFinancier() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BILAN FINANCIER & RAPPORTS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Chiffre d\'Affaires : $totalCA FCFA'),
            pw.Text('Total Dépenses : $totalDepenses FCFA'),
            pw.Text('Bénéfice Net : $beneficeNet FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _imprimerSyntheseArticles(Map<String, Map<String, dynamic>> articlesMap) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SYNTHÈSE DES ARTICLES VENDUS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Article', 'Quantité', 'Prix Unitaire', 'Total'],
              data: articlesMap.values.map((item) => [
                item['nom'],
                item['quantite'].toString(),
                '${item['prixVente']} FCFA',
                '${item['total']} FCFA',
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de la synthèse des articles
    final Map<String, Map<String, dynamic>> syntheseArticles = {};
    for (var vente in _ventesFiltrees) {
      for (var item in vente.articles) {
        final nom = item.nomProduit;
        final qte = item.quantite;
        final total = item.total;

        if (syntheseArticles.containsKey(nom)) {
          syntheseArticles[nom]!['quantite'] += qte;
          syntheseArticles[nom]!['total'] += total;
        } else {
          syntheseArticles[nom] = {
            'nom': nom,
            'quantite': qte,
            'prixVente': item.prixVente,
            'total': total,
          };
        }
      }
    }

    final articlesAffiches = syntheseArticles.values.where((item) {
      return (item['nom'] as String).toLowerCase().contains(_searchArticleQuery.toLowerCase());
    }).toList();

    String periodeTexte = (_dateDebut != null && _dateFin != null)
        ? 'Du ${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year} au ${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
        : 'Toutes les périodes';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rapports, Bilan & Synthèse Articles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.cyan.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Bilan Financier', icon: Icon(Icons.analytics)),
              Tab(text: 'Synthèse des Articles', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Sélecteur de date manuel partagé
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Période : $periodeTexte', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton.icon(
                    onPressed: () => _selectionnerIntervalleDate(context),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: const Text('Sélectionner dates'),
                  ),
                  if (_dateDebut != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: () => setState(() { _dateDebut = null; _dateFin = null; }),
                      tooltip: 'Réinitialiser',
                    ),
                ],
              ),
              const SizedBox(height: 15),

              Expanded(
                child: TabBarView(
                  children: [
                    // Onglet 1 : Bilan Financier
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildCard('Chiffre d\'Affaires', '$totalCA FCFA', Colors.green)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildCard('Total Dépenses', '$totalDepenses FCFA', Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildCard('Bénéfice Net', '$beneficeNet FCFA', Colors.blue, fullWidth: true),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade800, foregroundColor: Colors.white),
                            icon: const Icon(Icons.print),
                            label: const Text('Imprimer le Bilan Financier'),
                            onPressed: _imprimerBilanFinancier,
                          ),
                        ),
                      ],
                    ),

                    // Onglet 2 : Synthèse des Articles (avec bouton d'impression)
                    Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchArticleQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un article...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                            icon: const Icon(Icons.print),
                            label: const Text('Imprimer la Synthèse Articles'),
                            onPressed: () => _imprimerSyntheseArticles(syntheseArticles),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: articlesAffiches.isEmpty
                              ? const Center(child: Text('Aucun article trouvé.', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: articlesAffiches.length,
                                  itemBuilder: (context, index) {
                                    final item = articlesAffiches[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(item['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('Quantité vendue : ${item['quantite']} | PU : ${item['prixVente']} FCFA'),
                                        trailing: Text('${item['total']} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}