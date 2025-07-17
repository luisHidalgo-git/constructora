import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LocationPickerWidget extends StatefulWidget {
  final String? initialLocation;
  final Function(String) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  String _selectedLocation = '';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? '';
  }

  Future<void> _openLocationPicker() async {
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Permisos de ubicación denegados', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Permisos de ubicación denegados permanentemente', isError: true);
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      // Abrir el mapa para seleccionar ubicación
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
        ),
      );

      if (result != null && result is String) {
        setState(() {
          _selectedLocation = result;
        });
        widget.onLocationSelected(result);
      }
    } catch (e) {
      _showMessage('Error al obtener ubicación: ${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedLocation.isNotEmpty
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedLocation.isNotEmpty
                      ? Icons.location_on
                      : Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLocation.isNotEmpty
                          ? 'Ubicación seleccionada'
                          : 'Seleccionar ubicación',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 14,
                        color: _selectedLocation.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textGray,
                      ),
                    ),
                    if (_selectedLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedLocation,
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Toca para abrir el mapa',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.iconGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerScreen({
    super.key,
    required this.initialPosition,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(widget.initialPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress = 
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'
                  .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
                  .replaceAll(RegExp(r',\s*,'), ',');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Ubicación seleccionada';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromLatLng(position);
  }

  void _confirmSelection() {
    if (_selectedAddress.isNotEmpty) {
      Navigator.pop(context, _selectedAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Ubicación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.iconDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectedPosition != null ? _confirmSelection : null,
            child: Text(
              'Confirmar',
              style: TextStyle(
                color: _selectedPosition != null
                    ? AppColors.primary
                    : AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Address display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ubicación seleccionada:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Obteniendo dirección...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _selectedAddress.isNotEmpty
                        ? _selectedAddress
                        : 'Toca en el mapa para seleccionar una ubicación',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                  onTap: _onMapTapped,
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedPosition!,
                            infoWindow: const InfoWindow(
                              title: 'Ubicación seleccionada',
                            ),
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textGray,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toca en cualquier lugar del mapa para seleccionar la ubicación del proyecto',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
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