class GestionLicence {
  // Délai de validité par défaut fixé à 3 jours à partir de la première installation
  static DateTime dateExpiration = DateTime.now().add(const Duration(days: 3));

  static bool get estExpire => DateTime.now().isAfter(dateExpiration);
}

class Utilisateur {
  String id;
  String nom;
  String codePin;
  bool estAdmin;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.codePin,
    required this.estAdmin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'codePin': codePin,
      'estAdmin': estAdmin,
    };
  }

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      codePin: json['codePin'] ?? '',
      estAdmin: json['estAdmin'] ?? false,
    );
  }
}