/// Routing group model with available options
class RoutingGroup {
  final String name;
  final List<String> options; // e.g., ['节点选择', '直连', 'aws-Sydney', ...]
  final String defaultOption;

  RoutingGroup({
    required this.name,
    required this.options,
    required this.defaultOption,
  });
}
