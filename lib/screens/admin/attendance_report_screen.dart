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

  const AttendanceReportScreen({Key? key, required this.event})
      : super(key: key);

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _generatePdf(List<AttendanceModel> attendanceList) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final fullDateFormat = DateFormat('MMM dd, yyyy hh:mm a');

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
                pw.SizedBox(height: 16),
                pw.Text(
                  'Event Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Event Name: ${widget.event.name}'),
                pw.Text('Venue: ${widget.event.venue}'),
                pw.Text(
                  'Date: ${dateFormat.format(widget.event.startTime)} - ${dateFormat.format(widget.event.endTime)}',
                ),
                pw.Text(
                  'Time: ${timeFormat.format(widget.event.startTime)} - ${timeFormat.format(widget.event.endTime)}',
                ),
                pw.Text(
                  'GPS Location: ${widget.event.latitude != null && widget.event.longitude != null ? '${widget.event.latitude!.toStringAsFixed(6)}, ${widget.event.longitude!.toStringAsFixed(6)}' : '-'}',
                ),
                pw.Text(
                  'Beacon UUID: ${widget.event.beaconUuid.isNotEmpty ? widget.event.beaconUuid : '-'}',
                ),
                pw.Text(
                  'Beacon Major/Minor: ${widget.event.beaconMajor != 0 || widget.event.beaconMinor != 0 ? '${widget.event.beaconMajor} / ${widget.event.beaconMinor}' : '-'}',
                ),
                pw.SizedBox(height: 8),
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
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'No.',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Email',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Check-in Time',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'GPS Location',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...attendanceList.asMap().entries.map((entry) {
                int index = entry.key;
                AttendanceModel attendance = entry.value;
                String gpsLocation = attendance.latitude != null &&
                        attendance.longitude != null
                    ? '${attendance.latitude!.toStringAsFixed(4)}, ${attendance.longitude!.toStringAsFixed(4)}'
                    : '-';
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${index + 1}'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(attendance.userEmail ?? 'N/A'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                          fullDateFormat.format(attendance.checkInTime)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(gpsLocation,
                          style: pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                );
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
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
        actions: [
          StreamBuilder<List<AttendanceModel>>(
            stream: _firestoreService.getEventAttendance(widget.event.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox();
              }
              return IconButton(
                icon: Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(snapshot.data!),
                tooltip: 'Export PDF',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Details Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(height: 24),
                _buildDetailRow(Icons.location_on, 'Venue', widget.event.venue),
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  '${dateFormat.format(widget.event.startTime)} - ${dateFormat.format(widget.event.endTime)}',
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.access_time,
                  'Time',
                  '${timeFormat.format(widget.event.startTime)} - ${timeFormat.format(widget.event.endTime)}',
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.gps_fixed,
                  'GPS Location',
                  widget.event.latitude != null &&
                          widget.event.longitude != null
                      ? '${widget.event.latitude!.toStringAsFixed(6)}, ${widget.event.longitude!.toStringAsFixed(6)}'
                      : '-',
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.bluetooth,
                  'Beacon UUID',
                  widget.event.beaconUuid.isNotEmpty
                      ? widget.event.beaconUuid
                      : '-',
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.numbers,
                  'Beacon Major/Minor',
                  widget.event.beaconMajor != 0 || widget.event.beaconMinor != 0
                      ? '${widget.event.beaconMajor} / ${widget.event.beaconMinor}'
                      : '-',
                ),
              ],
            ),
          ),
          StreamBuilder<List<AttendanceModel>>(
            stream: _firestoreService.getEventAttendance(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Expanded(
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
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
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
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.people,
                              color: Theme.of(context).primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Total Attendees: ${attendanceList.length}',
                            style: TextStyle(
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
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                attendance.userEmail ?? 'Unknown User',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                checkInFormat.format(attendance.checkInTime),
                              ),
                              trailing: Icon(
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
