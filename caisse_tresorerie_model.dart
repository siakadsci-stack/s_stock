import 'package:flutter/material.dart';

class MouvementCaisse {
  final String id;
  final DateTime date;
  final String type; // 'Versement' ou 'Retrait'
  final double montant;
  final String motif;
  final String auteur;

  MouvementCaisse({
    required this.id,
    required this.date,
    required this.type,
    required this.montant,
    required this.motif,
    required this.auteur,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'montant': montant,
      'motif': motif,
      'auteur': auteur,
    };
  }

  factory MouvementCaisse.fromJson(Map<String, dynamic> json) {
    return MouvementCaisse(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      motif: json['motif'] ?? '',
      auteur: json['auteur'] ?? '',
    );
  }
}