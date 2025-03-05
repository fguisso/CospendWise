import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

class _CustomImageProvider extends ImageProvider<_CustomImageProvider> {
  final String url;
  final double scale;

  _CustomImageProvider(this.url, {this.scale = 1.0});

  @override
  Future<_CustomImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CustomImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(_CustomImageProvider key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: scale,
    );
  }

  Future<ui.Codec> _loadAsync(_CustomImageProvider key, DecoderBufferCallback decode) async {
    try {
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final Uri resolved = Uri.parse(url);
      final HttpClientRequest request = await httpClient.getUrl(resolved);
      
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final Uint8List bytes = await response.fold<BytesBuilder>(
        BytesBuilder(),
        (BytesBuilder builder, List<int> chunk) => builder..add(chunk),
      ).then((builder) => builder.takeBytes());

      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file');
      }

      return decode(await ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      debugPrint('Error loading image: $e');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _CustomImageProvider && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);
}

class UserAvatar extends StatefulWidget {
  final User? user;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.user,
    required this.radius,
    this.backgroundColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _hasError = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _setupImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.profilePicture != widget.user?.profilePicture) {
      _setupImage();
    }
  }

  void _setupImage() {
    if (!mounted) return;
    
    setState(() {
      _hasError = false;
      if (widget.user?.profilePicture != null) {
        _imageProvider = _CustomImageProvider(widget.user!.profilePicture!);
      } else {
        _imageProvider = null;
      }
    });
  }

  String _getInitials() {
    if (widget.user == null || widget.user!.name.isEmpty) {
      return '?';
    }
    final nameParts = widget.user!.name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.user?.profilePicture == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: widget.radius * 0.8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
      backgroundImage: _imageProvider,
      onBackgroundImageError: (_, __) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
} 