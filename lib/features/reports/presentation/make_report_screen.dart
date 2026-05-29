import 'dart:io';
import 'dart:async';

import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/image_provider.dart';
import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'search_reports_screen.dart';
import 'report_submitted_screen.dart';

import '../data/reports_reposritory.dart';
import '../../../core/utils/methods/auto_complete_json_decoder.dart';
import '../../../core/utils/methods/auto_complete_predictions.dart';

// Prototype-only default key for faster team testing.
// In production/release this must be injected securely (CI secrets, remote config, etc).
const String _prototypeGoogleMapsApiKey =
    'AIzaSyCho5-OnMIO1tRNYj11iiLtQKkFVMfPvAo';
const String _googleGeocodingApiKey = String.fromEnvironment(
  'GOOGLE_GEOCODING_API_KEY',
  defaultValue: _prototypeGoogleMapsApiKey,
);

class MakeReportScreen extends ConsumerStatefulWidget {
  const MakeReportScreen({super.key});

  @override
  ConsumerState<MakeReportScreen> createState() => _MakeReportScreenState();
}

class _MakeReportScreenState extends ConsumerState<MakeReportScreen> {
  static const LatLng _defaultMapCenter = LatLng(52.4862, -1.8904);

  final _reportsRepository = ReportsRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressSearchController = TextEditingController();

  static const _draftDescriptionKey = 'report_draft_description';
  static const _draftCategoryKey = 'report_draft_category';
  static const _draftLatitudeKey = 'report_draft_latitude';
  static const _draftLongitudeKey = 'report_draft_longitude';

  GoogleMapController? _mapController;

  bool _isSearchingAddress = false;
  bool _isLocatingCurrent = false;
  bool _isLoadingSuggestions = false;
  bool _submittingReport = false;
  Timer? _autoCompleteDebounce;
  List<AutoCompletePredictions> _autoCompletePredictions = [];
  LatLng _selectedLatLng = _defaultMapCenter;

  late String _randomUUID;

  File? _uploadedImage;

  ReportType _selectedCategory = ReportType.pothole;

  Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('selected_location'),
      position: _defaultMapCenter,
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _moveToCurrentLocation();

