import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Depense {
  final String id;
  String motif;
  double montant;
  String categorie;
  DateTime date;
  bool verrouille;

  Depense({required this.id, required this.motif, required this.montant, required this.categorie, required this.date, this.verrouille = false});

  Map<String, dynamic> toJson() => {'id': id, 'motif': motif, 'montant': montant, 'categorie': categorie, 'date': date.toIso8601String(), 'verrouille': verrouille};

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
        id: json['id'] ?? '',
        motif: json['motif'] ?? '',
        montant: (json['montant'] ?? 0).toDouble(),
        categorie: json['categorie'] ?? 'Divers',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        verrouille: json['verrouille'] ?? false,
      );
}

class ExpensesPage extends StatefulWidget {
  final List<Depense> depenses;
  final Function(Depense) onDepenseAjoutee;
  final Function(String) onDepenseSupprimee;

  const ExpensesPage({Key? key, required this.depenses, required this.onDepenseAjoutee, required this.onDepenseSupprimee}) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  DateTime? _dateDebut;
  DateTime? _dateFin;

  Future<void> _selectionnerIntervalleDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }

  List<Depense> get _depensesFiltrees {
    return widget.depenses.where((d) {
      if (_dateDebut != null && _dateFin != null) {
        final debut = DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day);
        final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
        return d.date.isAfter(debut.subtract(const Duration(seconds: 1))) && d.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  double get _totalDepensesFiltrees => _depensesFiltrees.fold(0, (sum, d) => sum + d.montant);

  Future<void> _imprimerDepenses() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÉTAT DES DÉPENSES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Date', 'Motif', 'Catégorie', 'Montant'],
              data: _depensesFiltrees.map((d) => ['${d.date.day}/${d.date.month}/${d.date.year}', d.motif, d.categorie, '${d.montant} FCFA']).toList(),
            ),
            pw.SizedBox(height: 15),
            pw.Text('Total Dépenses : $_totalDepensesFiltrees FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _ajouterDepenseDialog() {
    final motifController = TextEditingController();
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: motifController, decoration: const InputDecoration(labelText: 'Motif')),
            TextField(controller: montantController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant (FCFA)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              double? montant = double.tryParse(montantController.text);
              if (motifController.text.isNotEmpty && montant != null && montant > 0) {
                widget.onDepenseAjoutee(Depense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  motif: motifController.text,
                  montant: montant,
                  categorie: 'Session',
                  date: DateTime.now(),
                  verrouille: false,
                ));
                setState(() {});
                Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Dépenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.print, color: Colors.white), onPressed: _imprimerDepenses),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtrer par date', style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _selectionnerIntervalleDate(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Sélectionner dates'),
                ),
                if (_dateDebut != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: () => setState(() { _dateDebut = null; _dateFin = null; }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Total Dépenses Sélectionnées', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('$_totalDepensesFiltrees FCFA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _depensesFiltrees.isEmpty
                  ? const Center(child: Text('Aucune dépense trouvée.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _depensesFiltrees.length,
                      itemBuilder: (context, index) {
                        final d = _depensesFiltrees.reversed.toList()[index];
                        return Card(
                          child: ListTile(
                            title: Text(d.motif, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${d.montant} FCFA | Date : ${d.date.day}/${d.date.month}/${d.date.year}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                widget.onDepenseSupprimee(d.id);
                                setState(() {});
                              },
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
        onPressed: _ajouterDepenseDialog,
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter Dépense'),
      ),
    );
  }
}