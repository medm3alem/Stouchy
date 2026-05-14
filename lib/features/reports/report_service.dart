import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../transactions/domain/transaction.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateAndDownloadReport({
    required String monthYear,
    required double balance,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryData,
    required String aiAdvice,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();
    
    // Charger une police qui supporte les accents (UTF-8)
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rapport Financier Stouchy', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(monthYear, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Résumé Global
            pw.Text('Résumé du mois', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Solde', '$balance$currencySymbol'),
                _buildStat('Revenus', '$totalIncome$currencySymbol'),
                _buildStat('Dépenses', '$totalExpense$currencySymbol'),
              ],
            ),
            pw.SizedBox(height: 30),

            // Graphique/Tableau des catégories
            pw.Text('Dépenses par catégorie', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Catégorie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...categoryData.entries.map((e) {
                  final percentage = totalExpense > 0 ? (e.value / totalExpense * 100).toStringAsFixed(1) : '0';
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.key)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.value.toStringAsFixed(2)}$currencySymbol')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$percentage%')),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 30),

            // Conseil IA
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Analyse de Stouchy AI', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
                  pw.SizedBox(height: 10),
                  pw.Text(aiAdvice, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Généré par Stouchy - Votre coach financier intelligent',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    // Lancer l'impression / sauvegarde
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Stouchy_$monthYear.pdf',
    );
  }

  static pw.Widget _buildStat(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
