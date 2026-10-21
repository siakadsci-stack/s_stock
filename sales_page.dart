void _imprimerDocument(Vente vente, {required bool estBonDeLivraison}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Scaffold(
          appBar: AppBar(
            title: Text(estBonDeLivraison ? 'Prévisualisation - Bon de Livraison' : 'Prévisualisation - Facture Client'),
            backgroundColor: Colors.blueAccent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PdfPreview(
            build: (format) async {
              final pdf = pw.Document();

              pw.ImageProvider? logoImage;
              if (widget.magasin.logo.isNotEmpty) {
                try {
                  final decodedBytes = base64Decode(widget.magasin.logo);
                  logoImage = pw.MemoryImage(decodedBytes);
                } catch (_) {}
              }

              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a5,
                  margin: const pw.EdgeInsets.all(20),
                  build: (pw.Context pdfContext) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // ENTÊTE COMMUNE
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (logoImage != null)
                                pw.Container(width: 60, height: 40, child: pw.Image(logoImage))
                              else
                                pw.Text('LOGO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.SizedBox(height: 5),
                              pw.Text(widget.magasin.nomMagasin, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Tél : ${widget.magasin.contact}', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('Adresse : ${widget.magasin.adresse}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                estBonDeLivraison ? 'BON DE LIVRAISON' : 'FACTURE N° : ${vente.id.substring(vente.id.length > 5 ? vente.id.length - 5 : 0)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.Text('Date : ${vente.date.day}/${vente.date.month}/${vente.date.year}', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('Client : ${vente.nomClient}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              if (vente.telephoneClient.isNotEmpty)
                                pw.Text('Tél Client : ${vente.telephoneClient}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.SizedBox(height: 10),

                      // CONTENU ADAPTÉ
                      if (estBonDeLivraison) ...[
                        pw.Center(
                          child: pw.Text('BON DE LIVRAISON (Articles & Quantités)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Table.fromTextArray(
                          headers: ['DESIGNATION ARTICLE', 'QUANTITÉ LIVRÉE'],
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          data: vente.articles.map((a) => [
                                a.nomProduit,
                                a.quantite.toString(),
                              ]).toList(),
                        ),
                      ] else ...[
                        pw.Table.fromTextArray(
                          headers: ['ARTICLE', 'QTE', 'P. UNITAIRE', 'TOTAL'],
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          data: vente.articles.map((a) => [
                                a.nomProduit,
                                a.quantite.toString(),
                                '${a.prixVente.toStringAsFixed(0)} FCFA',
                                '${a.total.toStringAsFixed(0)} FCFA',
                              ]).toList(),
                        ),
                      ],

                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 90,
                            height: 45,
                            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed)),
                            alignment: pw.Alignment.center,
                            child: pw.Text('CACHET', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ),
                          if (!estBonDeLivraison)
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                              child: pw.Text(
                                'NET À PAYER : ${vente.total.toStringAsFixed(0)} FCFA',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              return pdf.save();
            },
          ),
        ),
      ),
    );
  }
