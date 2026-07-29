import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/court_holidays.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({super.key});

  @override
  State<DeadlinesPage> createState() => _DeadlinesPageState();
}

class _DeadlinesPageState extends State<DeadlinesPage> {
  DateTime _orderDate = DateTime.now();
  final _stageCtrl = TextEditingController(text: 'Hearing');

  @override
  void dispose() {
    _stageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final holidays = indiaCourtHolidaysFor(year);
    final predictions =
        predictDeadlines(orderDate: _orderDate, stage: _stageCtrl.text);
    final fmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Holidays & deadlines')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Court holidays (national sample)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          ...holidays.map((h) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(h.name),
                trailing: Text(fmt.format(h.date)),
              )),
          const Divider(height: 32),
          const Text('Predictive deadlines',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const Text(
            'Reminders only — verify limitation and local rules.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Order / reference date'),
            subtitle: Text(fmt.format(_orderDate)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _orderDate,
                  firstDate: DateTime(year - 2),
                  lastDate: DateTime(year + 2),
                );
                if (d != null) setState(() => _orderDate = d);
              },
            ),
          ),
          TextField(
            controller: _stageCtrl,
            decoration: const InputDecoration(labelText: 'Stage'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ...predictions.map((p) => Card(
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text('${fmt.format(p.dueOn)}\n${p.basis}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final ics = toIcsEvent(
                        title: p.title,
                        day: p.dueOn,
                        description: p.basis,
                      );
                      await Clipboard.setData(ClipboardData(text: ics));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('ICS copied for Calendar/Outlook')),
                        );
                      }
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
