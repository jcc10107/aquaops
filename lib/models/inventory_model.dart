class InventoryModel {
  final String id;
  final String sku;
  final String name;
  final String category; // 'water', 'packaging'
  final int currentStock;
  final String unit;
  final int minimumThreshold;
  final double costPerUnit;

  InventoryModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.minimumThreshold,
    required this.costPerUnit,
  });

  bool get isLowStock => currentStock <= minimumThreshold;

  Map<String, dynamic> toMap() => {
    'sku': sku,
    'name': name,
    'category': category,
    'currentStock': currentStock,
    'unit': unit,
    'minimumThreshold': minimumThreshold,
    'costPerUnit': costPerUnit,
  };
}

class MaintenanceAlertModel {
  final String id;
  final String equipmentName;
  final String taskType;
  final String urgency; // 'critical', 'warning', 'routine'
  final DateTime dueDate;
  final bool isCompleted;

  MaintenanceAlertModel({
    required this.id,
    required this.equipmentName,
    required this.taskType,
    required this.urgency,
    required this.dueDate,
    this.isCompleted = false,
  });
}
