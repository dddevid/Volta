import 'package:flutter/material.dart';

class UiUtils {
  static double? parseVoto(String voto) {
    String parsableVoto = voto.replaceAll(',', '.').replaceAll('\u00bd', '.5');
    double? numericVoto;

    if (parsableVoto.endsWith('+')) {
      numericVoto = (double.tryParse(
                  parsableVoto.substring(0, parsableVoto.length - 1)) ??
              0) +
          0.25;
    } else if (parsableVoto.endsWith('-')) {
      numericVoto = (double.tryParse(
                  parsableVoto.substring(0, parsableVoto.length - 1)) ??
              0) -
          0.25;
    } else {
      numericVoto = double.tryParse(parsableVoto);
    }

    return numericVoto;
  }

  static Color getVotoColor(String voto) {
    final numericVoto = parseVoto(voto);

    if (numericVoto == null) return Colors.grey;

    if (numericVoto >= 7) {
      return const Color(0xFF4CAF50);
    } else if (numericVoto >= 6) {
      return const Color(0xFFFFC107);
    } else {
      return const Color(0xFFF44336);
    }
  }
}
