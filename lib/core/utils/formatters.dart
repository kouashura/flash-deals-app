import 'package:intl/intl.dart';

class Formatters {
  static String price(num amount) {
    final f = NumberFormat('#,###', 'fr_FR');
    return '${f.format(amount)} FCFA';
  }

  static String date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);
}
