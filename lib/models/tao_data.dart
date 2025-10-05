// models/tao_data.dart
class TaoData {
  final int number;
  final String title;
  final String text;
  final String notes;
  final String audio1;
  final String audio2;
  final String audio3;

  TaoData({
    required this.number,
    required this.title,
    required this.text,
    required this.notes,
    required this.audio1,
    required this.audio2,
    required this.audio3,
  });

  factory TaoData.fromJson(Map<String, dynamic> json) {
    // Convert // to \n for proper line breaks
    String formatText(String text) {
      return text.replaceAll('//', '\n').replaceAll('////', '\n\n');
    }

    String formatNotes(String notes) {
      return notes.replaceAll('\\n', '\n');
    }

    return TaoData(
      number: int.tryParse(json['number'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled',
      text: formatText(json['text']?.toString() ?? 'Text not available'),
      notes: formatNotes(json['notes']?.toString() ?? ''),
      audio1: json['1']?.toString() ?? '',
      audio2: json['2']?.toString() ?? '',
      audio3: json['3']?.toString() ?? '',
    );
  }

  static String _formatTaoText(String rawText) {
    if (rawText.isEmpty) return 'Text not available';

    String text = rawText
        .replaceAll('\\n', '\n')
        .replaceAll('|', '\n')
        .replaceAll(';', '\n')
        .replaceAll('//', '\n')
        .replaceAll('  ', '\n\n');

    if (!text.contains('\n')) {
      text = text
          .replaceAll('. ', '.\n\n')
          .replaceAll('? ', '?\n\n')
          .replaceAll('! ', '!\n\n');
    }

    return text.trim();
  }

  static String _formatNotes(String rawNotes) {
    if (rawNotes.isEmpty) return '';

    return rawNotes
        .replaceAll('\\n', '\n')
        .replaceAll('|', '\n')
        .replaceAll('•', '\n•')
        .replaceAll('- ', '\n- ')
        .trim();
  }

  factory TaoData.empty() {
    return TaoData(
      number: 0,
      title: '',
      text: '',
      notes: '',
      audio1: '',
      audio2: '',
      audio3: '',
    );
  }
}