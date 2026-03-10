import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app/models/travel_model.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class PdfService {
  static Future<void> generateAndDownloadTravelPlan(
    TravelPlan travelPlan,
  ) async {
    final pdf = pw.Document();

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(travelPlan),
          pw.SizedBox(height: 30),
          _buildOverview(travelPlan),
          pw.SizedBox(height: 30),
          ..._buildItinerary(travelPlan),
        ],
      ),
    );

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();

    if (kIsWeb) {
      // For web platform
      _downloadPdfWeb(
        pdfBytes,
        '${travelPlan.title.replaceAll(' ', '_')}_Travel_Plan.pdf',
      );
    } else {
      // For mobile platforms
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${travelPlan.title.replaceAll(' ', '_')}_Travel_Plan.pdf',
      );
    }
  }

  static void _downloadPdfWeb(Uint8List pdfBytes, String filename) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static pw.Widget _buildHeader(TravelPlan travelPlan) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF3B82F6), PdfColor.fromInt(0xFF1E40AF)],
        ),
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            travelPlan.title,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${travelPlan.destination} • ${travelPlan.duration}',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Travel Planner',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOverview(TravelPlan travelPlan) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Overview',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1E40AF),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Destination:', travelPlan.destination),
                    _buildInfoRow('Duration:', travelPlan.duration),
                    _buildInfoRow(
                      'Total Days:',
                      '${travelPlan.itinerary.duration_days}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildItinerary(TravelPlan travelPlan) {
    List<pw.Widget> widgets = [];

    widgets.add(
      pw.Text(
        'Daily Itinerary',
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF1E40AF),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    for (final day in travelPlan.itinerary.days) {
      widgets.add(_buildDaySection(day));
      widgets.add(pw.SizedBox(height: 25));
    }

    return widgets;
  }

  static pw.Widget _buildDaySection(TravelDay day) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF3B82F6),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '${day.day_number}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Day ${day.day_number}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      day.theme,
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        ...day.activities
            .map((activity) => _buildActivityItem(activity))
            .toList(),
      ],
    );
  }

  static pw.Widget _buildActivityItem(Activity activity) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF3B82F6),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  activity.time,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _getCategoryColorPdf(activity.category),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  activity.category.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            activity.location.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1E40AF),
            ),
          ),
          if (activity.location.address.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              activity.location.address,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            activity.description,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
          ),
          if (activity.culturalConnection.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFF3B82F6),
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Why this matches your taste:',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF3B82F6),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    activity.culturalConnection,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static PdfColor _getCategoryColorPdf(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return const PdfColor.fromInt(0xFF8B5CF6);
      case 'film':
        return const PdfColor.fromInt(0xFFF59E0B);
      case 'fashion':
        return const PdfColor.fromInt(0xFFEC4899);
      case 'dining':
        return const PdfColor.fromInt(0xFF10B981);
      case 'hidden_gem':
        return const PdfColor.fromInt(0xFF3B82F6);
      default:
        return const PdfColor.fromInt(0xFF6B7280);
    }
  }
}
