class IrrigationRecord {
  double amount;
  double duration;
  DateTime time;
  String userName;

  IrrigationRecord(
      {required this.userName, required this.amount, required this.duration, required this.time});
}
