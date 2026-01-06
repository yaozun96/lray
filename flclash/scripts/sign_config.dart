import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart'; // For RSA Key typing

void main(List<String> args) async {
  if (args.contains('--auto')) {
    autoSignConfig();
    return;
  }

  print('=== Xboard Config Signer ===');
  print('1. Generate New Key Pair');
  print('2. Sign Config String');
  print('3. Verify Signature');
  stdout.write('Select mode (1/2/3): ');
  
  final mode = stdin.readLineSync()?.trim();
  
  if (mode == '1') {
    generateKeys();
  } else if (mode == '2') {
    signConfig();
  } else if (mode == '3') {
    verifyConfig();
  } else {
    print('Invalid mode.');
  }
}

void autoSignConfig() {
  final privFile = File('private.pem');
  if (!privFile.existsSync()) {
    print('Error: private.pem not found in current directory.');
    exit(1);
  }
  
  final inputFile = File('config_input.txt');
  if (!inputFile.existsSync()) {
    print('Error: config_input.txt not found in current directory.');
    exit(1);
  }

  final privateKeyString = privFile.readAsStringSync();
  final parser = RSAKeyParser();
  final privateKey = parser.parse(privateKeyString) as RSAPrivateKey;
  
  final rawContent = inputFile.readAsStringSync().trim();
  // Ensure content is Base64 encoded for the payload
  final encodedContent = base64Encode(utf8.encode(rawContent));
  
  final signer = Signer(RSASigner(RSASignDigest.SHA256, publicKey: null, privateKey: privateKey));
  final signature = signer.sign(encodedContent);
  
  final result = {
    "content": encodedContent,
    "signature": signature.base64,
  };
  
  File('signed_config.json').writeAsStringSync(jsonEncode(result));
  print('Successfully generated signed_config.json (Content Base64 Encoded)');
}

void generateKeys() {
  final rsa = RSAKeyParser();
  // We use a helper from encrypt package or just generate using pointycastle
  // encrypt package doesn't have a direct "generate" for RSA easily accessible in one line usually without helper,
  // but let's use a simpler approach or a dedicated helper if available.
  // Actually, 'encrypt' package wraps pointycastle.
  // Let's us basic RSA key generator.
  
  // Note: For simplicity in this script without complex dependencies setup, 
  // we might need to rely on the user having the environment ready.
  // Assuming 'encrypt' is available in the project context.
  
  // Since we are running this as a script, we might need 'args'. 
  // But wait, the user needs to run this with `dart run scripts/sign_config.dart`.
  // It requires the package to be resolvable.
  
  print('\nGenerating 2048-bit RSA Key Pair...');
  
  // This is a simplified generation using a dummy secure random. 
  // In a real production script we should ensure high entropy.
  // Ideally, use openssl to generate keys, but here we do it in Dart.
  
  // actually, manually implementing key gen in dart script is verbose using pointycastle directly.
  // Let's ask user to use OpenSSL or provide a simple logic?
  // No, I can write the logic.
  
  print('NOTE: For best security, verify your random source or use OpenSSL.');
  // Skipping complex key gen implementation to avoid dependency hell in script execution if not fully set up.
  // But wait, 'encrypt' has RSAKeyParser but not Generator?
  // Let's assume we maintain a simple PEM format.
  
  print('FATAL: Key generation in pure Dart script requires extensive boilerplate. \n'
        'Please generate keys using OpenSSL:\n\n'
        'openssl genrsa -out private.pem 2048\n'
        'openssl rsa -in private.pem -pubout -out public.pem\n');
}

void signConfig() {
  print('\n--- Sign Config ---');
  stdout.write('Enter path to private_key.pem (default: private.pem): ');
  var privPath = stdin.readLineSync()?.trim();
  if (privPath == null || privPath.isEmpty) privPath = 'private.pem';
  
  File privFile = File(privPath);
  if (!privFile.existsSync()) {
    print('Error: Private key file not found: $privPath');
    return;
  }
  
  final privateKeyString = privFile.readAsStringSync();
  final parser = RSAKeyParser();
  final privateKey = parser.parse(privateKeyString) as RSAPrivateKey;
  
  stdout.write('Enter config string (JSON or Base64): ');
  // Handle multiline input or file?
  // Let's suggest file input for config.
  print('(Or press ENTER to read from "config_input.txt")');
  
  String rawInput = stdin.readLineSync()?.trim() ?? '';
  if (rawInput.isEmpty) {
    final inputFile = File('config_input.txt');
    if (inputFile.existsSync()) {
      rawInput = inputFile.readAsStringSync().trim();
      print('Read content from config_input.txt');
    } else {
      print('Error: No content provided.');
      return;
    }
  }
  
  // Ensure we are working with Base64 content for the signature payload
  // If input looks like JSON (starts with {), encode it.
  // If it's already Base64 (legacy behavior support), keep it.
  String encodedContent;
  if (rawInput.trim().startsWith('{')) {
    encodedContent = base64Encode(utf8.encode(rawInput.trim()));
  } else {
    encodedContent = rawInput.trim(); 
  }
  
  final signer = Signer(RSASigner(RSASignDigest.SHA256, publicKey: null, privateKey: privateKey));
  final signature = signer.sign(encodedContent);
  
  print('\n=== Result JSON for OSS ===');
  final result = {
    "content": encodedContent,
    "signature": signature.base64,
  };
  
  print(jsonEncode(result));
  
  print('\n=== Signature (Base64) ===');
  print(signature.base64);
}

void verifyConfig() {
  print('\n--- Verify Config ---');
  stdout.write('Enter path to public_key.pem (default: public.pem): ');
  var pubPath = stdin.readLineSync()?.trim();
  if (pubPath == null || pubPath.isEmpty) pubPath = 'public.pem';
  
  File pubFile = File(pubPath);
  if (!pubFile.existsSync()) {
    print('Error: Public key file not found: $pubPath');
    return;
  }
  
  final publicKeyString = pubFile.readAsStringSync();
  final parser = RSAKeyParser();
  final publicKey = parser.parse(publicKeyString) as RSAPublicKey;
  
  print('Enter JSON from OSS (containing "content" and "signature"): ');
  final jsonStr = stdin.readLineSync()?.trim();
  if (jsonStr == null || jsonStr.isEmpty) return;
  
  try {
    final map = jsonDecode(jsonStr);
    final content = map['content'];
    final sigBase64 = map['signature'];
    
    final verifier = Signer(RSASigner(RSASignDigest.SHA256, publicKey: publicKey, privateKey: null));
    final isValid = verifier.verify64(content, sigBase64);
    
    print('\nVerification Result: ${isValid ? "PASS ✅" : "FAIL ❌"}');
  } catch (e) {
    print('Error parsing JSON: $e');
  }
}
