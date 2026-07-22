import 'package:eClassify/data/cubits/service/auction_sheet_verification_cubit.dart';
import 'package:eClassify/data/model/service/auction_sheet_verification_model.dart';
import 'package:eClassify/data/repositories/service/auction_sheet_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAuctionSheetRepository
    extends AuctionSheetVerificationRepository {
  String? submittedChassisNumber;
  String? submittedPhoneNumber;

  @override
  Future<AuctionSheetVerificationResult> submitRequest({
    required String chassisNumber,
    required String phoneNumber,
  }) async {
    submittedChassisNumber = chassisNumber;
    submittedPhoneNumber = phoneNumber;
    return AuctionSheetVerificationResult(
      id: 1,
      chassisNumber: chassisNumber,
      status: 'pending',
      message: 'Request submitted.',
    );
  }
}

void main() {
  group('AuctionSheetVerificationCubit submission', () {
    test('adds +92 and clears form fields after success', () async {
      final repository = _RecordingAuctionSheetRepository();
      final cubit = AuctionSheetVerificationCubit(repository: repository)
        ..updateChassisNumber('ncp165-1234567')
        ..updatePhoneNumber('0300 123-4567');

      final submitted = await cubit.notifyMe();

      expect(submitted, isTrue);
      expect(repository.submittedChassisNumber, 'NCP165-1234567');
      expect(repository.submittedPhoneNumber, '+923001234567');
      expect(cubit.state.chassisNumber, isEmpty);
      expect(cubit.state.phoneNumber, isEmpty);

      await cubit.close();
    });

    test('does not duplicate an existing Pakistan country code', () async {
      final repository = _RecordingAuctionSheetRepository();
      final cubit = AuctionSheetVerificationCubit(repository: repository)
        ..updateChassisNumber('NCP165-1234567')
        ..updatePhoneNumber('+92 300 1234567');

      final submitted = await cubit.notifyMe();

      expect(submitted, isTrue);
      expect(repository.submittedPhoneNumber, '+923001234567');

      await cubit.close();
    });
  });
}
