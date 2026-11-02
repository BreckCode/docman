import 'dart:convert';

import 'package:docman/docman.dart';
import 'package:docman/src/methods/document_file_methods.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('devdf.plugins/docman/action');

DocumentFile _doc({required String type}) => DocumentFile(
      name: 'a.txt',
      type: type,
      uri: 'content://test/a.txt',
      size: 0,
      lastModified: 0,
      exists: true,
      canRead: true,
      canWrite: true,
      canDelete: true,
      canCreate: true,
      canThumbnail: false,
    );

Map<String, Object?> _result(String uri) => {
      'name': 'a.txt',
      'type': 'text/plain',
      'uri': uri,
      'size': 1,
      'lastModified': 0,
      'exists': true,
      'canRead': true,
      'canWrite': true,
      'canDelete': true,
      'canCreate': false,
      'canThumbnail': false,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const samples = ['plain ascii', 'é © — “quotes”', 'नमस्ते 你好', 'emoji 😀👍🏽'];

  group('encodeContent', () {
    for (final s in samples) {
      test('round-trips "$s" through UTF-8', () {
        final bytes = DocumentFileMethods.encodeContent(s);
        expect(bytes, equals(utf8.encode(s)));
        expect(utf8.decode(bytes), s);
      });
    }
  });

  group('native args', () {
    final captured = <Map<dynamic, dynamic>>[];

    setUp(() {
      captured.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        final args = Map<dynamic, dynamic>.from(call.arguments as Map);
        captured.add(args);
        return _result(args['uri'] as String);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('writeFile sends UTF-8 bytes for string content', () async {
      const text = 'héllo 你好 😀';
      await _doc(type: 'text/plain').writeFile(content: text);
      final sent = captured.single['content'] as Uint8List;
      expect(utf8.decode(sent), text);
    });

    test('createFile sends UTF-8 bytes for string content', () async {
      const text = 'const s = "€";';
      await _doc(type: 'directory').createFile(name: 'b.js', content: text);
      final sent = captured.single['content'] as Uint8List;
      expect(utf8.decode(sent), text);
    });

    test('raw bytes are passed through untouched', () async {
      final raw = Uint8List.fromList([0, 255, 128, 7]);
      await _doc(type: 'text/plain').writeFile(bytes: raw);
      expect(captured.single['content'], raw);
    });
  });
}
