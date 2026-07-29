import 'package:flutter_test/flutter_test.dart';
import 'package:snp_legal_workspace/features/billing/domain/billing_models.dart';
import 'package:snp_legal_workspace/features/ai/data/ai_assist_service.dart';
import 'package:snp_legal_workspace/features/ai/domain/ai_models.dart';

void main() {
  group('Invoice calculations', () {
    test('line amount and invoice totals', () {
      final now = DateTime(2026, 7, 29);
      final inv = Invoice(
        id: '1',
        invoiceNumber: 'SNP-2026-0001',
        lines: const [
          InvoiceLineItem(
            description: 'Hearing',
            quantity: 2,
            unitAmount: 5000,
            feeModel: FeeModel.perHearing,
          ),
          InvoiceLineItem(
            description: 'Drafting',
            quantity: 1,
            unitAmount: 10000,
          ),
        ],
        gstPercent: 18,
        createdAt: now,
        updatedAt: now,
      );
      expect(inv.subtotal, 20000);
      expect(inv.gstAmount, 3600);
      expect(inv.total, 23600);
      expect(inv.balanceDue, 23600);
    });

    test('partial payment updates balance', () {
      final now = DateTime(2026, 7, 29);
      final inv = Invoice(
        id: '1',
        invoiceNumber: 'SNP-2026-0001',
        lines: const [
          InvoiceLineItem(
              description: 'Fee', quantity: 1, unitAmount: 10000),
        ],
        gstPercent: 0,
        paidAmount: 4000,
        createdAt: now,
        updatedAt: now,
      );
      expect(inv.total, 10000);
      expect(inv.balanceDue, 6000);
    });

    test('time entry amount', () {
      final e = TimeEntry(
        id: 't1',
        description: 'Conference',
        minutes: 90,
        hourlyRate: 4000,
        date: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      );
      expect(e.amount, 6000);
      expect(e.durationLabel, '1h 30m');
    });
  });

  group('CNR format', () {
    test('accepts 16 alphanumeric', () {
      final cnr = 'DLCT010012342024';
      expect(cnr.length, 16);
      expect(RegExp(r'^[A-Z0-9]{16}$').hasMatch(cnr), isTrue);
    });
  });

  group('AI on-device templates', () {
    final service = AiAssistService();

    test('case brief contains sections', () {
      final r = service.generate(
        tool: AiToolType.caseBrief,
        matterTitle: 'Test v State',
        courtName: 'Saket',
        stage: 'Trial',
      );
      expect(r.content, contains('CASE BRIEF'));
      expect(r.content, contains('ISSUES'));
      expect(r.content, contains('Test v State'));
    });

    test('checklist has filing items', () {
      final r =
          service.generate(tool: AiToolType.checklist, matterTitle: 'X');
      expect(r.content, contains('Vakalatnama'));
    });
  });
}
