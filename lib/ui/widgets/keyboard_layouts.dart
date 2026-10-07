enum KeyboardKeyKind {
  character,
  shift,
  backspace,
  layer,
  enter,
  space,
  disabled
}

class KeyboardKeyData {
  const KeyboardKeyData({
    required this.label,
    required this.kind,
    this.flex = 2,
    this.alternates = const [],
  });

  final String label;
  final KeyboardKeyKind kind;
  final int flex;
  final List<String> alternates;

  bool get isLetter => kind == KeyboardKeyKind.character && label.length == 1;
}

const letterKeyboardRows = <List<KeyboardKeyData>>[
  [
    KeyboardKeyData(label: 'Q', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'W', kind: KeyboardKeyKind.character),
    KeyboardKeyData(
      label: 'E',
      kind: KeyboardKeyKind.character,
      alternates: ['é', 'è', 'ê'],
    ),
    KeyboardKeyData(label: 'R', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'T', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'Y', kind: KeyboardKeyKind.character),
    KeyboardKeyData(
      label: 'U',
      kind: KeyboardKeyKind.character,
      alternates: ['ú', 'ù', 'û'],
    ),
    KeyboardKeyData(
      label: 'I',
      kind: KeyboardKeyKind.character,
      alternates: ['í', 'ì', 'î'],
    ),
    KeyboardKeyData(
      label: 'O',
      kind: KeyboardKeyKind.character,
      alternates: ['ó', 'ò', 'ô'],
    ),
    KeyboardKeyData(label: 'P', kind: KeyboardKeyKind.character),
  ],
  [
    KeyboardKeyData(
        label: 'A',
        kind: KeyboardKeyKind.character,
        alternates: ['á', 'à', 'â']),
    KeyboardKeyData(label: 'S', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'D', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'F', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'G', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'H', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'J', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'K', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'L', kind: KeyboardKeyKind.character),
  ],
  [
    KeyboardKeyData(label: 'Shift', kind: KeyboardKeyKind.shift, flex: 3),
    KeyboardKeyData(label: 'Z', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'X', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'C', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'V', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'B', kind: KeyboardKeyKind.character),
    KeyboardKeyData(
        label: 'N', kind: KeyboardKeyKind.character, alternates: ['ñ']),
    KeyboardKeyData(label: 'M', kind: KeyboardKeyKind.character),
    KeyboardKeyData(
        label: 'Backspace', kind: KeyboardKeyKind.backspace, flex: 3),
  ],
  [
    KeyboardKeyData(label: '?123', kind: KeyboardKeyKind.layer, flex: 3),
    KeyboardKeyData(label: ',', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'SPACE', kind: KeyboardKeyKind.space, flex: 10),
    KeyboardKeyData(label: '.', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'Enter', kind: KeyboardKeyKind.enter, flex: 3),
  ],
];

const symbolKeyboardRows = <List<KeyboardKeyData>>[
  [
    KeyboardKeyData(label: '1', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '2', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '3', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '4', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '5', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '6', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '7', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '8', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '9', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '0', kind: KeyboardKeyKind.character),
  ],
  [
    KeyboardKeyData(label: '@', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '#', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '₱', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '%', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '&', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '-', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '+', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '(', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: ')', kind: KeyboardKeyKind.character),
  ],
  [
    KeyboardKeyData(label: '', kind: KeyboardKeyKind.disabled, flex: 3),
    KeyboardKeyData(label: '!', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '"', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: "'", kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: ':', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: ';', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '/', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: '?', kind: KeyboardKeyKind.character),
    KeyboardKeyData(
        label: 'Backspace', kind: KeyboardKeyKind.backspace, flex: 3),
  ],
  [
    KeyboardKeyData(label: 'ABC', kind: KeyboardKeyKind.layer, flex: 3),
    KeyboardKeyData(label: ',', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'SPACE', kind: KeyboardKeyKind.space, flex: 10),
    KeyboardKeyData(label: '.', kind: KeyboardKeyKind.character),
    KeyboardKeyData(label: 'Enter', kind: KeyboardKeyKind.enter, flex: 3),
  ],
];
