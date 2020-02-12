# msgpack

Streaming API implementation of [MessagePack](https://msgpack.org/) binary serialization format.

## Installing

Check installing page section

## Getting Started

Packer and Unpacker classes provide Streaming API for serializing and deserializing data.

## Example

### Packer

```
    final p = Packer();
    p.packInt(1);
    p.packInt(2);
    final bytes = p.takeBytes(); //Uint8List
    send(bytes) //send to server
```

### Unpacker

```
    final List<int> rawBytes = receive() // receive List<int> bytes from server
    final u = Unpacker.fromList(rawBytes);
    final n1 = u.unpackInt();
    final n2 = u.unpackInt();
    expect(n1, equals(1));
    expect(n2, equals(2));
```


## NOTES

### Packing Maps and Iterables
* pack Map or Iterable header length 
* manually pack all items 

Only need put length header before packing items
After packing all items no need to stop  or finish or end this map / iterable

```
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


## Roadmap

* Sooner will be added convenient functions for automatically packing and unpacking from dart list / map

## Contributing

If you have advice how to improve library code or making it lighter or blazingly faster - don't hesitate to open an issue or pull request!