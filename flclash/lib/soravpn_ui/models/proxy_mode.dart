/// VPN 代理模式
enum ProxyMode {
  /// 智能分流模式 - 国内直连，国外走代理
  smart('智能分流'),

  /// 全局代理模式 - 所有流量走代理
  global('全局模式');

  final String label;
  const ProxyMode(this.label);
}
