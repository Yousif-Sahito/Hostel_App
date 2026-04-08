class AdminDashboardModel {
  final int totalMembers;
  final int activeMembers;
  final int pendingBills;
  final double monthlyCollection;
  final String messStatus;
  final String todayMenu;
  final int tomorrowMessOffCount;

  const AdminDashboardModel({
    required this.totalMembers,
    required this.activeMembers,
    required this.pendingBills,
    required this.monthlyCollection,
    required this.messStatus,
    required this.todayMenu,
    required this.tomorrowMessOffCount,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalMembers: json['totalMembers'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      pendingBills: json['pendingBills'] ?? 0,
      monthlyCollection: (json['monthlyCollection'] ?? 0).toDouble(),
      messStatus: (json['messStatus'] ?? 'ON').toString(),
      todayMenu: (json['todayMenu'] ?? 'No menu available').toString(),
      tomorrowMessOffCount: json['tomorrowMessOffCount'] ?? 0,
    );
  }
}
