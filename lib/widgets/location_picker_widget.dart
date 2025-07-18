import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
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

  Future<bool> _checkLocationPermissions() async {
    try {
      PermissionStatus locationStatus = await Permission.location.request();

      if (locationStatus.isDenied) {
        _showMessage('Permisos de ubicación denegados', isError: true);
        return false;
      }

      if (locationStatus.isPermanentlyDenied) {
        _showMessage(
          'Ve a Configuración > Aplicaciones > Constructora > Permisos para habilitar ubicación.',
          isError: true,
        );
        return false;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(
          'Habilita el servicio de ubicación en Configuración.',
          isError: true,
        );
        return false;
      }

      return true;
    } catch (e) {
      _showMessage(
        'Error verificando permisos: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<void> _openLocationPicker() async {
    try {
      bool hasPermission = await _checkLocationPermissions();
      if (!hasPermission) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Obtener ubicación actual
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        // Si falla, usar ubicación por defecto (Lima, Perú)
        position = Position(
          latitude: -12.0464,
          longitude: -77.0428,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Abrir mapa
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleMapPickerScreen(
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
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showMessage('Error: ${e.toString()}', isError: true);
      }
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
        duration: Duration(seconds: isError ? 4 : 2),
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
              const Icon(
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

class SimpleMapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  const SimpleMapPickerScreen({super.key, required this.initialPosition});

  @override
  State<SimpleMapPickerScreen> createState() => _SimpleMapPickerScreenState();
}

class _SimpleMapPickerScreenState extends State<SimpleMapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(widget.initialPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        setState(() {
          _selectedAddress = address.isNotEmpty
              ? address
              : 'Ubicación seleccionada';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
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

  Future<void> _moveToCurrentLocation() async {
    if (_mapController == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPosition, zoom: 16.0),
        ),
      );

      setState(() {
        _selectedPosition = newPosition;
      });

      _getAddressFromLatLng(newPosition);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
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
                if (_isLoadingAddress)
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
                        : 'Toca en el mapa para seleccionar',
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
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: widget.initialPosition,
                        zoom: 15.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        // Dar tiempo para que el mapa se inicialice
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            setState(() {
                              _mapReady = true;
                            });
                          }
                        });
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
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      buildingsEnabled: true,
                      indoorViewEnabled: true,
                      trafficEnabled: false,
                      liteModeEnabled: false,
                    ),

                    // Loading overlay
                    if (!_mapReady)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargando Google Maps...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Esto puede tomar unos segundos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current location button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _mapReady ? _moveToCurrentLocation : null,
              icon: const Icon(Icons.my_location, size: 20),
              label: const Text('Usar mi ubicación actual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mapReady ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

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
                Icon(Icons.info_outline, color: AppColors.textGray, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toca en cualquier lugar del mapa para seleccionar la ubicación del proyecto.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
