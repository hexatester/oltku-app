import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Determines the PON type from [submodel].
/// HA7304 and HA7302CST are EPON; everything else is treated as GPON.
enum PonType { epon, gpon }

PonType _ponTypeFromSubmodel(String? submodel) {
  const eponSubmodels = {'HA7304', 'HA7302CST'};
  if (submodel != null && eponSubmodels.contains(submodel)) {
    return PonType.epon;
  }
  return PonType.gpon;
}

class ActivationView extends StatefulWidget {
  final String oltModel;
  final String? oltSubmodel;

  const ActivationView({
    super.key,
    required this.oltModel,
    this.oltSubmodel,
  });

  @override
  State<ActivationView> createState() => _ActivationViewState();
}

class _ActivationViewState extends State<ActivationView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  // EPON fields
  final _macController = TextEditingController();

  // GPON fields
  final _ponSnController = TextEditingController();
  final _pppoeUsernameController = TextEditingController();
  final _pppoePasswordController = TextEditingController();
  final _pppoeVlanController = TextEditingController();
  bool _obscurePppoePassword = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late PonType _ponType;

  @override
  void initState() {
    super.initState();
    _ponType = _ponTypeFromSubmodel(widget.oltSubmodel);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _macController.dispose();
    _ponSnController.dispose();
    _pppoeUsernameController.dispose();
    _pppoePasswordController.dispose();
    _pppoeVlanController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate network delay — replace with real API call
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    }
  }

  void _handleReset() {
    _formKey.currentState?.reset();
    _macController.clear();
    _ponSnController.clear();
    _pppoeUsernameController.clear();
    _pppoePasswordController.clear();
    _pppoeVlanController.clear();
    setState(() => _submitted = false);
    _fadeController
      ..reset()
      ..forward();
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  // ─── EPON form ──────────────────────────────────────────────────────────────

  Widget _buildEponForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.settings_ethernet,
          color: const Color(0xFF06B6D4),
          title: 'EPON Device Identity',
          subtitle: 'Provide the MAC address of the ONU to register.',
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _macController,
          style: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
            LengthLimitingTextInputFormatter(17),
            _MacAddressFormatter(),
          ],
          decoration: _fieldDecoration(
            label: 'MAC Address',
            icon: Icons.perm_device_information,
            hint: 'AA:BB:CC:DD:EE:FF',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'MAC address is required';
            }
            final clean = v.replaceAll(':', '');
            if (clean.length != 12) {
              return 'Enter a valid 6-byte MAC (AA:BB:CC:DD:EE:FF)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── GPON form ──────────────────────────────────────────────────────────────

  Widget _buildGponForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.fiber_manual_record,
          color: const Color(0xFF10B981),
          title: 'GPON Device Identity',
          subtitle:
              'Enter the PON Serial Number printed on the ONU label.',
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _ponSnController,
          style: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1.0,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-FxX]')),
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: _fieldDecoration(
            label: 'PON Serial Number (SN)',
            icon: Icons.qr_code_2,
            hint: 'e.g. 48575443A1B2C3D4',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'PON SN is required';
            }
            if (v.trim().length < 8) {
              return 'SN must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.vpn_key_outlined,
          color: const Color(0xFF8B5CF6),
          title: 'PPPoE Credentials',
          subtitle:
              'These credentials will be provisioned on the ONU for WAN access.',
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _pppoeUsernameController,
          decoration: _fieldDecoration(
            label: 'PPPoE Username',
            icon: Icons.person_outline,
            hint: 'e.g. user@isp.net',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'PPPoE username is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pppoePasswordController,
          obscureText: _obscurePppoePassword,
          decoration: _fieldDecoration(
            label: 'PPPoE Password',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscurePppoePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
              ),
              onPressed: () => setState(
                () => _obscurePppoePassword = !_obscurePppoePassword,
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'PPPoE password is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pppoeVlanController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: _fieldDecoration(
            label: 'PPPoE VLAN ID',
            icon: Icons.lan_outlined,
            hint: '1 – 4094',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'VLAN ID is required';
            }
            final n = int.tryParse(v.trim());
            if (n == null || n < 1 || n > 4094) {
              return 'Enter a valid VLAN ID (1–4094)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── success state ───────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Activation Request Sent',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The ONU provisioning request has been queued.\nThe device will register within a few minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _handleReset,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Activate Another ONU'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isEpon = _ponType == PonType.epon;
    final typeLabel = isEpon ? 'EPON' : 'GPON';
    final typeColor = isEpon ? const Color(0xFF06B6D4) : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: typeColor.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: typeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Activate ONU',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -size.height * 0.3,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _submitted
                    ? _buildSuccessState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // Header card
                            _HeaderCard(
                              ponType: _ponType,
                              oltModel: widget.oltModel,
                              oltSubmodel: widget.oltSubmodel,
                            ),
                            const SizedBox(height: 24),
                            // Form card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius:
                                    BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    isEpon
                                        ? _buildEponForm()
                                        : _buildGponForm(),
                                    const SizedBox(height: 28),
                                    // Submit button
                                    _isSubmitting
                                        ? const Center(
                                            child:
                                                CircularProgressIndicator(),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: _handleSubmit,
                                            icon: const Icon(
                                              Icons.send_rounded,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Submit Activation',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(
                                                0xFF6366F1,
                                              ),
                                              foregroundColor:
                                                  Colors.white,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                vertical: 16,
                                              ),
                                              elevation: 6,
                                              shadowColor: const Color(
                                                0xFF6366F1,
                                              ).withValues(alpha: 0.5),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(12),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Disclaimer
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'This is a provisioning request form. '
                                    'Actual activation depends on OLT configuration.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final PonType ponType;
  final String oltModel;
  final String? oltSubmodel;

  const _HeaderCard({
    required this.ponType,
    required this.oltModel,
    this.oltSubmodel,
  });

  @override
  Widget build(BuildContext context) {
    final isEpon = ponType == PonType.epon;
    final gradient = isEpon
        ? const LinearGradient(
            colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isEpon
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF10B981))
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEpon
                  ? Icons.settings_ethernet
                  : Icons.fiber_manual_record,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEpon
                      ? 'EPON ONU Activation'
                      : 'GPON ONU Activation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  oltSubmodel != null
                      ? '$oltModel · $oltSubmodel'
                      : oltModel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── MAC address formatter ────────────────────────────────────────────────────

class _MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(':', '').toUpperCase();
    if (raw.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(':');
      buffer.write(raw[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
