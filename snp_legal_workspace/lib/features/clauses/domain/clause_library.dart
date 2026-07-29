class ClauseEntry {
  const ClauseEntry({
    required this.id,
    required this.title,
    required this.tags,
    required this.text,
  });
  final String id;
  final String title;
  final List<String> tags;
  final String text;
}

const clauseLibrary = [
  ClauseEntry(
    id: 'jurisdiction',
    title: 'Jurisdiction clause',
    tags: ['civil', 'contract'],
    text:
        'Subject to the exclusive jurisdiction of the competent courts at __________.',
  ),
  ClauseEntry(
    id: 'limitation_saving',
    title: 'Limitation — sufficient cause',
    tags: ['limitation', 'procedure'],
    text:
        'The delay in filing, if any, is neither deliberate nor mala fide and is liable to be condoned in the interest of justice.',
  ),
  ClauseEntry(
    id: 'interim_protection',
    title: 'Interim protection prayer',
    tags: ['injunction', 'ia'],
    text:
        'Pending disposal of this application, the respondents be restrained from ______________.',
  ),
  ClauseEntry(
    id: 'costs',
    title: 'Costs',
    tags: ['prayer'],
    text: 'Award costs of this petition in favour of the petitioner.',
  ),
  ClauseEntry(
    id: 'no_solicitation',
    title: 'Internal note — Bar Council Rule 36',
    tags: ['ethics'],
    text:
        'Do not publish rankings, client testimonials for solicitation, or cold-outreach directories via this workspace.',
  ),
];
