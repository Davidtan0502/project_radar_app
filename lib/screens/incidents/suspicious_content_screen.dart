// lib/screens/suspicious_content_screen.dart
import 'package:flutter/material.dart';

class SuspiciousContentScreen extends StatefulWidget {
  final String description;
  final double suspicionScore;
  final List<String> matchedPatterns;
  final String explanation;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SuspiciousContentScreen({
    super.key,
    required this.description,
    required this.suspicionScore,
    required this.matchedPatterns,
    required this.explanation,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<SuspiciousContentScreen> createState() => _SuspiciousContentScreenState();
}

class _SuspiciousContentScreenState extends State<SuspiciousContentScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Calculate bottom padding to account for navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Content Review'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: bottomPadding, // Dynamic bottom padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 56,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content Review Required',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Warning message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  'Our system detected content that may indicate a false or misleading report.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              
              // Suspicion score with visual indicator
              _buildScoreSection(theme),
              const SizedBox(height: 20),
              
              // AI explanation
              if (widget.explanation.isNotEmpty) ...[
                _buildExplanationSection(theme),
                const SizedBox(height: 20),
              ],
              
              // Detected patterns
              if (widget.matchedPatterns.isNotEmpty) ...[
                _buildPatternsSection(theme),
                const SizedBox(height: 20),
              ],
              
              // Report content preview
              _buildContentPreview(theme),
              const SizedBox(height: 20),
              
              // Legal warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  '⚠️ False reports may violate terms of service and have legal consequences.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suspicion Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: widget.suspicionScore,
                backgroundColor: Colors.grey[300],
                color: _getScoreColor(widget.suspicionScore),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(widget.suspicionScore * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(widget.suspicionScore),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplanationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.explanation,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Patterns',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.matchedPatterns
              .map((pattern) => Chip(
                    label: Text(
                      pattern,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[900],
                      ),
                    ),
                    backgroundColor: Colors.orange[100],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildContentPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Content',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.description,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'EDIT REPORT',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.orange.withOpacity(0.3),
            ),
            child: Text(
              'SUBMIT ANYWAY',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.red;
    if (score >= 0.4) return Colors.orange;
    return Colors.blue;
  }
}