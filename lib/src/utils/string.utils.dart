final RegExp regex = RegExp(r'[_-]');

extension StringExtension on String {
  String toPascalCase() {
    final List<String> words =
        trim().toLowerCase().split(regex).where((element) {
      return element.isNotEmpty;
    }).toList();

    return words.fold('', (previousValue, element) {
      return previousValue + (element[0].toUpperCase() + element.substring(1));
    });
  }

  String toCamelCase() {
    final String text = toPascalCase();

    return text.isEmpty ? '' : text[0].toLowerCase() + text.substring(1);
  }
}
