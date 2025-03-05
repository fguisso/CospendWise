import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum LoginStatus {
  ok,
  authFailed,
  connectionFailed,
  noNetwork,
  jsonFailed,
  serverFailed,
  ssoTokenMismatch,
  reqFailed
}

class CospendService {
  static const int _connectionTimeout = 10; // seconds

  /// Creates an HTTP client that accepts self-signed certificates
  static HttpClient _createHttpClient({bool allowSelfSigned = true}) {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: _connectionTimeout)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint('\nCospendService - SSL Certificate Details:');
        debugPrint('- Host: $host');
        debugPrint('- Port: $port');
        debugPrint('- Issuer: ${cert.issuer}');
        debugPrint('- Subject: ${cert.subject}');
        debugPrint('- Valid from: ${cert.startValidity}');
        debugPrint('- Valid until: ${cert.endValidity}');
        
        if (allowSelfSigned) {
          debugPrint('- Accepting self-signed certificate');
          return true;
        }
        
        // Check if certificate is expired
        final now = DateTime.now();
        if (now.isBefore(cert.startValidity) || now.isAfter(cert.endValidity)) {
          debugPrint('- Certificate is expired or not yet valid');
          return false;
        }
        
        // Check if certificate is for the correct host
        if (!_isValidHostname(cert, host)) {
          debugPrint('- Certificate hostname mismatch');
          return false;
        }
        
