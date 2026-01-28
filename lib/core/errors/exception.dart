class BleException {
  final String message;
  final String? code;

  BleException(this.message, {this.code});

  @override
  String toString() => message;
}
