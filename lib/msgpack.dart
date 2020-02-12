/// Library for manual streaming packing and unpacking MsgPack data.
///
/// Packer and Unpacker classes provides serializing and deserializing functions.
/// Use packXXX, unpackXXX, isNull, isXXX methods, where XXX is a primitive types names.
/// For working with iterables and maps - write header before and after manually pack items
library msgpack;


export 'src/packer.dart';
export 'src/unpacker.dart';


