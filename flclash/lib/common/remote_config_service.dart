import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/remote_config.dart';
import 'package:crisp_chat/crisp_chat.dart';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class RemoteConfigService {
  static RemoteConfig? _config;
  // TODO: Replace with actual OSS URL
  static const String _remoteConfigUrl = 'https://wall-api.oss-cn-shenzhen.aliyuncs.com/config';
  
  // TODO: Replace with your actual Public Key (PEM format content)
  // Run scripts/sign_config.dart to generate keys, then paste public.pem content here.
  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArnwnBajX+e5XKYmW1mIC
KDS1AgFzIO2wnzXiYfQGpoburr2BeCWP3zJxi6xbYoQ2INV8L3+yBplaAuG6TG5s
pNy7d+rGYAGH0ONuv6McC8OJbZ8dqntYnT31YI0/yvWc6FEd2fqZYSfCr9AB8QIz
tRMe+NrLAS+XEnvZFVpB/MdO04vKUJWp35Fm+cRtotucPtzzucNAOReth/XjqyTc
zBUBMM5ek3jK+DsihO4mZt0cwPvPt7FFwtocpjDqn4Iw2UBKpRncWsKmIOw04sEb
uazDFyI8UrCEMkOj3TQTI5F59CfSgTyOY2+qCpwaJbY4b+fTwE8O2dxr61zXv98Z
FQIDAQAB
-----END PUBLIC KEY-----
''';

  static final ValueNotifier<RemoteConfig?> configNotifier = ValueNotifier<RemoteConfig?>(null);
  
  static RemoteConfig? get config => _config;
  // Sync wrapper for notifier
  static set config(RemoteConfig? value) {
    _config = value;
    configNotifier.value = value;
  }

  static Future<void> init() async {
    try {
      final response = await http.get(Uri.parse(_remoteConfigUrl));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final body = response.body.trim();
        
        // 1. Parse outer JSON { content, signature }
        Map<String, dynamic> jsonMap;
        try {
          print('[RemoteConfig] Parsing body: $body');
          jsonMap = jsonDecode(body);
        } catch (e) {
          print('[RemoteConfig] Parse error: $e');
          // Fallback for legacy format (raw base64 string)
          // Security Risk: If we allow fallback, an attacker can just use legacy format.
          // For transition, we might log warning. For strict security, we fail.
          commonPrint.log('RemoteConfig: Legacy format detected. Rejecting for security.');
          return;
        }
        
        final content = jsonMap['content'] as String?;
        final signature = jsonMap['signature'] as String?;
        
        if (content == null || signature == null) {
          commonPrint.log('RemoteConfig: Invalid format (missing content or signature).');
          return;
        }

        // 2. Verify Signature
        final bool isValid = _verifySignature(content, signature);
        if (!isValid) {
          commonPrint.log('RemoteConfig: FATAL - Signature Verification Failed! Potential Tampering!');
          // Terminate or use hardcoded default?
          // Using hardcoded default is safer than using tampered config.
          return;
        }
        
        // 3. Decode Verified Content
        final decodedString = utf8.decode(base64Decode(content));
        
        Map<String, dynamic> configJson;
        if (decodedString.trim().startsWith('{')) {
          configJson = jsonDecode(decodedString);
        } else {
          // Handle legacy query string format: ?domain=...
          try {
            // Remove leading '?' if present
            final queryString = decodedString.startsWith('?') ? decodedString.substring(1) : decodedString;
            final uriParams = Uri.splitQueryString(queryString);
            
            // Convert to RemoteConfig JSON format
            configJson = {
              'domain': uriParams['domain'] != null ? [uriParams['domain']] : [],
              // Add other fields if present in query string
            };
          } catch (e) {
            commonPrint.log('RemoteConfig: Failed to parse legacy content: $e');
            return;
          }
        }
        
        config = RemoteConfig.fromJson(configJson);
        commonPrint.log('RemoteConfig: Signature Verified & Loaded Successfully.');
      }
    } catch (e) {
      commonPrint.log('RemoteConfig Init Failed: $e');
    }
  }

  static bool _verifySignature(String content, String signatureBase64) {
    try {
      final parser = RSAKeyParser();
      // Verify signature using the public key
      // The key must match the private key used to sign the config uploaded to OSS.
      
      final publicKey = parser.parse(_publicKeyPem) as RSAPublicKey;
      final verifier = Signer(RSASigner(RSASignDigest.SHA256, publicKey: publicKey, privateKey: null));
      
      return verifier.verify64(content, signatureBase64);
    } catch (e) {
      commonPrint.log('RemoteConfig: Verification Logic Error: $e');
      return false;
    }
  }
}
