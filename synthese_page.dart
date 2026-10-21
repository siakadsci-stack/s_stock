import 'package:flutter/material.dart';
import 'sales_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SynthesePage extends StatefulWidget {
  final List<Vente> historiqueVentes;
  final VoidCallback onVenteSupprimee;

  const SynthesePage({Key? key, required this.historiqueVentes, required this.onVenteSupprimee}) : super(key: key);

  @override
  State<SynthesePage> createState() => _SynthesePageState();
}

class _SynthesePageState extends State<SynthesePage> {
  DateTime? _dateDebut;
  DateTime? _dateFin;

  Future<void> _selectionnerIntervalleDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
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
        return v.date.isAfter(debut.subtract(const Duration(seconds: 1))) && v.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  // IMPRESSION DE LA SYNTHÈSE AVEC QTÉ, PRIX UNITAIRE ET PRIX TOTAL
  Future<void> _imprimerSyntheseVentes(double totalCA) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SYNTHÈSE DES VENTES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['ARTICLE', 'QUANTITÉ', 'PRIX UNITAIRE', 'PRIX TOTAL'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: _ventesFiltrees.expand((vente) {
                return vente.articles.map((item) => [
                      item.nomProduit,
                      item.quantite.toString(),
                      '${item.prixVente.toStringAsFixed(0)} FCFA',
                      '${item.total.toStringAsFixed(0)} FCFA',
                    ]);
              }).toList(),
            ),
            pw.SizedBox(height: 15),
            pw.Text('Chiffre d\'Affaires Total : ${totalCA.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    double totalCA = _ventesFiltrees.fold(0, (sum, v) => sum + v.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synthèse des Ventes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer la synthèse',
            onPressed: () => _imprimerSyntheseVentes(totalCA),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Période de Synthèse', style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _selectionnerIntervalleDate(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Dates'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Text('Chiffre d\'Affaires', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('$totalCA FCFA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ventesFiltrees.length,
                itemBuilder: (context, index) {
                  final vente = _ventesFiltrees.reversed.toList()[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text('Vente du ${vente.date.day}/${vente.date.month}/${vente.date.year} - ${vente.nomClient}'),
                      subtitle: Text('Total : ${vente.total} FCFA'),
                      children: vente.articles.map((item) {
                        return ListTile(
                          dense: true,
                          title: Text(item.nomProduit),
                          subtitle: Text('Quantité : ${item.quantite} x ${item.prixVente} FCFA'),
                          trailing: Text('Total : ${item.total} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}