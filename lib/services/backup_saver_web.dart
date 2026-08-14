import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('gestorSaveBackup')
external JSPromise<JSBoolean> _gestorSaveBackup(JSString content, JSString filename);

class BackupSaver {
  static Future<bool> save(Uint8List bytes, String filename) async {
    try {
      final content = base64Encode(bytes);
      final result = await _gestorSaveBackup(
        content.toJS,
        filename.toJS,
      ).toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }
}
