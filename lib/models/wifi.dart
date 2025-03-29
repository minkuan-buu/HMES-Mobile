class WifiModel {
  String ssid;
  int rssi;

  WifiModel({required this.ssid, required this.rssi});

  String getSsid() {
    return ssid;
  }

  int getRssi() {
    return rssi;
  }

  factory WifiModel.fromJson(Map<String, dynamic> json) {
    return WifiModel(ssid: json['ssid'], rssi: json['rssi']);
  }
}