    var uuid = Uuid();
    _randomUUID = uuid.v4();
  }

  Future<void> _loadDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);

    final savedDescription = prefs.getString(_draftDescriptionKey) ?? '';
    final savedCategory = prefs.getString(_draftCategoryKey);
    final savedLat = prefs.getDouble(_draftLatitudeKey);
    final savedLng = prefs.getDouble(_draftLongitudeKey);

    final restoredLocation = (savedLat != null && savedLng != null)
        ? LatLng(savedLat, savedLng)
        : _defaultMapCenter;

    final restoredCategory = ReportType.values.firstWhere(
      (e) => e.name == savedCategory,
      orElse: () => ReportType.pothole,
    );

    if (!mounted) return;

    setState(() {
      _selectedCategory = restoredCategory;
      _selectedLatLng = restoredLocation;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: restoredLocation,
        ),
      };
    });
    _descriptionController.value = TextEditingValue(
      text: savedDescription,
      selection: TextSelection.collapsed(offset: savedDescription.length),
    );
  }

  Future<void> _saveDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);

    await prefs.setString(
      _draftDescriptionKey,
      _descriptionController.text.trim(),
    );
    await prefs.setString(_draftCategoryKey, _selectedCategory.name);
    await prefs.setDouble(_draftLatitudeKey, _selectedLatLng.latitude);
    await prefs.setDouble(_draftLongitudeKey, _selectedLatLng.longitude);
  }

  Future<void> _setPickedLocation(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _markers = {
        Marker(markerId: const MarkerId('selected_location'), position: latLng),
      };
    });

    await _saveDraft();
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocatingCurrent) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLocatingCurrent = true;
    });

    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition();

      final currentLatLng = LatLng(position.latitude, position.longitude);

      await _setPickedLocation(currentLatLng);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingCurrent = false;
        });
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location service is disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission permanently denied. Please enable it in app settings.',
      );
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchAddress() async {
    await _searchAddressWithParams();
  }

  Future<void> _searchAddressWithParams({
    String? queryOverride,
    String? placeId,
  }) async {
    final rawQuery = (queryOverride ?? _addressSearchController.text).trim();
    if ((rawQuery.isEmpty && placeId == null) || _isSearchingAddress) return;

    if (_googleGeocodingApiKey.isEmpty) {
      _showMessage(
        'Address search is not configured. Missing GOOGLE_GEOCODING_API_KEY.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final query = rawQuery.replaceAll(RegExp(r'\s+'), ' ').trim();

      final Uri uri;
      if (placeId != null) {
        uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
          'place_id': placeId,
          'key': _googleGeocodingApiKey,
        });
      } else {
        uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
          'address': query,
          'key': _googleGeocodingApiKey,
        });
      }

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final status = data['status'] as String? ?? 'UNKNOWN';

      if (status != 'OK') {
        if (status == 'ZERO_RESULTS') {
          _showMessage('Address not found.');
          return;
        }

        final errorMessage =
            data['error_message'] as String? ?? 'Geocoding failed.';
        throw Exception('$status: $errorMessage');
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        _showMessage('Address not found.');
        return;
      }

      final geometry = results.first['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;

      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();

      final searchedLatLng = LatLng(lat, lng);

      await _setPickedLocation(searchedLatLng);
      if (mounted) {
        setState(() {
          _autoCompletePredictions = [];
        });
      }

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: searchedLatLng, zoom: 16),
        ),
      );
    } catch (e) {
      _showMessage('Failed to search address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    }
  }

  void _onAddressInputChanged(String rawInput) {
    _autoCompleteDebounce?.cancel();

    final input = rawInput.trim();

    if (input.isEmpty) {
      setState(() {
        _autoCompletePredictions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _autoCompleteDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaceAutoComplete(input);
    });
  }

  Future<void> _fetchPlaceAutoComplete(String query) async {
    if (_googleGeocodingApiKey.isEmpty || query.length < 3) {
      if (!mounted) return;
      setState(() {
        _autoCompletePredictions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {'input': query, 'key': _googleGeocodingApiKey},
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final parsed = PlaceAutoCompleteResponse.parseResponse(response.body);

      if (!mounted) return;

      setState(() {
        _autoCompletePredictions = parsed.predictions ?? [];
        _isLoadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _autoCompletePredictions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _onSuggestionSelected(AutoCompletePredictions prediction) async {
    final selectedText = prediction.description?.trim();
    if (selectedText == null || selectedText.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _addressSearchController.text = selectedText;
      _autoCompletePredictions = [];
    });

    await _searchAddressWithParams(
      queryOverride: selectedText,
      placeId: prediction.placeId,
    );
  }

  String _categoryLabel(ReportType value) {
    switch (value) {
      case ReportType.pothole:
        return 'Pothole';
      case ReportType.rubbish:
        return 'Rubbish';
      case ReportType.other:
        return 'Other';
    }
  }

  IconData _categoryIcon(ReportType value) {
    switch (value) {
      case ReportType.pothole:
        return Icons.landscape;
      case ReportType.rubbish:
        return Icons.delete_outline;
      case ReportType.other:
        return Icons.question_mark_rounded;
    }
  }

  Future<void> _updateCategory(ReportType category) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCategory = category;
    });
    await _saveDraft();
  }

  Future<void> _resetAfterSuccessfulSubmit() async {
    final prefs = ref.read(sharedPreferencesProvider);

    await Future.wait([
      prefs.remove(_draftDescriptionKey),
      prefs.remove(_draftCategoryKey),
      prefs.remove(_draftLatitudeKey),
      prefs.remove(_draftLongitudeKey),
      prefs.remove('latest_report_category'),
      prefs.remove('latest_report_status'),
    ]);

    if (!mounted) return;

    final newUuid = const Uuid().v4();

    setState(() {
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      _addressSearchController.clear();
      _autoCompletePredictions = [];
      _uploadedImage = null;
      _selectedCategory = ReportType.pothole;
      _selectedLatLng = _defaultMapCenter;
      _markers = {
        const Marker(
          markerId: MarkerId('selected_location'),
          position: _defaultMapCenter,
        ),
      };
      _randomUUID = newUuid;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _defaultMapCenter, zoom: 15),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _submittingReport) return;

    final selectedImage = _uploadedImage;
    if (selectedImage == null) {
      _showMessage('No photo selected.');
      return;
    }

    setState(() {
      _submittingReport = true;
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);

      await _saveDraft();
      await prefs.setString(
        'latest_report_category',
        _categoryLabel(_selectedCategory),
      );
      await prefs.setString('latest_report_status', 'In Progress');

      final title = _titleController.text.trim();
      final category = _selectedCategory.name;
      final description = _descriptionController.text.trim();
      final longitude = _selectedLatLng.longitude;
      final latitude = _selectedLatLng.latitude;

      final uploadURL = await ImagePickerProvider().uploadImage(
        selectedImage,
        folder: 'Uploads',
      );

      if (uploadURL == null) {
        _showMessage('Image upload failed. Please try again.');
        return;
      }

      await ImagePickerProvider().saveImageUrl(
        uploadURL,
        ref.read(currentUserIdProvider)!,
      );

      if (!mounted) return;

      Report report = Report(
        _randomUUID,
        title,
        ref.read(currentUserIdProvider)!,
        category,
        description,
        uploadURL,
        latitude,
        longitude,
        DateTime.now(),
      );

      ReportInteraction interaction = ReportInteraction(
        _randomUUID,
        ReportStatus.reported,
        0,
        [],
        DateTime.now(),
      );

      await _reportsRepository.submitReport(report);
      await _reportsRepository.submitInteraction(interaction);

      if (!mounted) return;

      await _resetAfterSuccessfulSubmit();

      if (!mounted) return;

      _showMessage('Report sent successfully.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportSubmittedScreen(
            reportCategory: _categoryLabel(_selectedCategory),
            reportStatus: 'Reported',
          ),
        ),
      );
    } catch (e) {
      _showMessage('Failed to submit report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submittingReport = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _autoCompleteDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = _ReportPagePalette.of(context);
    final categories = ReportType.values;

    return Scaffold(
      backgroundColor: colors.pageBg,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Report an Issue',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Issue Title Section
              _SectionTitle(title: 'Issue Title', color: colors.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: colors.title),
                decoration: InputDecoration(
                  hintText: 'Enter issue title',
                  hintStyle: TextStyle(color: colors.subtitle),
                  filled: true,
                  fillColor: colors.panelBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an issue title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Category Selection Section
              _SectionTitle(title: 'Select Category', color: colors.title),
              const SizedBox(height: 12),
              Row(
                children: categories.map((category) {
                  final selected = category == _selectedCategory;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: category == categories.last ? 0 : 10,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _updateCategory(category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.accentSoft
                                : colors.panelBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? colors.accent : colors.border,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _categoryIcon(category),
                                size: 28,
                                color: selected
                                    ? colors.accent
                                    : colors.subtitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _categoryLabel(category),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? colors.accent
                                      : colors.title,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Description Section
              const SizedBox(height: 20),
              _SectionTitle(title: 'Describe the Issue', color: colors.title),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                onChanged: (_) => _saveDraft(),
                style: TextStyle(color: colors.title),
                decoration: InputDecoration(
                  hintText: 'Enter description',
                  hintStyle: TextStyle(color: colors.subtitle),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              // Add Photo
              const SizedBox(height: 20),
              _SectionTitle(title: 'Add Photo', color: colors.title),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.panelBg,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        _uploadedImage = await ImagePickerProvider().pickImage(
                          ImageSource.camera,
                        );
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        color: colors.accent,
                      ),
                      label: Text(
                        'Take a Picture',
                        style: TextStyle(
                          color: colors.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.panelBg,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        _uploadedImage = await ImagePickerProvider().pickImage(
                          ImageSource.gallery,
                        );
                        setState(() {});
                      },
                      icon: Icon(Icons.photo_album, color: colors.accent),
                      label: Text(
                        'Select From Gallery',
                        style: TextStyle(
                          color: colors.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: _uploadedImage == null
                    ? const Text("No Image Selected")
                    : Image.file(_uploadedImage!),
              ),
              _SectionTitle(title: 'Set Location', color: colors.title),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search address',
                        hintStyle: TextStyle(color: colors.subtitle),
                        prefixIcon: Icon(Icons.search, color: colors.accent),
                        filled: true,
                        fillColor: colors.panelBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      onChanged: _onAddressInputChanged,
                      onSubmitted: (_) => _searchAddress(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSearchingAddress ? null : _searchAddress,
                    child: _isSearchingAddress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_isLoadingSuggestions || _autoCompletePredictions.isNotEmpty)
                const SizedBox(height: 8),
              if (_isLoadingSuggestions || _autoCompletePredictions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: colors.panelBg,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Searching suggestions...'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _autoCompletePredictions.length,
                          separatorBuilder: (_, separatorIndex) =>
                              Divider(height: 1, color: colors.border),
                          itemBuilder: (context, index) {
                            final suggestion = _autoCompletePredictions[index];
                            final title =
                                suggestion.structuredFormatting?.mainText ??
                                suggestion.description ??
                                '';
                            final subtitle =
                                suggestion.structuredFormatting?.secondaryText;

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.place_outlined,
                                color: colors.accent,
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: subtitle == null
                                  ? null
                                  : Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () => _onSuggestionSelected(suggestion),
                            );
                          },
                        ),
                ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Main map canvas where users can tap to place the report marker.
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLatLng,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onTap: _setPickedLocation,
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Material(
                        color: colors.panelBg,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _isLocatingCurrent
                              ? null
                              : _moveToCurrentLocation,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            // Keep feedback visible while waiting for GPS permission/location.
                            child: _isLocatingCurrent
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.my_location, color: colors.accent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Selected: ${_selectedLatLng.latitude.toStringAsFixed(5)}, '
                '${_selectedLatLng.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _submittingReport
                      ? colors.shadow
                      : colors.accent,
                  foregroundColor: colors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submittingReport ? null : _submit,
                child: _submittingReport
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _ReportPagePalette {
  const _ReportPagePalette({
    required this.pageBg,
    required this.panelBg,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.onAccent,
    required this.shadow,
    required this.appBarBackground,
    required this.appBarForeground,
  });

  final Color pageBg;
  final Color panelBg;
  final Color accent;
  final Color accentSoft;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color onAccent;
  final Color shadow;
  final Color appBarBackground;
  final Color appBarForeground;

  factory _ReportPagePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _ReportPagePalette(
      pageBg: theme.scaffoldBackgroundColor,
      panelBg: cs.surfaceContainerLow,
      accent: cs.primary,
      accentSoft: cs.primaryContainer,
      border: cs.outlineVariant,
      title: cs.onSurface,
      subtitle: cs.onSurfaceVariant,
      onAccent: cs.onPrimary,
      shadow: cs.shadow.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
      ),
      appBarBackground: theme.appBarTheme.backgroundColor ?? cs.surface,
      appBarForeground: theme.appBarTheme.foregroundColor ?? cs.onPrimary,
    );
  }
}
