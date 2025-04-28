String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

String capitalizeName(String name) {
  return name.split(' ').map((part) => capitalize(part)).join(' ');
}