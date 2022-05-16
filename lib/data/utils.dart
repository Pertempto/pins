import 'dart:math';

String generateId({required int length}) {
  String id = '';
  String options = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Random rand = Random();
  for (int i = 0; i < length; i++) {
    id += options[rand.nextInt(options.length)];
  }
  return id;
}
