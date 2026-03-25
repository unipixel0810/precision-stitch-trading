/// 상장 종목 코드 (예: 005380). 순수 Dart.
final class SymbolCode {
  SymbolCode(String raw)
    : value = raw.trim() {
    if (value.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'SymbolCode must not be empty');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SymbolCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