        debugPrint('- Certificate is valid');
        return true;
      };
    return httpClient;
  }

  /// Check if the certificate is valid for the given hostname
  static bool _isValidHostname(X509Certificate cert, String hostname) {
    // Extract the Common Name (CN) from the subject
    final cnMatch = RegExp(r'CN=([^,]+)').firstMatch(cert.subject);
    final commonName = cnMatch?.group(1);
    
    // Extract Subject Alternative Names (SANs) if available
    final sanMatch = RegExp(r'DNS:([^,]+)').allMatches(cert.subject);
    final subjectAltNames = sanMatch.map((m) => m.group(1)).whereType<String>().toList();
    
    // Check if hostname matches CN or any SAN
    final isValid = commonName == hostname || subjectAltNames.contains(hostname);
    debugPrint('- Common Name: $commonName');
    debugPrint('- Subject Alt Names: $subjectAltNames');
    debugPrint('- Hostname match: $isValid');
    
    return isValid;
  }

  /// Makes an HTTP GET request that accepts self-signed certificates
  static Future<http.Response> _getSelfSignedResponse(String url, {Map<String, String>? headers}) async {
    debugPrint('\nCospendService - Making request:');
    debugPrint('- Full URL: $url');
    
    final uri = Uri.parse(url);
    debugPrint('- Parsed URL components:');
    debugPrint('  * Scheme: ${uri.scheme}');
    debugPrint('  * Host: ${uri.host}');
    debugPrint('  * Port: ${uri.port}');
    debugPrint('  * Path: ${uri.path}');
    debugPrint('  * Query: ${uri.query}');
    
    if (headers != null) {
      debugPrint('- Request headers:');
      headers.forEach((key, value) {
        debugPrint('  * $key: ${key == 'Authorization' ? '(hidden)' : value}');
      });
    }

    final client = _createHttpClient();
    final request = await client.getUrl(uri);
    
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
    }
    
    debugPrint('- Sending request...');
    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();
    
    debugPrint('- Response received:');
    debugPrint('  * Status code: ${response.statusCode}');
    debugPrint('  * Content length: ${stringData.length} bytes');
    
    // Convert HttpHeaders to Map<String, String>
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });
    
    return http.Response(
      stringData,
      response.statusCode,
      headers: responseHeaders,
    );
  }

  /// Formats the URL by handling trailing slashes and missing protocol
  static String formatUrl(String url) {
    debugPrint('CospendService - Formatting URL:');
    debugPrint('- Input URL: $url');

    // Remove trailing slashes and whitespace
    String formattedUrl = url.trim();
    while (formattedUrl.endsWith('/')) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }

    // Add protocol if missing
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    // Ensure proper URL format with double slashes after protocol
    formattedUrl = formattedUrl.replaceFirst('://', '://');

    // Remove common path components to avoid duplication
    final commonPaths = [
      '/index.php/apps/cospend',
      '/apps/cospend',
      '/index.php',
    ];

    for (final path in commonPaths) {
      if (formattedUrl.endsWith(path)) {
        formattedUrl = formattedUrl.substring(0, formattedUrl.length - path.length);
      }
    }

    debugPrint('- Formatted URL: $formattedUrl');
    return formattedUrl;
  }

  /// Checks if the URL uses HTTP (non-secure)
  static bool isHttp(String? url) {
    return url != null && 
           url.length > 4 && 
           url.startsWith("http") && 
           url[4] != 's';
  }

  /// Validates login credentials against the Cospend server
  static Future<LoginStatus> isValidLogin({
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('\nCospendService - Validating login:');
      debugPrint('- Original URL: $url');
      debugPrint('- Username: $username');
      
      final formattedUrl = formatUrl(url);
      debugPrint('- Formatted base URL: $formattedUrl');
      
      final targetUrl = "$formattedUrl/index.php/apps/cospend/api/ping";
      debugPrint('- Full endpoint URL: $targetUrl');
      
      final uri = Uri.parse(targetUrl);
      debugPrint('- Parsed endpoint components:');
      debugPrint('  * Scheme: ${uri.scheme}');
      debugPrint('  * Host: ${uri.host}');
      debugPrint('  * Port: ${uri.port}');
      debugPrint('  * Path: ${uri.path}');
      
      final credentials = base64Encode(utf8.encode("$username:$password"));
      
      final response = await _getSelfSignedResponse(
        targetUrl,
        headers: {
          "Authorization": "Basic $credentials",
          "Accept": "application/json",
          "OCS-APIRequest": "true",
        },
      );

      debugPrint('\nResponse details:');
      debugPrint('- Status code: ${response.statusCode}');
      debugPrint('- Response headers:');
      response.headers.forEach((key, value) {
        debugPrint('  * $key: $value');
      });
      debugPrint('- Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          jsonDecode(response.body);
          debugPrint('- Login successful');
          return LoginStatus.ok;
        } catch (e) {
          debugPrint('- JSON parsing error: $e');
          return LoginStatus.jsonFailed;
        }
      } else if (response.statusCode >= 401 && response.statusCode <= 403) {
        debugPrint('- Authentication failed');
        return LoginStatus.authFailed;
      } else {
        debugPrint('- Server error: ${response.statusCode}');
        return LoginStatus.serverFailed;
      }
    } on HttpException catch (e) {
      debugPrint('- Connection error: $e');
      return LoginStatus.connectionFailed;
    } catch (e) {
      debugPrint('- Unexpected error: $e');
      return LoginStatus.reqFailed;
    }
  }

  /// Checks if there is a valid Cospend instance at the given URL
  static Future<bool> isValidUrl(String url) async {
    try {
      debugPrint('\nCospendService - Checking URL validity:');
      debugPrint('- Original URL: $url');
      
      final formattedUrl = formatUrl(url);
      debugPrint('- Formatted base URL: $formattedUrl');
      
      // First try the Nextcloud status endpoint
      final statusUrl = "$formattedUrl/status.php";
      debugPrint('\nTrying Nextcloud status endpoint:');
      debugPrint('- Full URL: $statusUrl');
      
      final statusUri = Uri.parse(statusUrl);
      debugPrint('- Parsed components:');
      debugPrint('  * Scheme: ${statusUri.scheme}');
      debugPrint('  * Host: ${statusUri.host}');
      debugPrint('  * Port: ${statusUri.port}');
      debugPrint('  * Path: ${statusUri.path}');
      
      try {
        final response = await _getSelfSignedResponse(statusUrl);

        if (response.statusCode == 200) {
          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['installed'] == true) {
              debugPrint('✓ Nextcloud instance found and installed');
              return true;
            }
          } catch (e) {
            debugPrint('✗ Error parsing status response: $e');
          }
        }
      } catch (e) {
        debugPrint('✗ Error checking status endpoint: $e');
      }

      // If status.php fails, try the Cospend API ping endpoint
      final pingUrl = "$formattedUrl/index.php/apps/cospend/api/ping";
      debugPrint('\nTrying Cospend ping endpoint:');
      debugPrint('- Full URL: $pingUrl');
      
      final pingUri = Uri.parse(pingUrl);
      debugPrint('- Parsed components:');
      debugPrint('  * Scheme: ${pingUri.scheme}');
      debugPrint('  * Host: ${pingUri.host}');
      debugPrint('  * Port: ${pingUri.port}');
      debugPrint('  * Path: ${pingUri.path}');
      
      try {
        final response = await _getSelfSignedResponse(pingUrl);

        if (response.statusCode == 200) {
          try {
            jsonDecode(response.body);
            debugPrint('✓ Valid Cospend instance found');
            return true;
          } catch (e) {
            debugPrint('✗ Error parsing ping response: $e');
          }
        }
      } catch (e) {
        debugPrint('✗ Error checking ping endpoint: $e');
      }

      debugPrint('✗ No valid Cospend instance found at the URL');
      return false;
    } catch (e) {
      debugPrint('✗ Unexpected error in isValidUrl: $e');
      return false;
    }
  }

  /// Makes an authenticated request to the Cospend API
  static Future<http.Response> makeAuthenticatedRequest({
    required String url,
    required String username,
    required String password,
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
    bool useOcsApi = false,
    bool retryOnError = false,
  }) async {
    try {
      debugPrint('\nCospendService - Making authenticated request:');
      debugPrint('- Method: $method');
      debugPrint('- Endpoint: $endpoint');
      
      final formattedUrl = formatUrl(url);
      final targetUrl = '$formattedUrl/$endpoint';
      
      debugPrint('- Base URL: $formattedUrl');
      debugPrint('- Full URL: $targetUrl');
      
      final credentials = base64Encode(utf8.encode('$username:$password'));
      final headers = {
        'Authorization': 'Basic $credentials',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      if (useOcsApi) {
        headers['OCS-APIRequest'] = 'true';
      }

      // Function to make the actual request with retries
      Future<http.Response> makeRequest() async {
        int retryCount = 0;
        const maxRetries = 3;
        const retryDelay = Duration(seconds: 1);

        while (true) {
          try {
            if (method == 'GET') {
              return await _getSelfSignedResponse(targetUrl, headers: headers);
            } else {
              final client = _createHttpClient();
              final uri = Uri.parse(targetUrl);
              final request = method == 'POST' 
                ? await client.postUrl(uri)
                : method == 'PUT'
                  ? await client.putUrl(uri)
                  : await client.deleteUrl(uri);
              
              headers.forEach((key, value) {
                request.headers.set(key, value);
              });
              
              if (body != null) {
                final jsonBody = jsonEncode(body);
                request.write(jsonBody);
              }
              
              final response = await request.close();
              final stringData = await response.transform(utf8.decoder).join();
              
              // Convert HttpHeaders to Map<String, String>
              final responseHeaders = <String, String>{};
              response.headers.forEach((name, values) {
                responseHeaders[name] = values.join(',');
              });
              
              return http.Response(
                stringData,
                response.statusCode,
                headers: responseHeaders,
              );
            }
          } catch (e) {
            debugPrint('CospendService - Request error: $e');
            
            // If we should retry and haven't exceeded max retries
            if (retryOnError && retryCount < maxRetries && 
                (e is HandshakeException || e is SocketException)) {
              retryCount++;
              debugPrint('CospendService - Retrying request (attempt $retryCount of $maxRetries)');
              await Future.delayed(retryDelay * retryCount);
              continue;
            }
            rethrow;
          }
        }
      }

      return await makeRequest();
    } catch (e) {
      debugPrint('CospendService - Error making authenticated request: $e');
      rethrow;
    }
  }
} 