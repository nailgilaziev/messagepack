Streaming API implementation of [MessagePack](https://msgpack.org/) binary serialization format - msgpack.

# Getting Started

`Packer` and `Unpacker` classes provide Streaming API for serializing and deserializing data.

# Example - Simple

## Packer

```dart
import 'package:messagepack/messagepack.dart';
```

```dart
final p = Packer();
p.packInt(1);
p.packInt(2);
final bytes = p.takeBytes(); //Uint8List
send(bytes) //send to server
```

## Unpacker

```dart
final List<int> rawBytes = receive() // receive List<int> bytes from server
final u = Unpacker.fromList(rawBytes);
final n1 = u.unpackInt();
final n2 = u.unpackInt();
// check values in test
expect(n1, equals(1));
expect(n2, equals(2));
```


# Example - Different types

## Packer

```dart
final p = Packer();
p.packInt(1);
p.packBool(true);
final bytes = p.takeBytes(); //Uint8List
send(bytes) //send to server
```

## Unpacker

```dart
final List<int> rawBytes = receive() // receive List<int> bytes from server
final u = Unpacker.fromList(rawBytes);
print(u.unpackInt());
print(u.unpackBool());
```

# Example - complex 

```dart
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
    ..packMapLength(2) //map {'key1':false, 'key2',3.14}
    ..packString('key1') //pack key1
    ..packBool(false) //pack value1
    ..packString('key12') //pack key1
    ..packDouble(3.13); //pack value1

  final bytes = p.takeBytes();
  final u = Unpacker(bytes);
  //Unpack the same sequential/streaming way
```

# NOTES

## Packing Maps and Iterables
* firstly, pack Map or Iterable header length 
* secondly, manually pack all items - that's all 

Only need put length header before packing items 

After packing all items no need to stop  or finish or end this map / iterable

```dart
final list = ['i1','i2'];
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
```

## More examples

More examples can be found in:
* test/messagepack_test.dart
* example/example.dart

## Don't use Packer after calling .takeBytes()

Internally it cleans up underlying _builder, so further behaviour will be useless.  
Call .takeBytes() only once. It returns Uint8List of packed bytes.
After that call don't continue to use Packer instance (don't call .packXXX() methods and .takeBytes())
Instead, create new Packer instance method.


# Roadmap

* Sooner will be added convenient functions for automatically packing and unpacking from dart list / map

# Contributing

If you have advice how to improve library code or making it lighter or blazingly faster - don't hesitate to open an issue or pull request!