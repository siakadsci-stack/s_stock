Import 'stock_page.dart';
import 'clients_page.dart';
import 'sales_page.dart';
import 'expenses_page.dart';
import 'caisse_tresorerie_model.dart';
import 'auth_model.dart';

class Magasin {
  String id;
  String nomMagasin;
  String nomGerant;
  String codePin;
  String contact;
  String adresse;
  String logo; // Champ pour le logo/enseigne personnalisé
  List<Produit> produits;
  List<Client> clients;
  List<Vente> historiqueVentes;
  List<Depense> depenses;
  List<MouvementCaisse> mouvementsCaisse;
  List<Utilisateur> utilisateurs;
  DateTime? derniereClotureDate; // Pour verrouiller les dépenses et ventes des sessions passées

  Magasin({
    required this.id,
    required this.nomMagasin,
    required this.nomGerant,
    required this.codePin,
    this.contact = '',
    this.adresse = '',
    this.logo = '',
    required this.produits,
    required this.clients,
    required this.historiqueVentes,
    required this.depenses,
    required this.mouvementsCaisse,
    required this.utilisateurs,
    this.derniereClotureDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomMagasin': nomMagasin,
        'nomGerant': nomGerant,
        'codePin': codePin,
        'contact': contact,
        'adresse': adresse,
        'logo': logo,
        'produits': produits.map((p) => p.toJson()).toList(),
        'clients': clients.map((c) => c.toJson()).toList(),
        'historiqueVentes': historiqueVentes.map((v) => v.toJson()).toList(),
        'depenses': depenses.map((d) => d.toJson()).toList(),
        'mouvementsCaisse': mouvementsCaisse.map((m) => m.toJson()).toList(),
        'utilisateurs': utilisateurs.map((u) => u.toJson()).toList(),
        'derniereClotureDate': derniereClotureDate?.toIso8601String(),
      };

  factory Magasin.fromJson(Map<String, dynamic> json) => Magasin(
        id: json['id'] ?? '',
        nomMagasin: json['nomMagasin'] ?? '',
        nomGerant: json['nomGerant'] ?? '',
        codePin: json['codePin'] ?? '',
        contact: json['contact'] ?? '',
        adresse: json['adresse'] ?? '',
        logo: json['logo'] ?? '',
        produits: (json['produits'] as List? ?? []).map((p) => Produit.fromJson(p)).toList(),
        clients: (json['clients'] as List? ?? []).map((c) => Client.fromJson(c)).toList(),
        historiqueVentes: (json['historiqueVentes'] as List? ?? []).map((v) => Vente.fromJson(v)).toList(),
        depenses: (json['depenses'] as List? ?? []).map((d) => Depense.fromJson(d)).toList(),
        mouvementsCaisse: (json['mouvementsCaisse'] as List? ?? []).map((m) => MouvementCaisse.fromJson(m)).toList(),
        utilisateurs: (json['utilisateurs'] as List? ?? []).map((u) => Utilisateur.fromJson(u)).toList(),
        derniereClotureDate: json['derniereClotureDate'] != null ? DateTime.parse(json['derniereClotureDate']) : null,
      );
}
