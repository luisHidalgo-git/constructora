class Formatters {
  static String formatCurrency(String value) {
    // Remover todo excepto números
    String numbersOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return '';
    }

    // Convertir a número y formatear con comas
    int number = int.parse(numbersOnly);
    String formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '\$$formatted';
  }
  
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
  
  static String formatActivityDate(DateTime? dateTime) {
    if (dateTime == null) return 'Sin fecha';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return formatDate(dateTime);
    }
  }
  
  static String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
  
  static String formatPercentage(double value) {
    return '${(value * 100).toInt()}%';
  }
}