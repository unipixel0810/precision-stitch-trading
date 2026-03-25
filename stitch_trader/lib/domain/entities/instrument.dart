import 'symbol_code.dart';

final class Instrument {
  Instrument({required this.code, required this.displayName});

  final SymbolCode code;
  final String displayName;
}
