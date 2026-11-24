/// OneDrive 云同步配置
///
/// 使用步骤（一次性）：
/// 1. 访问 https://portal.azure.com → Microsoft Entra ID → 应用注册 → 新注册
/// 2. 应用名称随意（如 WortApp），支持的账户类型选「个人 Microsoft 账户」
/// 3. 平台配置：添加「移动和桌面应用程序」平台，重定向 URI 填
///    http://localhost（与下方 [redirectUrl] 一致）
/// 4. API 权限：添加委派权限 Files.ReadWrite.AppFolder + offline_access
/// 5. 将「应用程序(客户端) ID」填入下方 [clientId]
class OneDriveConfig {
  OneDriveConfig._();

  /// Azure 应用 Client ID（申请后替换）
  static const String clientId = '566a392c-8566-4ddc-9fa2-b4d8219ddd7f';

  /// 重定向 URI（须与 Azure 应用注册中的配置一致）
  ///
  /// 认证在应用内 WebView 中完成并自动拦截回调换取令牌，
  /// 因此使用 Azure 支持的本地重定向即可，无需系统浏览器跳转。
  static const String redirectUrl = 'http://localhost';

  /// OAuth 权限：仅访问 App 专用文件夹（用户 OneDrive 中的 Apps/WortApp），
  /// 应用无法读取用户的其他文件，更安全。
  static const String scopes = 'Files.ReadWrite.AppFolder offline_access';

  /// 是否已填入真实的 Client ID
  static bool get isConfigured =>
      clientId.isNotEmpty && !clientId.startsWith('PASTE_');
}
