import 'dart:typed_data';
import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

abstract class FileDownloadHelper {
  static void downloadBytes(Uint8List bytes, String filename) {
    saveBytesAsFile(bytes, filename);
  }
}
