import 'package:flutter/foundation.dart';

/// ライセンスステータス
sealed class LicenseStatus {
  const LicenseStatus();
}

/// 有効なProライセンス
@immutable
class ValidPro extends LicenseStatus {
  final String licenseId;
  const ValidPro({required this.licenseId});
}

/// 有効なFreeライセンス
@immutable
class ValidFree extends LicenseStatus {
  const ValidFree();
}

/// 無効なライセンス
@immutable
class Invalid extends LicenseStatus {
  final String reason;
  const Invalid({required this.reason});
}

/// ライセンス情報
@immutable
class LicenseInfo {
  final bool isPro;
  final int imageLimit;
  final LicenseStatus status;

  const LicenseInfo({
    required this.isPro,
    required this.imageLimit,
    required this.status,
  });

  static const LicenseInfo free = LicenseInfo(
    isPro: false,
    imageLimit: 500,
    status: ValidFree(),
  );
}
