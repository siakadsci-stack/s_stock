import 'package:flutter/material.dart';
import 'auth_model.dart';

class LoginPage extends StatefulWidget {
  final List<Utilisateur> utilisateurs;
  final Function(Utilisateur) onConnexionReussie;
  final Function(Utilisateur) onCaissierAjoute;

  const LoginPage({
    Key? key,
    required this.utilisateurs,
    required this.onConnexionReussie,
    required this.onCaissierAjoute,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Utilisateur? _utilisateurSelectionne;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.utilisateurs.isNotEmpty) {
      _utilisateurSelectionne = widget.utilisateurs.first;
    }
  }

  void _verifierCodePin() {
    if (_utilisateurSelectionne != null) {
      if (_pinController.text == _utilisateurSelectionne!.codePin) {
        widget.onConnexionReussie(_utilisateurSelectionne!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code PIN incorrect !')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcul du nombre de jours restants avant expiration de la licence
    final differenceJours = GestionLicence.dateExpiration.difference(DateTime.now()).inDays;
    bool afficherAlerteLicence = differenceJours <= 7;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 60, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text('S-STOCK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Sélectionnez votre compte', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),

              // ALERTE LICENCE (Si reste moins d'une semaine ou expiré)
              if (afficherAlerteLicence)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GestionLicence.estExpire ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GestionLicence.estExpire ? Colors.red : Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: GestionLicence.estExpire ? Colors.red.shade800 : Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          GestionLicence.estExpire
                              ? 'ATTENTION : Votre licence a expiré !'
                              : 'Attention : La licence expire dans $differenceJours jour(s) (${GestionLicence.dateExpiration.day}/${GestionLicence.dateExpiration.month}/${GestionLicence.dateExpiration.year}).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: GestionLicence.estExpire ? Colors.red.shade900 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Liste déroulante des utilisateurs
              DropdownButtonFormField<Utilisateur>(
                value: _utilisateurSelectionne,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Utilisateur'),
                items: widget.utilisateurs.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text('${u.nom} (${u.estAdmin ? "Admin" : "Caissier"})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _utilisateurSelectionne = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Code PIN
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Code PIN (4 chiffres)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _verifierCodePin,
                  child: const Text('Se Connecter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}