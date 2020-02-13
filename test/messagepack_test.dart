import 'dart:convert';
import 'dart:math';

import 'package:messagepack/messagepack.dart';
import 'package:test/test.dart';

int packUnpackInt(int v, {bool negative = false}) {
  final p = Packer();
  if (negative)
    p.packInt(v);
  else
    p.packInt(v);
  final u = Unpacker(p.takeBytes());
  return u.unpackInt();
}

double packUnpackDouble(double v) {
  final p = Packer();
  p.packDouble(v);
  final u = Unpacker(p.takeBytes());
  return u.unpackDouble();
}

String packUnpackString(String v) {
  final p = Packer();
  p.packString(v);
  final u = Unpacker(p.takeBytes());
  return u.unpackString();
}

final ints = [
  9223372036854775807,
  1581367842777,
  0,
  1581367842,
  127,
  5,
  128,
  null,
  128,
];

final negativeInts = ints.map((e) => e == null ? null : -1 * e).toList()
  ..add(-9223372036854775808);

final doubles = [
  0.0,
  null,
  1.1,
  null,
  null,
  12345678.12345668,
  null,
  -1.1,
  2.56,
  -34.567890,
  -23456.54,
  null,
  -1.0
];

final strs = [
  'hi',
  null,
  null,
  'Повседневная практика показывает, что постоянное информационно-пропагандистское обеспечение нашей деятельности в значительной степени обуславливает создание модели развития. Не следует, однако забывать, что реализация намеченных плановых заданий требуют от нас анализа форм развития. Не следует, однако забывать, что новая модель организационной деятельности требуют определения и уточнения модели развития. Равным образом постоянный количественный рост и сфера нашей активности требуют от нас анализа системы обучения кадров, соответствует насущным потребностям.',
  'mediul length string',
  '12345678901234567890123456789012345678901234567890',
  '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890',
  null,
  'str containing  кириллицу',
  'hi'
];

