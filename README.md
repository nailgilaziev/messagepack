Streaming API implementation of [MessagePack](https://msgpack.org/) binary serialization format - msgpack.

[![pub package](https://img.shields.io/pub/v/messagepack.svg)](https://pub.dartlang.org/packages/messagepack)

## The basics

`Packer` and `Unpacker` classes provide Streaming API for serializing and deserializing data.  
`Unpacker` also provide automatic unpacking `Map` and `List` by implicitly unpacking internal items.

## Streaming API Example - Simple

For the simplest data packaging to bytes packet like this: 
```
-------------------------------------------   
| version | userId | broadcast? | message |
-------------------------------------------
```

### Packer part

```dart
import 'package:messagepack/messagepack.dart';
```

```dart
final p = Packer();
p.packInt(1); // packet format version
p.packInt(222); // user id
p.packBool(false); // broadcast message to others
p.packString('hi'); // user message text
final bytes = p.takeBytes(); //Uint8List
yourFunctionSendToServer(bytes); //sends [1, 204, 222, 195, 162, 104, 105]
```
> `1` encodes to 1 byte with value 1.  
> `222` encodes to 2 bytes with values [204, 222] because 222 > 127.  
> `true` encodes to 1 byte with value 195.  
> `'hi'` encodes to 3 bytes with first byte containing str length info and other 2 bytes hold symbols values.  

> For more information, refer to the [msgpack](https://msgpack.org/) documentation.  

Streaming packing process not like the way we usually pack data in json, by specifying keys.  
The current example is more like how data is packed in TCP/IP frame structure.

### Unpacker part

```dart
final List<int> rawBytes = yourFunctionReceiveFromServer(); // receive List<int> bytes from server
final u = Unpacker.fromList(rawBytes);
final version = u.unpackInt();
final userId = u.unpackInt();
final broadcast = u.unpackBool();
final message = u.unpackString();

// check values in test
expect(version, equals(1));
expect(userId, equals(222));
expect(broadcast, equals(true));
expect(message, equals('hi'));

```

## Streaming packing and automatic/implicit unpacking example - complex

```dart
final p = Packer()
  ..packListLength(10)              //pack 10 different types items to list
  ..packInt(99)
  ..packBool(true)
  ..packString('hi')
  ..packNull()                      // explicitly pack null
  ..packString(null)                // implicitly any type can accept null 
  ..packBinary(<int>[104, 105])     // hi codes
  ..packListLength(2)               // pack 2 elements list ['elem1',3.14]
  ..packString('elem1')             // list[0]
  ..packDouble(3.14)                // list[1]
  ..packString('continue to pack other elements')
  ..packMapLength(1)                // map {'key1':false}
  ..packString('key1')              // map key
  ..packBool(false)                 // map value 
  ..packInt(9223372036854775807);   // next root list item (map ended)

final bytes = p.takeBytes();
final u = Unpacker(bytes);
// Unpack by the same sequential/streaming way 
// or implicitly/automatically
final l = u.unpackList(); //List<Object>
print(l);
// [99, true, hi, null, null, [104, 105], [elem1, 3.14], continue to pack other elements, {key1: false}, 9223372036854775807]
```

`List<Object>` items explicitly casted to corresponding types when using.

## NOTES

### Packing Maps and Lists
* firstly, pack Map or List header length 
* secondly, manually pack all items - that's all 

Only need put length header before packing items 

After packing all items no need to stop or finish or end this map / list

```dart
final list = ['i1','i2'];
final map = {'k1': 11, 'k2': 22};
final p = Packer();
p.packListLength(list.length);
list.forEach(p.packString);
p.packMapLength(map.length);
map.forEach((key, v) {
  p.packString(key);
  p.packInt(v);
});
final bytes = p.takeBytes();
```

### More examples

More examples can be found in:
* `test/messagepack_test.dart`
* `example/example.dart`

### Don't use Packer after calling .takeBytes()

Internally it cleans up underlying _builder, so further behaviour will be useless.  
Call .takeBytes() only once. It returns Uint8List of packed bytes.
After that call don't continue to use Packer instance (don't call .packXXX() methods and .takeBytes())
Instead, create new Packer instance method.

### Motivation for creating this package

No other packages available that give streaming API for processing data 

## Contributing

If you have advice how to improve library code or making it lighter or blazingly faster - don't hesitate to open an issue or pull request!
