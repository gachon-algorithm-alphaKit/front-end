import 'package:flutter/material.dart';

import '../../../api/campus_navigation_service.dart';
import '../../../component/common_widgets.dart';

/// 출발지·경유지·도착지 입력 폼 카드
class RouteInputCard extends StatelessWidget {
  final TextEditingController departCtrl;
  final TextEditingController destCtrl;
  final List<TextEditingController> waypointCtrls;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onAddWaypoint;
  final void Function(int index) onRemoveWaypoint;

  const RouteInputCard({
    super.key,
    required this.departCtrl,
    required this.destCtrl,
    required this.waypointCtrls,
    required this.isLoading,
    required this.onSearch,
    required this.onAddWaypoint,
    required this.onRemoveWaypoint,
  });

  static final _buildings = CampusNavigationService.buildingNames;

  @override
  Widget build(BuildContext context) {
    return buildCard(
      child: Column(
        children: [
          _buildingField(departCtrl, '출발지', Icons.radio_button_checked, Colors.green),
          ...waypointCtrls.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(child: _buildingField(e.value, '경유지 ${e.key + 1}', Icons.add_location_alt, Colors.orange)),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                    onPressed: () => onRemoveWaypoint(e.key),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildingField(destCtrl, '도착지', Icons.location_on, Colors.red),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: waypointCtrls.length < 3 ? onAddWaypoint : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('경유지 추가', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onSearch,
                  icon: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.route, size: 18),
                  label: Text(isLoading ? '계산 중 (A*)...' : '최적 경로 탐색'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildingField(TextEditingController ctrl, String hint, IconData icon, Color color) {
    return Autocomplete<String>(
      key: ObjectKey(ctrl),
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (v) => v.text.isEmpty ? const [] : _buildings.where((b) => b.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: (s) {
        ctrl.text = s;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      fieldViewBuilder: (ctx, ctrl2, fn, onSubmit) {
        return TextField(
          controller: ctrl2,
          focusNode: fn,
          onChanged: (val) => ctrl.text = val,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: hint,
            prefixIcon: Icon(icon, color: color, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        );
      },
    );
  }
}
