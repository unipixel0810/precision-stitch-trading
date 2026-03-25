import '../entities/chart_price_line.dart';
import '../entities/ohlc_snapshot.dart';
import '../entities/symbol_code.dart';

/// 선택 종목에 대한 차트 배경·OHLC·오버레이 라인.
abstract class ChartContextRepository {
  Future<OhlcSnapshot> getOhlc(SymbolCode symbol);

  Future<List<ChartPriceLine>> listPriceLines(SymbolCode symbol);

  /// 메인 차트 배경 이미지 URI (없으면 null).
  Future<Uri?> backgroundImage(SymbolCode symbol);
}
