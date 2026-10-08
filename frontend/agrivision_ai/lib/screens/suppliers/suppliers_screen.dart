import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supplier_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// Looks up [key] and substitutes `{name}`-style placeholders in [args].
String _trArgs(BuildContext context, String key, Map<String, String> args) {
  var text = context.tr(key);
  args.forEach((k, v) => text = text.replaceAll('{$k}', v));
  return text;
}

class SuppliersScreen extends StatefulWidget {
  /// Optional treatment/fungicide name passed in from a scan result.
  /// Used as a best-effort filter against shop NAMES only — see the
  /// note in SupplierService.searchSuppliers for why OSM can't do
  /// true product-level search.
  final String? initialSearchQuery;

  const SuppliersScreen({super.key, this.initialSearchQuery});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  Timer? _debounce;

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _error;
  double? _lat;
  double? _lon;
  List<Supplier> _suppliers = [];
  int _currentRadiusMeters = 15000;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchQuery ?? '';
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _supplierService.getCurrentLocation();
      _lat = position.latitude;
      _lon = position.longitude;
      await _runSearch(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _runSearch(String query, {int? radiusMeters}) async {
    if (_lat == null || _lon == null) return;

    final radius = radiusMeters ?? _currentRadiusMeters;
    setState(() => _isLoading = true);

    try {
      final results = await _supplierService.searchSuppliers(
        query: query,
        lat: _lat!,
        lon: _lon!,
        radiusMeters: radius,
      );
      if (!mounted) return;
      setState(() {
        _suppliers = results;
        _error = null;
        _isLoading = false;
        _hasLoadedOnce = true;
        _currentRadiusMeters = radius;
      });
      _fitMapToResults();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _isLoading = false);

      // If we already have results on screen from a previous
      // successful search, don't wipe them out over a transient
      // failure (e.g. the free Overpass server timing out under
      // load) — just tell the farmer via a snackbar and let them
      // keep looking at what they already found. Only show the
      // full-screen error state if this was the very first search
      // and there's nothing to fall back to.
      if (_hasLoadedOnce && _suppliers.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_trArgs(context, 'suppliers_search_failed', {'error': message}))),
          );
        }
      } else {
        setState(() => _error = message);
      }
    }
  }

  Future<void> _expandSearch() async {
    final wider = (_currentRadiusMeters * 2).clamp(0, 50000);
    await _runSearch(_searchController.text, radiusMeters: wider);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _runSearch(value));
  }

  void _fitMapToResults() {
    if (_lat == null || _lon == null) return;

    if (_suppliers.isEmpty) {
      _mapController.move(LatLng(_lat!, _lon!), 13);
      return;
    }

    final points = [LatLng(_lat!, _lon!), ..._suppliers.map((s) => LatLng(s.latitude, s.longitude))];
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _recenter() {
    if (_lat == null || _lon == null) return;
    _fitMapToResults();
  }

  void _showSupplierSheet(Supplier s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SupplierDetailSheet(supplier: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nearby_suppliers'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: context.tr('suppliers_search_hint'),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _runSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.greenLightBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _trArgs(context, 'suppliers_looking_for', {'query': widget.initialSearchQuery!}),
                    style: const TextStyle(color: AppColors.greenMid, fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (_lat != null && _lon != null)
            SizedBox(
              width: double.infinity,
              height: 280,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_lat!, _lon!),
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.agrivision_ai',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat!, _lon!),
                            width: 26,
                            height: 26,
                            child: const Icon(Icons.my_location, color: AppColors.blue, size: 22),
                          ),
                        ],
                      ),
                      // Clustered supplier markers — nearby pins collapse
                      // into a single numbered circle at lower zoom
                      // levels, and expand automatically as the farmer
                      // zooms in, instead of overlapping illegibly.
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(36, 36),
                          markers: _suppliers
                              .map(
                                (s) => Marker(
                                  point: LatLng(s.latitude, s.longitude),
                                  width: 34,
                                  height: 34,
                                  child: GestureDetector(
                                    onTap: () => _showSupplierSheet(s),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.greenDark,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.storefront, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.greenMain,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // OSM's attribution text is a license requirement and is
                  // conventionally left in English regardless of app locale.
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      color: Colors.white.withValues(alpha: 0.7),
                      child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 7)),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: Icons.add,
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(
                          icon: Icons.remove,
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(icon: Icons.my_location, onTap: _recenter),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!_isLoading && _suppliers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _trArgs(
                    context,
                    _suppliers.length == 1 ? 'suppliers_shops_found_singular' : 'suppliers_shops_found_plural',
                    {'count': '${_suppliers.length}'},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Expanded(child: _buildList(theme)),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_isLoading && _suppliers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _suppliers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 40, color: AppColors.greenAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadInitial, child: Text(context.tr('try_again'))),
            ],
          ),
        ),
      );
    }

    if (_suppliers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 40, color: AppColors.greenAccent),
              const SizedBox(height: 12),
              Text(
                _trArgs(context, 'suppliers_none_found', {'radius': (_currentRadiusMeters / 1000).round().toString()}),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (_currentRadiusMeters < 50000) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _expandSearch,
                  icon: const Icon(Icons.zoom_out_map, size: 16),
                  label: Text(
                    _trArgs(context, 'suppliers_search_wider', {'radius': (_currentRadiusMeters * 2 / 1000).round().toString()}),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: _suppliers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            final s = _suppliers[index];
            return Material(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showSupplierSheet(s),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.greenDark, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.storefront_outlined, color: AppColors.greenPale, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(s.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                                Text(s.distanceLabel, style: const TextStyle(fontSize: 9.5, color: AppColors.greenMain, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // s.category is data from OpenStreetMap tags
                            // (e.g. "Agricultural Supplies"), not app UI —
                            // left untranslated since OSM doesn't provide
                            // localized values for this field.
                            Text(s.category, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_isLoading)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(context.tr('searching'), style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.greenDark),
        ),
      ),
    );
  }
}

class _SupplierDetailSheet extends StatelessWidget {
  final Supplier supplier;
  const _SupplierDetailSheet({required this.supplier});

  Future<void> _openDirections(BuildContext context) async {
    // A geo: URI with a query lets the device's own default maps app
    // (Google Maps, or whatever the farmer has set) handle routing —
    // this avoids hardcoding to one specific maps app. Falls back to
    // a Google Maps web URL if no app can handle geo: at all (some
    // devices without a maps app installed).
    final geoUri = Uri.parse(
      'geo:${supplier.latitude},${supplier.longitude}?q=${supplier.latitude},${supplier.longitude}(${Uri.encodeComponent(supplier.name)})',
    );
    final webFallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${supplier.latitude},${supplier.longitude}',
    );

    bool launched = false;
    try {
      launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      launched = false;
    }

    if (!launched) {
      try {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('suppliers_no_maps_app'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.greenDark, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.storefront_outlined, color: AppColors.greenPale, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(supplier.category, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.directions_walk, size: 15, color: AppColors.greenMain),
              const SizedBox(width: 6),
              Text('${supplier.distanceLabel} ${context.tr('away_suffix')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openDirections(context),
            icon: const Icon(Icons.directions, size: 16),
            label: Text(context.tr('get_directions')),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }
}