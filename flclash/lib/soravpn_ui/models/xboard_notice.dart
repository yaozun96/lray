/// Xboard 公告模型
class XboardNotice {
  final int id;
  final String title;
  final String content;
  final String? imgUrl;
  final int? show;
  final int? sort;
  final int? createdAt;
  final int? updatedAt;
  final List<String>? tags;

  XboardNotice({
    required this.id,
    required this.title,
    required this.content,
    this.imgUrl,
    this.show,
    this.sort,
    this.createdAt,
    this.updatedAt,
    this.tags,
  });

  factory XboardNotice.fromJson(Map<String, dynamic> json) {
    return XboardNotice(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imgUrl: json['img_url'],
      show: json['show'],
      sort: json['sort'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;
}

/// Xboard 知识库模型
class XboardKnowledge {
  final int id;
  final String? language; // 语言
  final String? category; // 分类
  final String title;
  final String body; // 内容 (Markdown)
  final int? show;
  final int? sort;
  final int? createdAt;
  final int? updatedAt;

  XboardKnowledge({
    required this.id,
    this.language,
    this.category,
    required this.title,
    required this.body,
    this.show,
    this.sort,
    this.createdAt,
    this.updatedAt,
  });

  factory XboardKnowledge.fromJson(Map<String, dynamic> json) {
    return XboardKnowledge(
      id: json['id'] ?? 0,
      language: json['language'],
      category: json['category'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      show: json['show'],
      sort: json['sort'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;
}

/// 公共配置模型 (Guest Config)
class XboardGuestConfig {
  final bool isEmailVerify; // 是否需要邮箱验证
  final bool isInviteForce; // 是否强制邀请码
  final bool isRecaptcha; // 是否启用 reCAPTCHA
  final String? recaptchaSiteKey;
  final List<String>? tosUrl; // 服务条款
  final String? appName;
  final String? appDescription;
  final String? appUrl;
  final String? logo;

  XboardGuestConfig({
    this.isEmailVerify = false,
    this.isInviteForce = false,
    this.isRecaptcha = false,
    this.recaptchaSiteKey,
    this.tosUrl,
    this.appName,
    this.appDescription,
    this.appUrl,
    this.logo,
  });

  factory XboardGuestConfig.fromJson(Map<String, dynamic> json) {
    return XboardGuestConfig(
      isEmailVerify: json['is_email_verify'] == 1 || json['is_email_verify'] == true,
      isInviteForce: json['is_invite_force'] == 1 || json['is_invite_force'] == true,
      isRecaptcha: json['is_recaptcha'] == 1 || json['is_recaptcha'] == true,
      recaptchaSiteKey: json['recaptcha_site_key'],
      tosUrl: json['tos_url'] != null ? List<String>.from(json['tos_url']) : null,
      appName: json['app_name'],
      appDescription: json['app_description'],
      appUrl: json['app_url'],
      logo: json['logo'],
    );
  }
}
