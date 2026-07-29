import 'package:flutter_test/flutter_test.dart';
import 'package:snp_legal_workspace/features/ai/data/ai_assist_service.dart';
import 'package:snp_legal_workspace/features/ai/domain/ai_models.dart';
import 'package:snp_legal_workspace/features/billing/domain/billing_models.dart';
import 'package:snp_legal_workspace/features/documents/domain/document_models.dart';
import 'package:snp_legal_workspace/features/clients/domain/client_models.dart';

void main() {
  group('Document share link validity', () {
    test('valid when not revoked and not expired', () {
      final link = DocumentShareLink(
        token: 'abc',
        documentId: 'd1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        maxDownloads: 5,
        downloadsRemaining: 3,
      );
      expect(link.isValid, isTrue);
    });

    test('invalid when revoked', () {
      final link = DocumentShareLink(
        token: 'abc',
        documentId: 'd1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        revoked: true,
      );
      expect(link.isValid, isFalse);
    });
  });

  group('Client conflict model', () {
    test('result flags', () {
      const ok = ConflictCheckResult(hasConflict: false);
      expect(ok.hasConflict, isFalse);
      const bad = ConflictCheckResult(
        hasConflict: true,
        matches: [
          ConflictMatch(partyName: 'X', source: 'case', role: 'petitioner'),
        ],
      );
      expect(bad.matches.length, 1);
    });
  });

  group('AI tools coverage', () {
    final s = AiAssistService();
    test('all tools return non-empty content', () {
      for (final t in AiToolType.values) {
        final r = s.generate(tool: t, matterTitle: 'Sample');
        expect(r.content.isNotEmpty, isTrue, reason: t.name);
        expect(r.tool, t);
      }
    });
  });

  group('Invoice status labels', () {
    test('every status has label', () {
      for (final s in InvoiceStatus.values) {
        expect(s.label.isNotEmpty, isTrue);
      }
    });
  });
}
