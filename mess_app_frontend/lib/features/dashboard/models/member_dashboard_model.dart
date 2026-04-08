class MemberDashboardModel {
  final String todayMenu;
  final String messStatus;
  final String tomorrowMessStatus;
  final int monthlyUnits;
  final double currentBill;
  final double dueAmount;

  const MemberDashboardModel({
    required this.todayMenu,
    required this.messStatus,
    required this.tomorrowMessStatus,
    required this.monthlyUnits,
    required this.currentBill,
    required this.dueAmount,
  });

  factory MemberDashboardModel.fromJson(Map<String, dynamic> json) {
    return MemberDashboardModel(
      todayMenu: (json['todayMenu'] ?? 'No menu available').toString(),
      messStatus: (json['messStatus'] ?? 'ON').toString(),
      tomorrowMessStatus: (json['tomorrowMessStatus'] ?? 'ON').toString(),
      monthlyUnits: json['monthlyUnits'] ?? 0,
      currentBill: (json['currentBill'] ?? 0).toDouble(),
      dueAmount: (json['dueAmount'] ?? 0).toDouble(),
    );
  }
}
