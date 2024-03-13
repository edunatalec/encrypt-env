enum GeneratorFormat {
  screamingSnakeCase('ssc'),
  camelCase('cc'),
  snakeCase('sc');

  final String name;

  const GeneratorFormat(this.name);
}
