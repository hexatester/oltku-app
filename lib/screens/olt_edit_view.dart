import 'package:flutter/material.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/services/storage_service.dart';

class OltEditView extends StatefulWidget {
  final OltConfig? existingConfig;

  const OltEditView({super.key, this.existingConfig});

  @override
  State<OltEditView> createState() => _OltEditViewState();
}

class _OltEditViewState extends State<OltEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController(text: 'http://192.168.1.100');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');
  final _refreshTimeController = TextEditingController(text: '1');
  bool _obscurePassword = true;
  bool _isLoading = false;
  final List<String> _oltModels = ['Hioso'];
  String _selectedOltModel = 'Hioso';
  
  final Map<String, IconData> _availableIcons = {
    'router': Icons.router,
    'device_hub': Icons.device_hub,
    'wifi': Icons.wifi,
    'home': Icons.home,
    'business': Icons.business,
    'cell_tower': Icons.cell_tower,
    'hub': Icons.hub,
    'settings_input_antenna': Icons.settings_input_antenna,
    'account_tree': Icons.account_tree,
    'location_on': Icons.location_on,
  };
  
  String _selectedOnuIcon = 'router';
  String _selectedOdpIcon = 'device_hub';
  double _markerSize = 100.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingConfig != null) {
      _nameController.text = widget.existingConfig!.name;
      _urlController.text = widget.existingConfig!.url;
      _usernameController.text = widget.existingConfig!.username;
      _passwordController.text = widget.existingConfig!.password;
      _refreshTimeController.text = widget.existingConfig!.refreshTimeMinutes.toString();
      if (_oltModels.contains(widget.existingConfig!.model)) {
        _selectedOltModel = widget.existingConfig!.model;
      }
      if (widget.existingConfig!.onuIcon != null && _availableIcons.containsKey(widget.existingConfig!.onuIcon)) {
        _selectedOnuIcon = widget.existingConfig!.onuIcon!;
      }
      if (widget.existingConfig!.odpIcon != null && _availableIcons.containsKey(widget.existingConfig!.odpIcon)) {
        _selectedOdpIcon = widget.existingConfig!.odpIcon!;
      }
      if (widget.existingConfig!.markerSize != null) {
        _markerSize = widget.existingConfig!.markerSize!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _refreshTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String name = _nameController.text.trim();
    String fullUrl = _urlController.text.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'http://$fullUrl';
    }
    if (fullUrl.endsWith('/')) {
      fullUrl = fullUrl.substring(0, fullUrl.length - 1);
    }

    try {
      final config = OltConfig(
        id:
            widget.existingConfig?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? 'Unnamed OLT' : name,
        url: fullUrl,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        model: _selectedOltModel,
        refreshTimeMinutes: int.tryParse(_refreshTimeController.text.trim()) ?? 1,
        lastRefreshTime: widget.existingConfig?.lastRefreshTime,
        onuIcon: _selectedOnuIcon,
        odpIcon: _selectedOdpIcon,
        markerSize: _markerSize,
      );
      await StorageService.saveOltConfig(config);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('${l10n.errorSavingConfig}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background subtle gradients
          Positioned(
            top: -size.height * 0.4,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.3,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 80.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.router,
                            size: 48,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          widget.existingConfig != null
                              ? AppLocalizations.of(context).editOlt
                              : AppLocalizations.of(context).addOlt,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          AppLocalizations.of(context).configureConnection,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Glassmorphic Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).oltNameLabel,
                                prefixIcon: const Icon(
                                  Icons.label_outline,
                                  color: Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // OLT Model Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedOltModel,
                              dropdownColor: const Color(0xFF1E1B2E),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).oltModelLabel,
                                prefixIcon: const Icon(
                                  Icons.settings,
                                  color: Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _oltModels.map((String model) {
                                return DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(model),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedOltModel = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            // HTTP URL
                            TextFormField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).oltAddressLabel,
                                prefixIcon: const Icon(
                                  Icons.link,
                                  color: Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context).validatorAddress;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Username
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).usernameLabel,
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context).validatorUsername;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).passwordLabel,
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF06B6D4),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context).validatorPassword;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Refresh Time
                            TextFormField(
                              controller: _refreshTimeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).refreshTimeLabel,
                                prefixIcon: const Icon(
                                  Icons.timer,
                                  color: Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context).validatorRefreshEmpty;
                                }
                                if (int.tryParse(value) == null || int.parse(value) < 1) {
                                  return AppLocalizations.of(context).validatorRefreshMin;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // ONU Icon
                            DropdownButtonFormField<String>(
                              initialValue: _selectedOnuIcon,
                              dropdownColor: const Color(0xFF1E1B2E),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).onuIconLabel,
                                prefixIcon: Icon(
                                  _availableIcons[_selectedOnuIcon],
                                  color: const Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _availableIcons.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Row(
                                    children: [
                                      Icon(entry.value, color: Colors.white70),
                                      const SizedBox(width: 12),
                                      Text(entry.key),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedOnuIcon = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            // ODP Icon
                            DropdownButtonFormField<String>(
                              initialValue: _selectedOdpIcon,
                              dropdownColor: const Color(0xFF1E1B2E),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).odpIconLabel,
                                prefixIcon: Icon(
                                  _availableIcons[_selectedOdpIcon],
                                  color: const Color(0xFF06B6D4),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _availableIcons.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Row(
                                    children: [
                                      Icon(entry.value, color: Colors.white70),
                                      const SizedBox(width: 12),
                                      Text(entry.key),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedOdpIcon = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            // Marker Size Slider
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).markerSizeLabel(_markerSize.toInt()),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Slider(
                                  value: _markerSize,
                                  min: 20.0,
                                  max: 200.0,
                                  divisions: 18,
                                  activeColor: const Color(0xFF06B6D4),
                                  inactiveColor: Colors.white24,
                                  onChanged: (value) {
                                    setState(() {
                                      _markerSize = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            // Submit Button
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleSave,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).save,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
