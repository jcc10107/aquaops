import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'klljcx86';

  // Same Worker used for push notifications — it holds the Cloudinary API
  // secret server-side and hands back a one-time upload signature. Used to
  // be an *unsigned* upload preset here instead, which had no server-side
  // authorization at all: anyone who pulled the cloud name/preset out of
  // the compiled app (both are plain strings, trivial to extract) could
  // upload arbitrary files to this Cloudinary account from outside the app
  // entirely. A signed upload is verified by Cloudinary itself.
  static const String _workerUrl = 'https://aquaops.jamesdevilla08.workers.dev';
  static const String _workerSecret = String.fromEnvironment('WORKER_SECRET');

  Future<String> uploadImage(Uint8List bytes, {String filename = 'upload.jpg', String? folder}) async {
    final signResponse = await http
        .post(
          Uri.parse(_workerUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_workerSecret',
          },
          body: jsonEncode({'cloudinarySign': true, if (folder != null) 'folder': folder}),
        )
        .timeout(const Duration(seconds: 10));
    if (signResponse.statusCode != 200) {
      throw Exception('Could not authorize upload: ${signResponse.statusCode}');
    }
    final signData = jsonDecode(signResponse.body) as Map<String, dynamic>;
    final signature = signData['signature'] as String;
    final timestamp = signData['timestamp'] as int;
    final apiKey = signData['apiKey'] as String;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    if (folder != null) {
      request.fields['folder'] = folder;
    }
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
