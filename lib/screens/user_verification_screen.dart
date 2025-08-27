import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../widgets/lottie_loader.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserVerificationScreen extends StatefulWidget {
  static const routeName = '/user-verification';
  
  final String? emailVerificationToken;
  final String? userId;
  final bool isEmailVerification;
  final String? userEmail; // Add email support for fallback

  const UserVerificationScreen({
    super.key,
    this.emailVerificationToken,
    this.userId,
    this.isEmailVerification = false,
    this.userEmail,
  });

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {


  
  bool _isLoading = false;
  bool _isEmailVerified = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isValidUserId = false;
  String? _userEmail; // Fallback to email if user ID fails

  @override
  void initState() {
    super.initState();
    if (widget.isEmailVerification && widget.emailVerificationToken != null) {
      _verifyEmail();
    }
    // If we have a userId but no email verification token, try to get user info
    if (widget.userId != null && !widget.isEmailVerification) {
      _validateUserIdAndCheckStatus();
    }
    
    // Store email for fallback
    _userEmail = widget.userEmail;
  }



  Future<void> _validateUserIdAndCheckStatus() async {
    if (widget.userId == null) return;
    
    // Basic validation for MongoDB ObjectId format
    if (widget.userId!.length != 24 || !RegExp(r'^[a-fA-F0-9]+$').hasMatch(widget.userId!)) {
      setState(() {
        _errorMessage = 'Invalid user ID format. Please log in again.';
        _isValidUserId = false;
      });
      return;
    }

    setState(() {
      _isValidUserId = true;
    });

    // Add a small delay to ensure user is fully saved to database
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkUserVerificationStatus();
  }

  Future<void> _checkUserVerificationStatus() async {
    if (widget.userId == null || !_isValidUserId) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Checking user status for ID: ${widget.userId}');
      final response = await http.get(
        Uri.parse('${ApiService.getBaseUrl()}/auth/user/status/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _isEmailVerified = responseData['isEmailVerified'] ?? false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 404) {
        // Try to get user by email as fallback
        await _tryGetUserByEmail();
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to get user status. Please try again.';
        });
      }
    } catch (e) {
      print('Error checking user status: $e');
              setState(() {
          _errorMessage = 'Network error: Please check your internet connection and try again.';
        });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _tryGetUserByEmail() async {
    if (_userEmail == null) {
      setState(() {
        _errorMessage = 'User account not found. This might be a temporary issue. Please try refreshing or contact support if the problem persists.';
      });
      return;
    }
    
    // Try to get user by email instead
    try {
      print('Trying to get user by email: $_userEmail');
      final response = await http.post(
        Uri.parse('${ApiService.getBaseUrl()}/auth/user/get-by-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': _userEmail!,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _isEmailVerified = responseData['isEmailVerified'] ?? false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'User account not found. This might be a temporary issue. Please try refreshing or contact support if the problem persists.';
        });
      }
    } catch (e) {
      print('Error getting user by email: $e');
      setState(() {
        _errorMessage = 'User account not found. This might be a temporary issue. Please try refreshing or contact support if the problem persists.';
      });
    }
  }

  Future<void> _verifyEmail() async {
    if (widget.emailVerificationToken == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiService.getBaseUrl()}/auth/user/verify-email/${widget.emailVerificationToken}'),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          _isEmailVerified = true;
          _successMessage = 'Email verified successfully!';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Email verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }





  Future<void> _resendEmailVerification() async {
    if (_userEmail == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.getBaseUrl()}/auth/user/resend-email-verification'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _userEmail!,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Verification email sent! Check your inbox.';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to resend verification email. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: Please check your internet connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: LottieLoader())
          : CustomScrollView(
              slivers: [
                // Apple-style header with improved typography
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Verify Account',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black.withValues(alpha: 0.9),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDarkMode 
                            ? [const Color(0xFF000000), const Color(0xFF1C1C1E)]
                            : [const Color(0xFFF5F5F7), const Color(0xFFF5F5F7)],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Content with improved spacing and layout
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        
                        // Enhanced subtitle with better typography
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'Please verify your email to activate your account',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode 
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.6),
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 48),

                        // Email Verification Card with enhanced design
                        _buildAppleStyleCard(
                          title: 'Email Verification',
                          subtitle: _isEmailVerified ? 'Verified Successfully' : 'Pending Verification',
                          icon: Icons.email_outlined,
                          isVerified: _isEmailVerified,
                          color: _isEmailVerified ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                          isDarkMode: isDarkMode,
                        ),
                        
                        if (!_isEmailVerified && widget.userId != null && _isValidUserId) ...[
                          const SizedBox(height: 20),
                          _buildAppleStyleButton(
                            onPressed: _resendEmailVerification,
                            title: 'Resend Email Verification',
                            isSecondary: true,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                        

                        
                        const SizedBox(height: 36),

                        // Enhanced Success/Error Messages
                        if (_successMessage != null) ...[
                          const SizedBox(height: 28),
                          _buildMessageCard(
                            message: _successMessage!,
                            isSuccess: true,
                            isDarkMode: isDarkMode,
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 28),
                          _buildMessageCard(
                            message: _errorMessage!,
                            isSuccess: false,
                            isDarkMode: isDarkMode,
                          ),
                          

                          
                          // Add helpful instructions for verification issues
                          if (_errorMessage!.contains('User account not found')) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF3A3A3C) : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Troubleshooting Tips:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Wait a few moments and try again\n• Check your internet connection\n• If the problem persists, try logging in again',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        // Continue Button (if email verified)
                        if (_isEmailVerified) ...[
                          const SizedBox(height: 36),
                          _buildAppleStyleButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/user-home');
                            },
                            title: 'Continue to App',
                            isDarkMode: isDarkMode,
                          ),
                        ],
                        
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }



  Widget _buildAppleStyleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black.withValues(alpha: 0.9),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isVerified ? color : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isVerified ? Icons.check : Icons.pending,
              color: isVerified ? Colors.white : (isDarkMode ? Colors.grey : Colors.grey),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleStyleButton({
    required VoidCallback? onPressed,
    required String title,
    bool isSecondary = false,
    bool isDarkMode = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isSecondary 
          ? Colors.transparent 
          : onPressed == null 
            ? (isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.withValues(alpha: 0.3))
            : const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(16),
        border: isSecondary 
          ? Border.all(
              color: const Color(0xFF007AFF),
              width: 2,
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSecondary 
                  ? const Color(0xFF007AFF)
                  : onPressed == null 
                    ? (isDarkMode ? Colors.grey : Colors.grey)
                    : Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildMessageCard({
    required String message,
    required bool isSuccess,
    bool isDarkMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess 
          ? (isDarkMode ? const Color(0xFF1A3A1A) : const Color(0xFF34C759).withValues(alpha: 0.1))
          : (isDarkMode ? const Color(0xFF3A1A1A) : const Color(0xFFFF3B30).withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess 
            ? const Color(0xFF34C759).withValues(alpha: 0.4)
            : const Color(0xFFFF3B30).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
