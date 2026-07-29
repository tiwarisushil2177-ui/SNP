import 'package:flutter_test/flutter_test.dart';
import 'package:snp_legal_workspace/core/theme/app_colors.dart';

void main() {
  test('design system colors are defined', () {
    expect(AppColors.deepNavy.value, isNonZero);
    expect(AppColors.saffron.value, isNonZero);
    expect(AppColors.ivory.value, isNonZero);
  });
}
