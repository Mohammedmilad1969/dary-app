import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isProceeding = false;
  Timer? _timeoutTimer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // Start maximum timeout timer - always proceed after 3 seconds max
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isProceeding) {
        if (kDebugMode) {
          debugPrint('⚠️ SplashScreen: Maximum timeout reached, proceeding...');
        }
        _proceedToNext();
      }
    });
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (kDebugMode) {
        debugPrint('🎬 SplashScreen: Initializing video...');
        if (kIsWeb) {
          debugPrint('🌐 Platform: Web');
        } else {
          debugPrint('📱 Platform: ${defaultTargetPlatform.toString().replaceAll('TargetPlatform.', '')}');
        }
      }
      
      // Use asset path - works on iOS, Android, and Web
      _controller = VideoPlayerController.asset('assets/splash_video.MP4');
      
      // Platform-specific timeout settings
      // Web needs more time for asset loading, mobile is usually faster
      final timeoutDuration = kIsWeb 
          ? const Duration(seconds: 6)  // Web: longer for asset loading
          : const Duration(seconds: 4);  // iOS/Android: faster native asset access
      
      if (kDebugMode) {
        debugPrint('⏱️ SplashScreen: Timeout set to ${timeoutDuration.inSeconds} seconds');
      }
      
      // Initialize with timeout
      await _controller!.initialize().timeout(
        timeoutDuration,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ SplashScreen: Video initialization timeout after ${timeoutDuration.inSeconds}s');
          }
          throw Exception('Video initialization timeout after ${timeoutDuration.inSeconds}s');
        },
      ).catchError((error) {
        if (kDebugMode) {
          debugPrint('❌ SplashScreen: Video initialization error: $error');
        }
        throw error;
      });
      
      if (mounted && !_hasError && !_isProceeding) {
        // Check if video actually initialized
        if (_controller!.value.hasError) {
          if (kDebugMode) {
            debugPrint('❌ SplashScreen: Video has error: ${_controller!.value.errorDescription}');
          }
          throw Exception(_controller!.value.errorDescription ?? 'Video initialization failed');
        }
        
        setState(() {
          _isInitialized = true;
        });
        
        if (kDebugMode) {
          debugPrint('✅ SplashScreen: Video initialized successfully');
          debugPrint('📹 Video size: ${_controller!.value.size}');
          debugPrint('⏱️ Video duration: ${_controller!.value.duration}');
        }
        
        // Set video to loop continuously
        _controller!.setLooping(true);
        
        // Platform-specific video settings
        // On iOS, we might need to set volume or other properties
        if (!kIsWeb) {
          // For mobile platforms, ensure proper video settings
          await _controller!.setVolume(1.0); // Full volume (mute if you don't want sound)
        }
        
        // No need to listen for completion since video loops
        // The timeout timer will handle proceeding to next screen
        
        // Play the video
        await _controller!.play();
        
        if (kDebugMode) {
          debugPrint('▶️ SplashScreen: Video playback started');
          debugPrint('🔊 SplashScreen: Video volume: ${_controller!.value.volume}');
          debugPrint('🔁 SplashScreen: Video looping: ${_controller!.value.isLooping}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SplashScreen: Error initializing video: $e');
        debugPrint('📍 Stack trace: $stackTrace');
      }
      _hasError = true;
      
      // Clean up controller if it exists
      _controller?.dispose();
      _controller = null;
      
      // If video fails, proceed after minimum duration
      if (mounted && !_isProceeding) {
        final elapsed = DateTime.now().difference(_startTime!);
        if (elapsed.inMilliseconds < 1500) {
          // Wait minimum 1.5 seconds for splash
          Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds), () {
            if (mounted && !_isProceeding) {
              _proceedToNext();
            }
          });
        } else {
          _proceedToNext();
        }
      }
    }
  }

  // Video listener removed since video loops continuously
  // The timeout timer handles navigation to next screen

  void _proceedToNext() {
    if (_isProceeding) return; // Prevent multiple calls
    _isProceeding = true;
    _timeoutTimer?.cancel();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    if (kDebugMode) {
      debugPrint('🚀 SplashScreen: Starting splash sequence...');
    }
    
    // Check authentication session
    await _checkAuthenticationSession();
  }

  Future<void> _checkAuthenticationSession() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (kDebugMode) {
        debugPrint('🔄 SplashScreen: Starting session check...');
      }
      
      // Initialize auth provider (this will check for existing session)
      await authProvider.initialize();
      
      if (kDebugMode) {
        debugPrint('✅ SplashScreen: Session check completed');
        debugPrint('📊 SplashScreen: User authenticated: ${authProvider.isAuthenticated}');
        if (authProvider.isAuthenticated) {
          debugPrint('👤 SplashScreen: User: ${authProvider.userEmail}');
        }
      }
      
      // Wait a bit more for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Always go to homepage (guest mode)
        if (kDebugMode) {
          debugPrint('🏠 SplashScreen: Navigating to homepage (guest mode)');
          if (authProvider.isAuthenticated) {
            debugPrint('👤 SplashScreen: User is logged in: ${authProvider.userEmail}');
          } else {
            debugPrint('👤 SplashScreen: User is in guest mode');
          }
        }
        context.go('/');
      }
    } catch (e) {
      // If there's an error, go to login as fallback
      if (kDebugMode) {
        debugPrint('❌ SplashScreen: Session check error: $e');
        debugPrint('🔐 SplashScreen: Falling back to login');
      }
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _controller != null && 
            _controller!.value.isInitialized && 
            !_controller!.value.hasError &&
            _isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width > 0 
                      ? _controller!.value.size.width 
                      : MediaQuery.of(context).size.width,
                  height: _controller!.value.size.height > 0 
                      ? _controller!.value.size.height 
                      : MediaQuery.of(context).size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            : Container(
                // Black screen while video loads or if video fails
                color: Colors.black,
              ),
      ),
    );
  }
}
