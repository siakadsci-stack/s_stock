import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'sales_page.dart'; // Pour le modèle Vente
import 'magasin_model.dart'; // Pour le modèle Magasin

Future<void> imprimerFacture(Vente vente, Magasin magasin) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5, // Format idéal pour ce type de facture
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Bloc Logo / Nom du Magasin / Numéro
                pw.Container(
                  width: 150,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        magasin.nomMagasin,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Magasin N° : ${magasin.id}',
                        style: const TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      const pw.Spacer(),
                      const pw.Text(
                        '[ Logo / Enseigne ]',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ),

                // Bloc Infos Facture & Client
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('N° FACTURE : ${vente.id.substring(vente.id.length - 5)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('DATE : ${vente.date.day}/${vente.date.month}/${vente.date.year}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('HEURE : ${vente.date.hour}:${vente.date.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('SAISIE : ${magasin.nomGerant}', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('NOM DU CLIENT : ${vente.nomClient}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    const pw.Text('CONTACT : 07 07 07 07 07', style: pw.TextStyle(fontSize: 9)),
                    const pw.Text('ADRESSE : ABIDJAN', style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            
            // Titre Liste des articles
            pw.Center(
              child: pw.Text(
                'LISTE DES ARTICLES',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 10),

            // --- TABLEAU DES ARTICLES ---
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['DESIGNATION', 'QTE', 'P. UNIT', 'P. TOTAL'],
              data: vente.articles.map((article) {
                return [
                  article.nomProduit,
                  article.quantite.toString(),
                  '${article.prixVente.toStringAsFixed(0)}',
                  '${article.total.toStringAsFixed(0)}',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // --- PIED DE PAGE (MONTANT NET & CACHET) ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Cachet Magasin
                pw.Container(
                  width: 110,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed),
                  ),
                  alignment: pw.Alignment.center,
                  child: const pw.Text(
                    'CACHET MAGASIN',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),

                // Montant Net
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('MONTANT NET : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text(
                        '${vente.total.toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  // Lancer l'impression ou l'aperçu PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}