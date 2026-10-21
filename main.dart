import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'magasin_model.dart';
import 'auth_model.dart';
import 'stock_page.dart';
import 'clients_page.dart';
import 'sales_page.dart';
import 'expenses_page.dart';
import 'caisse_tresorerie_page.dart';
import 'caisse_tresorerie_model.dart';
import 'reports_page.dart';
import 'synthese_page.dart';
import 'magasin_selection_page.dart';
import 'magasin_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SStockApp());
}

class SStockApp extends StatelessWidget {
  const SStockApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DS | CAPITAL® - S-STOCK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationController(),
    );
  }
}

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({Key? key}) : super(key: key);

  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  List<Magasin> _magasins = [];
  Magasin? _magasinActif;
  bool _chargement = true;

  final List<Utilisateur> _administrateursApp = [
    Utilisateur(id: 'admin1', nom: 'DS CAPITAL Admin', codePin: '2506', estAdmin: true),
  ];

  @override
  void initState() {
    super.initState();
    _chargerDonneesLocales();
  }

  Future<void> _chargerDonneesLocales() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString('s_stock_magasins_data');

    if (dataJson != null && dataJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(dataJson);
        setState(() {
          _magasins = decoded.map((m) => Magasin.fromJson(m)).toList();
          _chargement = false;
        });
      } catch (e) {
        _initialiserMagasinsParDefaut();
      }
    } else {
      _initialiserMagasinsParDefaut();
    }
  }

  void _initialiserMagasinsParDefaut() {
    setState(() {
      _magasins = [
        Magasin(
          id: 'mag_1',
          nomMagasin: 'Magasin Principal',
          nomGerant: 'Gérant Principal',
          codePin: '0000',
          contact: '+225 00 00 00 00',
          adresse: 'Siège Social',
          logo: '',
          produits: [
            Produit(
              id: 'p1',
              nom: 'Article Démo',
              categorie: 'Général',
              prixAchat: 1000,
              prixVente: 1500,
              quantite: 20,
              alerteQuantite: 5,
            ),
          ],
          clients: [
            Client(id: 'c1', nom: 'Client Divers', telephone: '00000000', adresse: 'Ville'),
          ],
          historiqueVentes: [],
          depenses: [],
          mouvementsCaisse: [],
          utilisateurs: [
            Utilisateur(id: 'u1', nom: 'Gérant Principal', codePin: '0000', estAdmin: true),
          ],
        ),
      ];
      _chargement = false;
    });
    _sauvegarderDonneesLocales();
  }

  Future<void> _sauvegarderDonneesLocales() async {
    final prefs = await SharedPreferences.getInstance();
    final String dataJson = jsonEncode(_magasins.map((m) => m.toJson()).toList());
    await prefs.setString('s_stock_magasins_data', dataJson);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_magasinActif == null) {
      return MagasinSelectionPage(
        magasins: _magasins,
        administrateursApp: _administrateursApp,
        onMagasinSelectionne: (magasin) {
          setState(() {
            _magasinActif = magasin;
          });
        },
        onMagasinAjoute: (nouveauMagasin) {
          setState(() {
            _magasins.add(nouveauMagasin);
          });
          _sauvegarderDonneesLocales();
        },
      );
    }

    return DashboardPage(
      magasin: _magasinActif!,
      onChangerMagasin: () {
        setState(() {
          _magasinActif = null;
        });
      },
      onDonneesModifiees: () {
        setState(() {});
        _sauvegarderDonneesLocales();
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  final Magasin magasin;
  final VoidCallback onChangerMagasin;
  final VoidCallback onDonneesModifiees;

  const DashboardPage({
    Key? key,
    required this.magasin,
    required this.onChangerMagasin,
    required this.onDonneesModifiees,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // 1. Chiffre d'affaires de la session active (depuis la dernière clôture)
  double get chiffreAffairesSessionActive {
    return widget.magasin.historiqueVentes.where((v) {
      if (widget.magasin.derniereClotureDate == null) return true;
      return v.date.isAfter(widget.magasin.derniereClotureDate!);
    }).fold(0.0, (sum, v) => sum + v.total);
  }

  // 2. Dépenses actives non verrouillées de la session
  double get depensesSessionActive {
    return widget.magasin.depenses.where((d) => !d.verrouille).fold(0.0, (sum, d) => sum + d.montant);
  }

  // 3. Solde cumulé en caisse
  double get soldeTresorerieCumule {
    double totalEncaissements = widget.magasin.mouvementsCaisse
        .where((m) => m.type == 'Versement' || m.type == 'Entrée')
        .fold(0.0, (sum, m) => sum + m.montant);
    double totalRetraits = widget.magasin.mouvementsCaisse
        .where((m) => m.type == 'Retrait' || m.type == 'Sortie')
        .fold(0.0, (sum, m) => sum + m.montant);
    return totalEncaissements - totalRetraits;
  }

  // 4. Clôture de session avec vérification (blocage si Dépenses > Ventes)
  void _confirmerClotureSessionDialog() {
    double totalVentes = chiffreAffairesSessionActive;
    double totalDep = depensesSessionActive;

    // RÈGLE : BLOCAGE SI LES DÉPENSES DÉPASSENT LES VENTES DU JOUR
    if (totalDep > totalVentes) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clôture impossible !', style: TextStyle(color: Colors.red)),
          content: Text('Le total des dépenses ($totalDep FCFA) dépasse le chiffre d\'affaires des ventes du jour ($totalVentes FCFA). La clôture est bloquée.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    double reliquatNet = totalVentes - totalDep;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation - Clôture de Journée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total des ventes de la session : ${totalVentes.toStringAsFixed(0)} FCFA'),
            Text('Total des dépenses de la session : ${totalDep.toStringAsFixed(0)} FCFA'),
            const Divider(),
            Text(
              'Reliquat Net à verser en Caisse : ${reliquatNet.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                for (var d in widget.magasin.depenses) {
                  d.verrouille = true;
                }
                widget.magasin.mouvementsCaisse.add(
                  MouvementCaisse(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    type: 'Versement',
                    montant: reliquatNet,
                    motif: 'Clôture session du ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    auteur: widget.magasin.nomGerant,
                  ),
                );
                widget.magasin.derniereClotureDate = DateTime.now();
              });

              widget.onDonneesModifiees();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session clôturée ! Compteur remis à zéro.')));
            },
            child: const Text('Valider la Clôture'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int produitsEnAlerte = widget.magasin.produits.where((p) => p.quantite <= p.alerteQuantite).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.magasin.nomMagasin} - Gérant : ${widget.magasin.nomGerant}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Paramètres Magasin & Logo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MagasinSettingsPage(
                    magasin: widget.magasin,
                    onMagasinModifie: () {
                      setState(() {});
                      widget.onDonneesModifiees();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white),
            tooltip: 'Changer de Magasin',
            onPressed: widget.onChangerMagasin,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenue au ${widget.magasin.nomMagasin}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // BANDEAU DE CLÔTURE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text('Session de vente active', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('Clôturer la Journée'),
                    onPressed: _confirmerClotureSessionDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // RAPPELS
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCard('Ventes Session Active', '${chiffreAffairesSessionActive.toStringAsFixed(0)} FCFA', Icons.point_of_sale, Colors.green),
                    SizedBox(height: isWide ? 0 : 10, width: isWide ? 10 : 0),
                    _buildSummaryCard('Solde Trésorerie (Caisse)', '${soldeTresorerieCumule.toStringAsFixed(0)} FCFA', Icons.account_balance_wallet, Colors.blue),
                    SizedBox(height: isWide ? 0 : 10, width: isWide ? 10 : 0),
                    _buildSummaryCard('Alerte Stock', '$produitsEnAlerte produit(s)', Icons.warning_amber_rounded, Colors.red),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),

            const Text('Modules de Gestion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // GRILLE DES MODULES
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Caisse / Ventes',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesPage(
                          produits: widget.magasin.produits,
                          clients: widget.magasin.clients,
                          historiqueVentes: widget.magasin.historiqueVentes,
                          magasin: widget.magasin,
                          onNouvelleVente: (vente) {
                            setState(() => widget.magasin.historiqueVentes.add(vente));
                            widget.onDonneesModifiees();
                          },
                          onSupprimerVente: (id) {
                            setState(() => widget.magasin.historiqueVentes.removeWhere((v) => v.id == id));
                            widget.onDonneesModifiees();
                          },
                          onNouveauClientAuto: (client) {
                            setState(() => widget.magasin.clients.add(client));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Trésorerie & Caisse',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CaisseTresoreriePage(
                          mouvements: widget.magasin.mouvementsCaisse,
                          onMouvementAjoute: (m) {
                            setState(() => widget.magasin.mouvementsCaisse.add(m));
                            widget.onDonneesModifiees();
                          },
                          utilisateurActif: widget.magasin.utilisateurs.first,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Gestion des Stocks',
                  icon: Icons.inventory_2,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockPage(
                          produits: widget.magasin.produits,
                          onProduitAjoute: (p) {
                            setState(() => widget.magasin.produits.add(p));
                            widget.onDonneesModifiees();
                          },
                          onProduitModifie: (p) {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                          onProduitSupprime: (id) {
                            setState(() => widget.magasin.produits.removeWhere((p) => p.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Gestion Clients',
                  icon: Icons.people,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientsPage(
                          clients: widget.magasin.clients,
                          onClientAjoute: (c) {
                            setState(() => widget.magasin.clients.add(c));
                            widget.onDonneesModifiees();
                          },
                          onClientModifie: (c) {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                          onClientSupprime: (id) {
                            setState(() => widget.magasin.clients.removeWhere((c) => c.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Dépenses',
                  icon: Icons.receipt_long,
                  color: Colors.deepOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpensesPage(
                          depenses: widget.magasin.depenses,
                          onDepenseAjoutee: (d) {
                            setState(() => widget.magasin.depenses.add(d));
                            widget.onDonneesModifiees();
                          },
                          onDepenseSupprimee: (id) {
                            setState(() => widget.magasin.depenses.removeWhere((item) => item.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Rapports & Bilan',
                  icon: Icons.bar_chart,
                  color: Colors.cyan.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsPage(
                          historiqueVentes: widget.magasin.historiqueVentes,
                          depenses: widget.magasin.depenses,
                          produits: widget.magasin.produits,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Synthèse Ventes',
                  icon: Icons.analytics,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SynthesePage(
                          historiqueVentes: widget.magasin.historiqueVentes,
                          onVenteSupprimee: () {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 36, color: color)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}