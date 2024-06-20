import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignInAccount googleSignInAccount;

  GoogleDriveService(this.googleSignInAccount);

  Future<drive.DriveApi> getDriveApi() async {
    final authHeaders = await googleSignInAccount.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
  }

  Future<void> uploadFile(String content, String fileName) async {
    final driveApi = await getDriveApi();

    final media = drive.Media(
      Stream.value(utf8.encode(content)),
      content.length,
    );

    final driveFile = drive.File()..name = fileName;
    final files = (await driveApi.files.list()).files;

    if (files == null || files.isEmpty) {
      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      return;
    }

    for (var file in files) {
      if (file.name == fileName && file.trashed != true) {
        await driveApi.files.update(
          driveFile,
          file.id!,
          uploadMedia: media,
        );
        return;
      }
    }
  }

  Future<String?> downloadFile(
    String fileName,
  ) async {
    final driveApi = await getDriveApi();
    var files = await driveApi.files.list();
    for (var file in files.files!) {
      if (file.name == fileName && file.trashed != true) {
        final media = await driveApi.files.get(
          file.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        final fileBytes = await media.toBytes();
        return utf8.decode(fileBytes);
      }
    }
    return null;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

extension on drive.Media {
  Future<List<int>> toBytes() async {
    final completer = Completer<List<int>>();
    final bytes = <int>[];
    stream.listen(
      bytes.addAll,
      onDone: () => completer.complete(bytes),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }
}
