import 'package:flutter/material.dart';
import 'caisse_tresorerie_model.dart';
import 'auth_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CaisseTresoreriePage extends StatefulWidget {
  final List<MouvementCaisse> mouvements;
  final Function(MouvementCaisse) onMouvementAjoute;
  final Utilisateur utilisateurActif;

  const CaisseTresoreriePage({
    Key? key,
    required this.mouvements,
    required this.onMouvementAjoute,
    required this.utilisateurActif,
  }) : super(key: key);

  @override
  State<CaisseTresoreriePage> createState() => _CaisseTresoreriePageState();
}

class _CaisseTresoreriePageState extends State<CaisseTresoreriePage> {
  DateTime? _dateDebutFiltre;
  DateTime? _dateFinFiltre;

  Future<void> _selectionnerIntervalleDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateDebutFiltre = picked.start;
        _dateFinFiltre = picked.end;
      });
    }
  }

  // Filtrage des mouvements selon l'intervalle de dates choisi
  List<MouvementCaisse> get _mouvementsFiltres {
    return widget.mouvements.where((m) {
      if (_dateDebutFiltre != null && _dateFinFiltre != null) {
        final debut = DateTime(_dateDebutFiltre!.year, _dateDebutFiltre!.month, _dateDebutFiltre!.day);
        final fin = DateTime(_dateFinFiltre!.year, _dateFinFiltre!.month, _dateFinFiltre!.day, 23, 59, 59);
        return m.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            m.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  double get _soldeActuel {
    // Calcul basé sur les mouvements filtrés (ou l'ensemble si aucun filtre de date n'est actif)
    final liste = _mouvementsFiltres;
    double entres = liste.where((m) => m.type == 'Versement' || m.type == 'Entrée').fold(0.0, (s, m) => s + m.montant);
    double sorties = liste.where((m) => m.type == 'Retrait' || m.type == 'Sortie').fold(0.0, (s, m) => s + m.montant);
    return entres - sorties;
  }

  Future<void> _imprimerTresorerie() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÉTAT DE LA TRÉSORERIE & CAISSE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            if (_dateDebutFiltre != null && _dateFinFiltre != null)
              pw.Text(
                'Période du ${_dateDebutFiltre!.day}/${_dateDebutFiltre!.month}/${_dateDebutFiltre!.year} au ${_dateFinFiltre!.day}/${_dateFinFiltre!.month}/${_dateFinFiltre!.year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            pw.SizedBox(height: 5),
            pw.Text('Solde Période : ${_soldeActuel.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Date', 'Type', 'Motif', 'Auteur', 'Montant'],
              data: _mouvementsFiltres.map((m) => [
                '${m.date.day}/${m.date.month}/${m.date.year}',
                m.type,
                m.motif,
                m.auteur,
                '${m.montant} FCFA',
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _ajouterMouvementDialog(String typeMouvement) {
    final motifController = TextEditingController();
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau Mouvement : $typeMouvement'),
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
                if ((typeMouvement == 'Retrait' || typeMouvement == 'Sortie') && montant > _soldeActuel) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Opération bloquée !', style: TextStyle(color: Colors.red)),
                      content: Text('Le montant demandé ($montant FCFA) est supérieur au solde disponible en caisse (${_soldeActuel} FCFA).'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                    ),
                  );
                  return;
                }

                widget.onMouvementAjoute(MouvementCaisse(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  type: typeMouvement,
                  montant: montant,
                  motif: motifController.text,
                  auteur: widget.utilisateurActif.nom,
                ));
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trésorerie & Caisse'),
        backgroundColor: Colors.blueGrey,
        actions: [
          // Bouton de sélection de dates
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            tooltip: 'Filtrer par date',
            onPressed: () => _selectionnerIntervalleDate(context),
          ),
          // Bouton d'impression
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer l\'état de la caisse',
            onPressed: _imprimerTresorerie,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(_dateDebutFiltre != null ? 'Solde Période Sélectionnée' : 'Solde Actuel en Caisse', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('${_soldeActuel.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  if (_dateDebutFiltre != null && _dateFinFiltre != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Du ${_dateDebutFiltre!.day}/${_dateDebutFiltre!.month}/${_dateDebutFiltre!.year} au ${_dateFinFiltre!.day}/${_dateFinFiltre!.month}/${_dateFinFiltre!.year}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _dateDebutFiltre = null;
                        _dateFinFiltre = null;
                      }),
                      child: const Text('Réinitialiser le filtre', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _ajouterMouvementDialog('Entrée'),
                  icon: const Icon(Icons.add),
                  label: const Text('Entrée / Versement'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => _ajouterMouvementDialog('Retrait'),
                  icon: const Icon(Icons.remove),
                  label: const Text('Retrait / Sortie'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _mouvementsFiltres.length,
                itemBuilder: (context, index) {
                  final m = _mouvementsFiltres.reversed.toList()[index];
                  bool estEntree = m.type == 'Versement' || m.type == 'Entrée';
                  return Card(
                    child: ListTile(
                      title: Text(m.motif, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.type} | Date : ${m.date.day}/${m.date.month}/${m.date.year} | Auteur : ${m.auteur}'),
                      trailing: Text('${estEntree ? "+" : "-"}${m.montant} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: estEntree ? Colors.green : Colors.red)),
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
