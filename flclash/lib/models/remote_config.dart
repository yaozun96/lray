import 'dart:convert';
import 'package:fl_clash/common/common.dart';

class RemoteConfig {
  final List<String> domain;
  final RemoteVersion version;
  final String download;
  final String? crispId;
  final String? description;
  final String? telegramUrl; // New
  final String? officialUrl; // New
  final List<String>? planTypeOrder;
  final List<PaymentRule>? paymentRules;

  const RemoteConfig({
    required this.domain,
    required this.version,
    required this.download,
    this.crispId,
    this.description,
    this.telegramUrl,
    this.officialUrl,
    this.planTypeOrder,
    this.paymentRules,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    String downloadUrl = '';
    final downloadData = json['download'];
    if (downloadData is String) {
      downloadUrl = downloadData;
    } else if (downloadData is Map) {
       // Pick for current platform or default
       // This is a comprehensive guess based on standard keys
       if (system.isWindows) downloadUrl = downloadData['windows'] ?? '';
       else if (system.isMacOS) downloadUrl = downloadData['macos'] ?? '';
       else if (system.isAndroid) downloadUrl = downloadData['android'] ?? '';
       else if (system.isLinux) downloadUrl = downloadData['linux'] ?? '';
       else downloadUrl = downloadData.values.first.toString();
    }

    return RemoteConfig(
      domain: List<String>.from(json['domain'] ?? []),
      version: RemoteVersion.fromJson(json['version'] ?? {}),
      download: downloadUrl,
      crispId: json['crisp_id'] is String && (json['crisp_id'] as String).isNotEmpty
          ? json['crisp_id']
          : null,
      description: json['description'],
      telegramUrl: json['telegram_url'],
      officialUrl: json['official_url'],
      planTypeOrder: json['plan_type_order'] != null
          ? List<String>.from(json['plan_type_order'])
          : null,
      paymentRules: json['payment_rules'] != null
          ? (json['payment_rules'] as List)
              .map((e) => PaymentRule.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'version': version.toJson(),
      'download': download,
      'crisp_id': crispId,
      'description': description,
      'telegram_url': telegramUrl,
      'official_url': officialUrl,
      'plan_type_order': planTypeOrder,
      'payment_rules': paymentRules?.map((e) => e.toJson()).toList(),
    };
  }
}

class RemoteVersion {
  final String windows;
  final String macos;
  final String android;

  const RemoteVersion({
    required this.windows,
    required this.macos,
    required this.android,
  });

  factory RemoteVersion.fromJson(Map<String, dynamic> json) {
    return RemoteVersion(
      windows: json['windows'] ?? '',
      macos: json['macos'] ?? '',
      android: json['android'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'windows': windows,
      'macos': macos,
      'android': android,
    };
  }
  
  String get currentPlatform {
    if (system.isWindows) return windows;
    if (system.isMacOS) return macos;
    if (system.isAndroid) return android;
    return '';
  }
}

class PaymentRule {
  final int paymentId;
  final double? minAmount;
  final double? maxAmount;

  const PaymentRule({
    required this.paymentId,
    this.minAmount,
    this.maxAmount,
  });

  factory PaymentRule.fromJson(Map<String, dynamic> json) {
    return PaymentRule(
      paymentId: json['payment_id'] as int,
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'min_amount': minAmount,
      'max_amount': maxAmount,
    };
  }
}
