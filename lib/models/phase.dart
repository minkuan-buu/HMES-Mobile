class PhaseModel {
  String id;
  String? name;
  String status;

  PhaseModel({required this.id, this.name, required this.status});

  String getId() {
    return id;
  }

  String? getName() {
    return name;
  }

  String getStatus() {
    return status;
  }

  factory PhaseModel.fromJson(Map<String, dynamic> json) {
    return PhaseModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }
}

class PhaseGetModel {
  String phaseId;
  String? phaseName;
  List<PhaseTargetModel> target;

  PhaseGetModel({required this.phaseId, this.phaseName, required this.target});

  factory PhaseGetModel.fromJson(Map<String, dynamic> json) {
    return PhaseGetModel(
      phaseId: json['phaseId'],
      phaseName: json['phaseName'],
      target:
          (json['target'] as List)
              .map((item) => PhaseTargetModel.fromJson(item))
              .toList(),
    );
  }
}

class PhaseTargetModel {
  String id;
  String type;
  double minValue;
  double maxValue;

  PhaseTargetModel({
    required this.id,
    required this.type,
    required this.minValue,
    required this.maxValue,
  });

  factory PhaseTargetModel.fromJson(Map<String, dynamic> json) {
    return PhaseTargetModel(
      id: json['id'],
      type: json['type'],
      minValue: json['minValue'].toDouble(),
      maxValue: json['maxValue'].toDouble(),
    );
  }
}
