import 'package:flutter/material.dart';
import 'caisse_tresorerie_model.dart';
import 'auth_model.dart';

class CaisseTresoreriePage extends StatefulWidget {
  final List<MouvementCaisse> mouvements;
  final Function(MouvementCaisse) onMouvementAjoute;
  final Utilisateur utilisateurActif;

  const CaisseTresoreriePage({Key? key, required this.mouvements, required this.onMouvementAjoute, required this.utilisateurActif}) : super(key: key);

  @override
  State<CaisseTresoreriePage> createState() => _CaisseTresoreriePageState();
}

class _CaisseTresoreriePageState extends State<CaisseTresoreriePage> {
  double get _soldeActuel {
    double entres = widget.mouvements.where((m) => m.type == 'Versement' || m.type == 'Entrée').fold(0.0, (s, m) => s + m.montant);
    double sorties = widget.mouvements.where((m) => m.type == 'Retrait' || m.type == 'Sortie').fold(0.0, (s, m) => s + m.montant);
    return entres - sorties;
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
                // BLOCAGE SI RETRAIT > SOLDE CAISSE
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
      appBar: AppBar(title: const Text('Trésorerie & Caisse'), backgroundColor: Colors.blueGrey),
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
                  const Text('Solde Actuel en Caisse', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('${_soldeActuel.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                itemCount: widget.mouvements.length,
                itemBuilder: (context, index) {
                  final m = widget.mouvements.reversed.toList()[index];
                  bool estEntree = m.type == 'Versement' || m.type == 'Entrée';
                  return Card(
                    child: ListTile(
                      title: Text(m.motif, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.type} | Auteur : ${m.auteur}'),
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