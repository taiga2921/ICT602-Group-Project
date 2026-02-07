import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/event_model.dart';
import '../../models/attendance_model.dart';
import '../../services/firestore_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  final EventModel event;

  const AttendanceReportScreen({super.key, required this.event});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _generatePdf(List<AttendanceModel> attendanceList) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Event: ${widget.event.name}'),
                pw.Text('Venue: ${widget.event.venue}'),
                pw.Text('Date: ${dateFormat.format(widget.event.startTime)}'),
                pw.Text('Total Attendees: ${attendanceList.length}'),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'No.',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Email',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Check-in Time',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...attendanceList.asMap().entries.map((entry) {
                int index = entry.key;
                AttendanceModel attendance = entry.value;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${index + 1}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(attendance.userEmail ?? 'N/A'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(dateFormat.format(attendance.checkInTime)),
                    ),
                  ],
                );
              // ignore: unnecessary_to_list_in_spreads
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          StreamBuilder<List<AttendanceModel>>(
            stream: _firestoreService.getEventAttendance(widget.event.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(snapshot.data!),
                tooltip: 'Export PDF',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            // ignore: deprecated_member_use
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(widget.event.venue),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(widget.event.startTime)} - ${dateFormat.format(widget.event.endTime)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder<List<AttendanceModel>>(
            stream: _firestoreService.getEventAttendance(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Expanded(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }

              final attendanceList = snapshot.data ?? [];

              if (attendanceList.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendees yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Total Attendees: ${attendanceList.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: attendanceList.length,
                        itemBuilder: (context, index) {
                          final attendance = attendanceList[index];
                          final checkInFormat = DateFormat('MMM dd, hh:mm a');

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                attendance.userEmail ?? 'Unknown User',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                checkInFormat.format(attendance.checkInTime),
                              ),
                              trailing: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}