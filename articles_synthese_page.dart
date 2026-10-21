import 'package:flutter/material.dart';

class ArticlesSynthesePage extends StatefulWidget {
  final List<dynamic> historiqueVentes;

  const ArticlesSynthesePage({Key? key, required this.historiqueVentes}) : super(key: key);

  @override
  State<ArticlesSynthesePage> createState() => _ArticlesSynthesePageState();
}

class _ArticlesSynthesePageState extends State<ArticlesSynthesePage> {
  DateTime _dateFiltre = DateTime.now();
  String _modeFiltre = 'Jour';
  String _searchQuery = '';

  void _imprimerRapportArticles(Map<String, Map<String, dynamic>> articlesMap) {
    double grandTotal = articlesMap.values.fold(0.0, (sum, item) => sum + (item['total'] as double));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Impression - Synthèse par Article'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('S-STOCK - SYNTHÈSE DES ARTICLES VENDUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Période : ${_modeFiltre == 'Jour' ? "${_dateFiltre.day}/${_dateFiltre.month}/${_dateFiltre.year}" : "${_dateFiltre.month}/${_dateFiltre.year}"}'),
                Text('Édité le : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                const Divider(),
                Text('Articles différents vendus : ${articlesMap.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('TOTAL CUMULÉ : $grandTotal FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                const Divider(),
                const Text('Détail des quantités et chiffres :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...articlesMap.values.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('• ${item['nom']} : Quantité ${item['quantite']} | PU ${item['prixVente']} FCFA | Total ${item['total']} FCFA'),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impression de la synthèse des articles lancée...')),
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Imprimer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventesFiltrees = widget.historiqueVentes.where((v) {
      if (_modeFiltre == 'Jour') {
        return v.date.year == _dateFiltre.year &&
            v.date.month == _dateFiltre.month &&
            v.date.day == _dateFiltre.day;
      } else {
        return v.date.year == _dateFiltre.year &&
            v.date.month == _dateFiltre.month;
      }
    }).toList();

    final Map<String, Map<String, dynamic>> syntheseArticles = {};
    for (var vente in ventesFiltrees) {
      for (var item in vente.articles) {
        final nom = item.produit.nom as String;
        final qte = item.quantite as int;
        final total = (item.produit.prixVente * qte) as double;

        if (syntheseArticles.containsKey(nom)) {
          syntheseArticles[nom]!['quantite'] += qte;
          syntheseArticles[nom]!['total'] += total;
        } else {
          syntheseArticles[nom] = {
            'nom': nom,
            'quantite': qte,
            'prixVente': item.produit.prixVente,
            'total': total,
          };
        }
      }
    }

    final articlesAffiches = syntheseArticles.values.where((item) {
      return (item['nom'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synthèse par Article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer le rapport des articles',
            onPressed: () => _imprimerRapportArticles(syntheseArticles),
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
                DropdownButton<String>(
                  value: _modeFiltre,
                  items: const [
                    DropdownMenuItem(value: 'Jour', child: Text('Filtrer par Jour')),
                    DropdownMenuItem(value: 'Mois', child: Text('Filtrer par Mois')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _modeFiltre = val);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_modeFiltre == 'Jour'
                      ? '${_dateFiltre.day}/${_dateFiltre.month}/${_dateFiltre.year}'
                      : '${_dateFiltre.month}/${_dateFiltre.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateFiltre,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _dateFiltre = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un article par son nom...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: articlesAffiches.isEmpty
                  ? const Center(child: Text('Aucun article trouvé.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: articlesAffiches.length,
                      itemBuilder: (context, index) {
                        final item = articlesAffiches[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.category, color: Colors.white, size: 20),
                            ),
                            title: Text(item['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Quantité vendue : ${item['quantite']} | PU : ${item['prixVente']} FCFA'),
                            trailing: Text(
                              '${item['total']} FCFA',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                            ),
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