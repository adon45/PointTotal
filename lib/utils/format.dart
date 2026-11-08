String formatExactPoints(double points) {
  final value = points.toString();
  final decimalIndex = value.indexOf('.');
  if (decimalIndex == -1) {
    return '$value.00';
  }
  final decimalPlaces = value.length - decimalIndex - 1;
  return decimalPlaces < 2
      ? value.padRight(value.length + 2 - decimalPlaces, '0')
      : value;
}

String formatTotal(double total) => total.toStringAsFixed(2);
