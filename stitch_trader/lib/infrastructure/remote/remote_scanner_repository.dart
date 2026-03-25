import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class RemoteScannerRepository implements ScannerRepository {
  const RemoteScannerRepository();

  @override
  Future<List<ScannerHit>> listHits() async {
    throw UnimplementedError('RemoteScannerRepository: connect REST/Kiwoom feed.');
  }
}
