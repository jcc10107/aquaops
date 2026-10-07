import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String sku;
  final String name;
  final String category;
  final int currentStock;
  final int maxCapacity;
  final String unit;
  final int minimumThreshold;
  final double costPerUnit;

  InventoryModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.maxCapacity,
    required this.unit,
    required this.minimumThreshold,
    required this.costPerUnit,
  });

  bool get isLowStock => currentStock <= minimumThreshold;

  factory InventoryModel.fromMap(Map<String, dynamic> data, String id) {
    return InventoryModel(
      id: id,
      sku: data['sku'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'water',
      currentStock: (data['currentStock'] ?? 0).toInt(),
      maxCapacity: (data['maxCapacity'] ?? 0).toInt(),
      unit: data['unit'] ?? 'pcs',
      minimumThreshold: (data['minimumThreshold'] ?? 0).toInt(),
      costPerUnit: (data['costPerUnit'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sku': sku,
    'name': name,
    'category': category,
    'currentStock': currentStock,
    'maxCapacity': maxCapacity,
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

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  factory MaintenanceAlertModel.fromMap(Map<String, dynamic> data, String id) {
    final dueDateRaw = data['dueDate'];
    return MaintenanceAlertModel(
      id: id,
      equipmentName: data['equipmentName'] ?? '',
      taskType: data['taskType'] ?? '',
      urgency: data['urgency'] ?? 'routine',
      dueDate: dueDateRaw is Timestamp ? dueDateRaw.toDate() : DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'equipmentName': equipmentName,
    'taskType': taskType,
    'urgency': urgency,
    'dueDate': Timestamp.fromDate(dueDate),
    'isCompleted': isCompleted,
  };
}