void main() {
  test('int sequentially increasing [independent]', () {
    for (int v = -65536; v < 65536; v++) {
      final r = packUnpackInt(v, negative: v < 0);
      expect(r, equals(v));
    }
  });

  test('Positive int [independent]', () {
    for (final v in ints) expect(packUnpackInt(v), equals(v));
  });

  test('Positive int [dependent]', () {
    final p = Packer();
    ints.forEach(p.packInt);
    final u = Unpacker(p.takeBytes());
    for (final v in ints) expect(u.unpackInt(), equals(v));
  });

  test('Negative int [independent]', () {
    for (final v in negativeInts)
      expect(packUnpackInt(v, negative: true), equals(v));
  });

  test('Negative int [dependent]', () {
    final p = Packer();
    negativeInts.forEach(p.packInt);
    final u = Unpacker(p.takeBytes());
    for (final v in negativeInts) expect(u.unpackInt(), equals(v));
  });

  test('Double [independent]', () {
    for (final v in doubles) expect(packUnpackDouble(v), equals(v));
  });

  test('Double [dependent]', () {
    final p = Packer();
    doubles.forEach(p.packDouble);
    final u = Unpacker(p.takeBytes());
    for (final v in doubles) expect(u.unpackDouble(), equals(v));
  });

  test('String [independent]', () {
    for (final v in strs) expect(packUnpackString(v), equals(v));
  });

  test('String [dependent]', () {
    final p = Packer();
    strs.forEach(p.packString);
    final u = Unpacker(p.takeBytes());
    for (final v in strs) expect(u.unpackString(), equals(v));
  });

  List<MapEntry<int, dynamic>> randomiseData() {
    final rands = <MapEntry<int, dynamic>>[];
    MapEntry<int, dynamic> me(int k, dynamic v) => MapEntry<int, dynamic>(k, v);
    final r = Random();

    dynamic nullOr(dynamic transform(int v)) {
      return r.nextInt(10) == 0 ? null : transform(r.nextInt(4294967296));
    }

    for (int i = 0; i < 200; i++) {
      final t = r.nextInt(5);
      if (t == 0) rands.add(me(t, null));
      if (t == 1) rands.add(me(t, nullOr((v) => v % 3 == 0)));
      if (t == 2) rands.add(me(t, nullOr((v) => v)));
      if (t == 3) rands.add(me(t, nullOr((v) => v * -1)));
      if (t == 4)
        rands.add(me(t,
            nullOr((v) => r.nextDouble() * v * (r.nextInt(2) == 1 ? -1 : 1))));
      if (t == 5) rands.add(me(t, nullOr((v) => strs[r.nextInt(strs.length)])));
    }
    return rands;
  }

  void pack(Packer p, MapEntry<int, dynamic> e) {
    if (e.key == 0) p.packNull();
    if (e.key == 1) p.packBool(e.value as bool);
    if (e.key == 2) p.packInt(e.value as int);
    if (e.key == 3) p.packInt(e.value as int);
    if (e.key == 4) p.packDouble(e.value as double);
    if (e.key == 5) p.packString(e.value as String);
  }

  dynamic unpack(Unpacker u, int type) {
    if (type == 0) return unpack(u, Random().nextInt(4) + 1);
    if (type == 1) return u.unpackBool();
    if (type == 2) return u.unpackInt();
    if (type == 3) return u.unpackInt();
    if (type == 4) return u.unpackDouble();
    if (type == 5) return u.unpackString();
  }

  test('Random different [independent]', () {
    final l = randomiseData();
    for (final e in l) {
      final p = Packer();
      pack(p, e);
      final u = Unpacker(p.takeBytes());
      expect(unpack(u, e.key), equals(e.value));
    }
  });

  test('Random different [dependent]', () {
    final l = randomiseData();
    final p = Packer();
    for (final e in l) {
      pack(p, e);
    }
    final u = Unpacker(p.takeBytes());
    for (int i = 0; i < l.length; i++) {
      expect(unpack(u, l[i].key), equals(l[i].value));
    }
  });

  test('Iterable [dependent]', () {
    final list = [
      'value1 short',
      'value2 medium medium',
      'value3 with кириллица кириллица кириллица',
      'value4 with long long text that so long long long long long long long long long long',
      'value5',
      'v6'
    ];
    final p = Packer();
    p.packNull();
    p.packIterableLength(null);
    p.packIterableLength(0);
    p.packIterableLength(list.length);
    list.forEach(p.packString);
    p.packBool(true);
    p.packIterableLength(list.length);
    list.forEach(p.packString);
    p.packInt(3);
    final u = Unpacker(p.takeBytes());
    expect(u.unpackIterableLength(), equals(0));
    expect(u.unpackIterableLength(), equals(0));
    expect(u.unpackIterableLength(), equals(0));
    final length = u.unpackIterableLength();
    for (int i = 0; i < length; i++) {
      expect(u.unpackString(), equals(list[i]));
    }
    expect(u.unpackBool(), equals(true));
    final length2 = u.unpackIterableLength();
    for (int i = 0; i < length2; i++) {
      expect(u.unpackString(), equals(list[i]));
    }
    expect(u.unpackInt(), equals(3));
  });

  test('Iterable different types [dependent]', () {
    final list = [
      -65999,
      -34855,
      -128,
      -31,
      -1,
      0,
      null,
      124,
      1581367842,
      1581367842777,
      null,
      'short string',
      'string with medium length',
      true,
      null,
      false,
      -3.14,
      0.5,
      36.6,
      null,
      100.0,
    ];
    final p = Packer();
    p.packIterableLength(list.length);
    for (int i = 0; i < 10; i++) {
      p.packInt(list[i] as int);
    }
    for (int i = 10; i < 13; i++) {
      p.packString(list[i] as String);
    }
    for (int i = 13; i < 16; i++) {
      p.packBool(list[i] as bool);
    }
    for (int i = 16; i < 21; i++) {
      p.packDouble(list[i] as double);
    }
    final u = Unpacker(p.takeBytes());
    expect(u.unpackIterableLength(), equals(list.length));
    for (int i = 0; i < 10; i++) {
      expect(u.unpackInt(), equals(list[i]));
    }
    for (int i = 10; i < 13; i++) {
      expect(u.unpackString(), equals(list[i]));
    }
    for (int i = 13; i < 16; i++) {
      expect(u.unpackBool(), equals(list[i]));
    }
    for (int i = 16; i < 21; i++) {
      expect(u.unpackDouble(), equals(list[i]));
    }
  });

  test('Map [dependent]', () {
    final map = {
      1: 11,
      2: 22,
      3: 33,
    };
    final p = Packer();
    p.packNull();
    p.packMapLength(null);
    p.packMapLength(0);
    p.packMapLength(map.length);
    for (int i = 0; i < map.length; i++) {
      p.packInt(i);
      p.packInt(map[i]);
    }
    p.packBool(true);
    p.packMapLength(map.length);
    for (int i = 0; i < map.length; i++) {
      p.packInt(i);
      p.packInt(map[i]);
    }
    p.packInt(3);
    final u = Unpacker(p.takeBytes());
    expect(u.unpackMapLength(), equals(0));
    expect(u.unpackMapLength(), equals(0));
    expect(u.unpackMapLength(), equals(0));
    final length = u.unpackMapLength();
    for (int i = 0; i < length; i++) {
      expect(u.unpackInt(), equals(i));
      expect(u.unpackInt(), equals(map[i]));
    }
    expect(u.unpackBool(), equals(true));
    final length2 = u.unpackMapLength();
    for (int i = 0; i < length2; i++) {
      expect(u.unpackInt(), equals(i));
      expect(u.unpackInt(), equals(map[i]));
    }
    expect(u.unpackInt(), equals(3));
  });

  test('Binary [dependent]', () {
    final bytes1 = utf8.encode('hi');
    final bytes2 = utf8.encode(
        'Значимость этих проблем настолько очевидна, что укрепление и развитие структуры представляет собой интересный эксперимент проверки систем массового участия. Задача организации, в особенности же постоянное информационно-пропагандистское обеспечение нашей деятельности обеспечивает широкому кругу (специалистов) участие в формировании систем массового участия. Товарищи! постоянный количественный рост и сфера нашей активности требуют определения и уточнения соответствующий условий активизации. Задача организации, в особенности же консультация с широким активом влечет за собой процесс внедрения и модернизации форм развития. Равным образом начало повседневной работы по формированию позиции позволяет оценить значение соответствующий условий активизации.');
    final empty = <int>[];
    final p = Packer();
    p.packBinary(null);
    p.packBinary(empty);
    p.packBinary(bytes1);
    p.packBool(true);
    p.packBinary(bytes2);
    p.packInt(3);
    final u = Unpacker(p.takeBytes());
    expect(u.unpackBinary(), equals(empty));
    expect(u.unpackBinary(), equals(empty));
    expect(u.unpackBinary(), equals(bytes1));
    expect(u.unpackBool(), equals(true));
    expect(u.unpackBinary(), equals(bytes2));
    expect(u.unpackInt(), equals(3));
  });

  test('Manual int example [dependent]', () {
    final p = Packer();
    p.packInt(1);
    p.packInt(2);
    final bytes = p.takeBytes();
    //send bytes to server
    //receive bytes from server
    final u = Unpacker(bytes);
    final n1 = u.unpackInt();
    final n2 = u.unpackInt();
    expect(n1, equals(1));
    expect(n2, equals(2));
  });

  test('Map Iterable example [dependent]', () {
    final list = ['i1', 'i2'];
    final map = {'k1': 11, 'k2': 22};
    final p = Packer();
    p.packIterableLength(list.length);
    list.forEach(p.packString);
    p.packMapLength(map.length);
    map.forEach((key, v) {
      p.packString(key);
      p.packInt(v);
    });
    final bytes = p.takeBytes();
    Unpacker(bytes);
  });

  test('Different types example [dependent]', () {
    final p = Packer()
      ..packInt(99)
      ..packBool(true)
      ..packString('hi')
      ..packNull()
      ..packString(null)
      ..packBinary(<int>[104, 105]) // hi codes
      ..packIterableLength(2) // pack 2 elements list ['elem1',3.14]
      ..packString('elem1')
      ..packDouble(3.14)
      ..packString('continue to pack other elements')
      ..packMapLength(1) //map {'key1':false}
      ..packString('key');

    final bytes = p.takeBytes();
    Unpacker(bytes);
  });
}
