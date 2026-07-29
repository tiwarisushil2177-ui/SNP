class LegalTemplate {
  const LegalTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
  });
  final String id;
  final String title;
  final String category;
  final String body;
}

const legalTemplates = [
  LegalTemplate(
    id: 'vakalatnama',
    title: 'Vakalatnama',
    category: 'Vakalatnama',
    body: '''
VAKALATNAMA

IN THE COURT OF _______________________

_________________  … Petitioner / Plaintiff
Versus
_________________  … Respondent / Defendant

I/We appoint ________________________________ (Advocate) to appear and act.

Place: __________
Date: __________

Signature of Client(s)
''',
  ),
  LegalTemplate(
    id: 'affidavit',
    title: 'Affidavit (general)',
    category: 'Affidavit',
    body: '''
AFFIDAVIT

I, ____________________, aged about ___ years, resident of ____________________,
do hereby solemnly affirm and state as under:

1.
2.
3.

DEPONENT
''',
  ),
  LegalTemplate(
    id: 'petition_outline',
    title: 'Petition / plaint outline',
    category: 'Petition / Plaint',
    body: '''
IN THE COURT OF _______________________

PETITION UNDER _______________________

MOST RESPECTFULLY SHOWETH:
1. Facts
2. Cause of action
3. Jurisdiction
4. Limitation
5. Grounds
6. Prayer
''',
  ),
  LegalTemplate(
    id: 'application_ia',
    title: 'Interlocutory application',
    category: 'Application / IA',
    body: '''
IA No. _____ of 20__

APPLICATION UNDER _______________________

Prayers:
a)
b)
''',
  ),
];
