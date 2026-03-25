import '../entities/scanner_hit.dart';

/// 스캐너 후보 종목 소스 (20시 로직 등 — 구현은 infrastructure).
abstract class ScannerRepository {
  Future<List<ScannerHit>> listHits();
}
