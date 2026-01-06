import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';

/// 节点分组模型 - 用于在节点选择对话框中显示订阅分组
class NodeGroup {
  final int subscriptionId;
  final String groupName;
  final List<VpnNode> nodes;

  NodeGroup({
    required this.subscriptionId,
    required this.groupName,
    required this.nodes,
  });

  factory NodeGroup.fromJson(Map<String, dynamic> json) {
    print('[NodeGroup] Parsing group JSON keys: ${json.keys.toList()}');
    
    // The API returns user_subscribe records
    // We inject subscribe_name from the subscription list
    String groupName = '订阅 #${json['subscribe_id'] ?? json['id']}';
    
    // Priority: subscribe_name (injected) > subscribe.name > name
    if (json['subscribe_name'] != null && json['subscribe_name'].toString().isNotEmpty) {
      groupName = json['subscribe_name'];
    } else if (json['subscribe'] != null && json['subscribe']['name'] != null) {
      groupName = json['subscribe']['name'];
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      groupName = json['name'];
    }
    
    print('[NodeGroup] Final group name: $groupName (subscribe_id: ${json['subscribe_id']})');
    
    return NodeGroup(
      subscriptionId: json['id'] ?? 0,
      groupName: groupName,
      nodes: json['nodes'] != null
          ? (json['nodes'] as List).map((node) => VpnNode.fromJson(node)).toList()
          : [],
    );
  }
}
