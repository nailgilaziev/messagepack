import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// packXXX can handle null values.
/// separate packNull function exist.
class Packer {
  /// Provide the size, that minimal enough to fit your most used data packets.
  Packer([this._bufSize = 64]) {
    _newBuf(_bufSize);
  }

  int _bufSize;

  Uint8List _buf;
  ByteData _d;
  int _offset;

  void _newBuf(int size) {
    _buf = Uint8List(size);
    _d = ByteData.view(_buf.buffer, _buf.offsetInBytes);
    _offset = 0;
  }

  final _builder = BytesBuilder(copy: false);
  final _strCodec = const Utf8Codec();

  void _nextBuf() {
    _flushBuf();
    _bufSize = _bufSize *= 2;
    _newBuf(_bufSize);
  }

  /// Flush [_buf] to [_builder] when [_buf] if almost full
  /// or when packer completes his job and transforms to bytes
  void _flushBuf() {
    _builder.add(Uint8List.view(
      _buf.buffer,
      _buf.offsetInBytes,
      _offset,
    ));
  }

  /// Pack binary and string uses this internally.
  void _putBytes(List<int> bytes) {
    final length = bytes.length;
    if (_buf.length - _offset < length) _nextBuf();
    if (_offset == 0) {
      /// buf flushed to builder, next new buf created, so we can write directly to builder
      _builder.add(bytes);
    } else {
      /// buf has space for us
      _buf.setRange(_offset, _offset + length, bytes);
      _offset += length;
    }
  }

  /// Explicitly pack null value.
  /// Other packXXX implicitly handle null values.
  void packNull() {
    if (_buf.length - _offset < 1) _nextBuf();
    _d.setUint8(_offset++, 0xc0);
  }

  /// Pack [bool] or `null`.
  void packBool(bool v) {
    if (_buf.length - _offset < 1) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
    } else {
      _d.setUint8(_offset++, v ? 0xc3 : 0xc2);
    }
  }

  /// Pack [int] or `null`.
  void packInt(int v) {
    // max 8 byte int + 1 control byte
    if (_buf.length - _offset < 9) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (v >= 0) {
      if (v <= 127) {
        _d.setUint8(_offset++, v);
      } else if (v <= 0xFF) {
        _d.setUint8(_offset++, 0xcc);
        _d.setUint8(_offset++, v);
      } else if (v <= 0xFFFF) {
        _d.setUint8(_offset++, 0xcd);
        _d.setUint16(_offset, v);
        _offset += 2;
      } else if (v <= 0xFFFFFFFF) {
        _d.setUint8(_offset++, 0xce);
        _d.setUint32(_offset, v);
        _offset += 4;
      } else {
        _d.setUint8(_offset++, 0xcf);
        _d.setUint64(_offset, v);
        _offset += 8;
      }
    } else if (v >= -32) {
      _d.setInt8(_offset++, v);
    } else if (v >= -128) {
      _d.setUint8(_offset++, 0xd0);
      _d.setInt8(_offset++, v);
    } else if (v >= -32768) {
      _d.setUint8(_offset++, 0xd1);
      _d.setInt16(_offset, v);
      _offset += 2;
    } else if (v >= -2147483648) {
      _d.setUint8(_offset++, 0xd2);
      _d.setInt32(_offset, v);
      _offset += 4;
    } else {
      _d.setUint8(_offset++, 0xd3);
      _d.setInt64(_offset, v);
      _offset += 8;
    }
  }

  /// Pack [double] or `null`.
  void packDouble(double v) {
    // 8 byte double + 1 control byte
    if (_buf.length - _offset < 9) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    _d.setUint8(_offset++, 0xcb);
    _d.setFloat64(_offset, v);
    _offset += 8;
  }

  /// Pack [String] or `null`.
  ///
  /// Depending on whether your distinguish empty [String] from `null` or not:
  /// - Empty and `null` is same: consider pack empty [String] to `null`, to save 1 byte on a wire.
  /// ```
  /// p.packStringEmptyIsNull(s) //or
  /// p.packString(s.isEmpty ? null : s) //or
  /// s.isEmpty ? p.packNull() : p.packString(s)
  /// ```
  /// - Empty and `null` distinguishable: no action required just save `p.packString(s)`.
  /// Throws [ArgumentError] if [String.length] exceed (2^32)-1.
  void packString(String v) {
    // max 4 byte str header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    final encoded = _strCodec.encode(v);
    final length = encoded.length;
    if (length <= 31) {
      _d.setUint8(_offset++, 0xA0 | length);
    } else if (length <= 0xFF) {
      _d.setUint8(_offset++, 0xd9);
      _d.setUint8(_offset++, length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xda);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdb);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max String length is 0xFFFFFFFF');
    }
    _putBytes(encoded);
  }

  /// Convenient function that call [packString(String v)] by passing empty [String] as `null`.
  ///
  /// Convenient when you not distinguish between empty [String] and null on MsgPack wire.
  /// See [packString()] method documentation for more details.
  void packStringEmptyIsNull(String v) {
    if (v == null)
      packNull();
    else
      packString(v.isEmpty ? null : v);
  }

  /// Pack `List<int>` or null.
  void packBinary(List<int> buffer) {
    // max 4 byte binary header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (buffer == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    final length = buffer.length;
    if (length <= 0xFF) {
      _d.setUint8(_offset++, 0xc4);
      _d.setUint8(_offset++, length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xc5);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xc6);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max binary length is 0xFFFFFFFF');
    }
    _putBytes(buffer);
  }

  /// Pack [Iterable.length] or `null`.
  void packIterableLength(int length) {
    // max 4 length header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (length == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (length <= 0xF) {
      _d.setUint8(_offset++, 0x90 | length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xdc);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdd);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max iterable length is 0xFFFFFFFF');
    }
  }

  /// Pack [Map.length] or `null`.
  void packMapLength(int length) {
    // max 4 byte header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (length == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (length <= 0xF) {
      _d.setUint8(_offset++, 0x80 | length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xde);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdf);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max map length is 0xFFFFFFFF');
    }
  }

  /// Get bytes representation of this packer.
  /// Note: after this call do not reuse packer - create new.
  Uint8List takeBytes() {
    Uint8List bytes;
    if (_builder.isEmpty) {
      bytes = Uint8List.view(
        _buf.buffer,
        _buf.offsetInBytes,
        _offset,
      );
    } else {
      _flushBuf();
      bytes = _builder.takeBytes();
    }
    return bytes;
  }
}
