import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan_detail.dart';

class HistoryTab extends StatefulWidget {
  final String activeProfileId;

  const HistoryTab({
    super.key,
    required this.activeProfileId,
  });

  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  List<Map<String, dynamic>> _allHistory = [];
  bool _isLoadingAllHistory = true;
  bool _isFilterExpanded = false;

  // --- Temp State (สำหรับแสดงในฟอร์มตอนยังไม่กดกรอง) ---
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  String _tempRisk = 'ทั้งหมด';
  String _tempBodyPart = 'ทั้งหมด';
  String _tempDisease = 'ทั้งหมด';

  // --- Active State (ค่าที่ใช้กรองจริงๆ) ---
  DateTime? _activeStartDate;
  DateTime? _activeEndDate;
  String _activeRisk = 'ทั้งหมด';
  String _activeBodyPart = 'ทั้งหมด';
  String _activeDisease = 'ทั้งหมด';

  final List<String> _riskOptions = ['ทั้งหมด', 'ความเสี่ยงสูง', 'ความเสี่ยงต่ำ'];
  final List<String> _bodyPartOptions = ['ทั้งหมด', 'คอ', 'แขน', 'ขา', 'หน้า', 'หลัง'];
  final List<String> _diseaseOptions = [
    'ทั้งหมด', 'ไม่พบโรค', 'Melanoma', 'BCC', 'SCC', 'Actinic Keratosis',
    'Melanocytic Nevi', 'Tinea', 'Keratosis', 'Psoriasis'
  ];

  @override
  void initState() {
    super.initState();
    fetchAllHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _resetFilters(); // เปลี่ยนโปรไฟล์ ให้ล้างตัวกรองและโหลดใหม่
    }
  }

  void _resetFilters() {
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
      _tempRisk = 'ทั้งหมด';
      _tempBodyPart = 'ทั้งหมด';
      _tempDisease = 'ทั้งหมด';
      
      _activeStartDate = null;
      _activeEndDate = null;
      _activeRisk = 'ทั้งหมด';
      _activeBodyPart = 'ทั้งหมด';
      _activeDisease = 'ทั้งหมด';
    });
    fetchAllHistory();
  }

  void _applyFilters() {
    setState(() {
      _activeStartDate = _tempStartDate;
      _activeEndDate = _tempEndDate;
      _activeRisk = _tempRisk;
      _activeBodyPart = _tempBodyPart;
      _activeDisease = _tempDisease;
      _isFilterExpanded = false; // พับเก็บเมื่อกดกรอง
    });
    fetchAllHistory();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_activeStartDate != null || _activeEndDate != null) count++;
    if (_activeRisk != 'ทั้งหมด') count++;
    if (_activeBodyPart != 'ทั้งหมด') count++;
    if (_activeDisease != 'ทั้งหมด') count++;
    return count;
  }

  bool get _hasTempFilter {
    return _tempStartDate != null ||
        _tempEndDate != null ||
        _tempRisk != 'ทั้งหมด' ||
        _tempBodyPart != 'ทั้งหมด' ||
        _tempDisease != 'ทั้งหมด';
  }

  Future<void> fetchAllHistory() async {
    setState(() => _isLoadingAllHistory = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        var query = Supabase.instance.client
            .from('scan_history')
            .select('*')
            .eq('user_id', user.id)
            .eq('profile_id', widget.activeProfileId);

        // 1. กรองจาก Database (ส่วนที่อยู่ในตารางโดยตรง)
        if (_activeBodyPart != 'ทั้งหมด') {
          query = query.eq('body_part', _activeBodyPart);
        }
        if (_activeDisease != 'ทั้งหมด') {
          if (_activeDisease == 'ไม่พบโรค' || _activeDisease == 'ผิวหนังปกติ') {
            query = query.or('result_name.ilike.%ไม่พบโรค%,result_name.ilike.%ปกติ%');
          } else {
            String searchDisease = _activeDisease;
            // ปรับชื่อให้ครอบคลุม (เช่น Nevi / Nevus)
            if (searchDisease == 'Melanocytic Nevi' || searchDisease == 'Melanocytic Nevus') {
              searchDisease = 'Melanocytic';
            }
            query = query.ilike('result_name', '%$searchDisease%');
          }
        }
        if (_activeStartDate != null) {
          query = query.gte('scanned_at', _activeStartDate!.toIso8601String());
        }
        if (_activeEndDate != null) {
          final endOfDay = DateTime(_activeEndDate!.year, _activeEndDate!.month, _activeEndDate!.day, 23, 59, 59);
          query = query.lte('scanned_at', endOfDay.toUtc().toIso8601String());
        }

        final data = await query.order('scanned_at', ascending: false);
        List<Map<String, dynamic>> fetchedList = List<Map<String, dynamic>>.from(data);

        // 2. กรองแบบ Local (สำหรับเรื่องความเสี่ยงสูง/ต่ำ ที่คำนวณจากชื่อโรค)
        if (_activeRisk != 'ทั้งหมด') {
          fetchedList = fetchedList.where((item) {
            var riskInfo = _getRiskLevelInfo(item['result_name'] ?? '');
            bool isHigh = riskInfo['text'] == 'ความเสี่ยงสูง';
            if (_activeRisk == 'ความเสี่ยงสูง' && !isHigh) return false;
            if (_activeRisk == 'ความเสี่ยงต่ำ' && isHigh) return false;
            return true;
          }).toList();
        }

        if (mounted) {
          setState(() {
            _allHistory = fetchedList;
            _isLoadingAllHistory = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAllHistory = false);
      }
    }
  }

  // ใช้รูปแบบวันที่ 1 ม.ค. 2567 สำหรับแสดงผลใน List
  String _formatThaiDateFull(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      List<String> months = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year + 543}";
    } catch (e) {
      return "ไม่ระบุ";
    }
  }

  // รูปแบบวันที่สั้น สำหรับช่อง Input ตัวกรอง
  String _formatShortDate(DateTime? date) {
    if (date == null) return "วว/ดด/ปปปป";
    String d = date.day.toString().padLeft(2, '0');
    String m = date.month.toString().padLeft(2, '0');
    return "$d/$m/${date.year}";
  }

  Map<String, dynamic> _getRiskLevelInfo(String diseaseName) {
    String nameLower = diseaseName.toLowerCase();
    bool isHighRisk = nameLower.contains("melanoma") ||
        nameLower.contains("เมลาโนมา") ||
        nameLower.contains("basal") ||
        nameLower.contains("bcc") ||
        nameLower.contains("squamous") ||
        nameLower.contains("scc") ||
        nameLower.contains("actinic") ||
        nameLower.contains("มะเร็ง");

    if (isHighRisk) {
      return {'text': 'ความเสี่ยงสูง', 'color': Colors.red, 'bgColor': Colors.red.shade50};
    } else {
      return {'text': 'ความเสี่ยงต่ำ', 'color': const Color(0xFF009688), 'bgColor': const Color(0xFFE0F2F1)};
    }
  }

  void _removeActiveFilter(String filterType) {
    setState(() {
      if (filterType == 'date') {
        _activeStartDate = null;
        _activeEndDate = null;
        _tempStartDate = null;
        _tempEndDate = null;
      } else if (filterType == 'risk') {
        _activeRisk = 'ทั้งหมด';
        _tempRisk = 'ทั้งหมด';
      } else if (filterType == 'body_part') {
        _activeBodyPart = 'ทั้งหมด';
        _tempBodyPart = 'ทั้งหมด';
      } else if (filterType == 'disease') {
        _activeDisease = 'ทั้งหมด';
        _tempDisease = 'ทั้งหมด';
      }
    });
    fetchAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        color: const Color(0xFF009688),
        onRefresh: fetchAllHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              width: double.infinity,
              color: Colors.white,
              child: const Center(
                child: Text(
                  "ประวัติการประเมิน",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
              ),
            ),

            // Filter Header & Tags
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ปุ่มเปิดปิดกล่องตัวกรอง
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                        if (_isFilterExpanded) {
                          // ถ้าเปิดขึ้นมาให้ reset temp ให้ตรงกับ active ล่าสุด
                          _tempStartDate = _activeStartDate;
                          _tempEndDate = _activeEndDate;
                          _tempRisk = _activeRisk;
                          _tempBodyPart = _activeBodyPart;
                          _tempDisease = _activeDisease;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt_outlined, color: Color(0xFF009688), size: 20),
                          const SizedBox(width: 8),
                          const Text("ตัวกรองประวัติ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF009688),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _activeFilterCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            _isFilterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องตัวกรอง (ขยายลงมา)
                  if (_isFilterExpanded) _buildFilterPanel(),

                  // แท็กตัวกรองที่เลือกไว้แล้ว (Active Filters)
                  if (!_isFilterExpanded && _activeFilterCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_activeStartDate != null || _activeEndDate != null)
                              _buildActiveFilterChip('วันที่เลือกแล้ว', 'date'),
                            if (_activeRisk != 'ทั้งหมด')
                              _buildActiveFilterChip(_activeRisk, 'risk'),
                            if (_activeBodyPart != 'ทั้งหมด')
                              _buildActiveFilterChip(_activeBodyPart, 'body_part'),
                            if (_activeDisease != 'ทั้งหมด')
                              _buildActiveFilterChip(_activeDisease, 'disease'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // รายการข้อมูลประวัติ
            if (_isLoadingAllHistory)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
              )
            else if (_allHistory.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: _allHistory.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildFullHistoryCard(_allHistory[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- UI กล่องตั้งค่าตัวกรอง (Filter Panel) ---
  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ช่วงวันที่
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Color(0xFF009688), size: 18),
              const SizedBox(width: 8),
              const Text("ช่วงวันที่", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) setState(() => _tempStartDate = picked);
                  },
                  child: _buildDateInputBox(_formatShortDate(_tempStartDate)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text("ถึง", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) setState(() => _tempEndDate = picked);
                  },
                  child: _buildDateInputBox(_formatShortDate(_tempEndDate)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. ความเสี่ยง
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF009688), size: 18),
              const SizedBox(width: 8),
              const Text("ความเสี่ยง", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _riskOptions.map((e) => _buildChoiceChip(
              label: e,
              isSelected: _tempRisk == e,
              onTap: () => setState(() => _tempRisk = e),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // 3. บริเวณที่เป็น
          Row(
            children: [
              const Icon(Icons.accessibility_new_outlined, color: Color(0xFF009688), size: 18),
              const SizedBox(width: 8),
              const Text("บริเวณที่เป็น", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyPartOptions.map((e) => _buildChoiceChip(
              label: e,
              isSelected: _tempBodyPart == e,
              onTap: () => setState(() => _tempBodyPart = e),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // 4. โรค
          Row(
            children: [
              const Icon(Icons.coronavirus_outlined, color: Color(0xFF009688), size: 18),
              const SizedBox(width: 8),
              const Text("โรค", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _diseaseOptions.map((e) => _buildChoiceChip(
              label: e,
              isSelected: _tempDisease == e,
              onTap: () => setState(() => _tempDisease = e),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // ปุ่ม Action (ล้างค่า & กรองข้อมูล)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // แค่รีเซ็ตค่า Temp ไว้ก่อน
                    setState(() {
                      _tempStartDate = null;
                      _tempEndDate = null;
                      _tempRisk = 'ทั้งหมด';
                      _tempBodyPart = 'ทั้งหมด';
                      _tempDisease = 'ทั้งหมด';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text("ล้างค่า", style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _hasTempFilter ? const Color(0xFF009688) : Colors.grey.shade300,
                    foregroundColor: _hasTempFilter ? Colors.white : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 18),
                      SizedBox(width: 6),
                      Text("กรองข้อมูล", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Components ย่อย ---
  Widget _buildDateInputBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const Icon(Icons.calendar_month, color: Colors.black87, size: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, String filterType) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1), // Light Teal
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF009688), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeActiveFilter(filterType),
            child: const Icon(Icons.close, color: Color(0xFF009688), size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Color(0xFF009688), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _activeFilterCount > 0 ? "ไม่พบประวัติที่ตรงกับตัวกรอง" : "ยังไม่มีประวัติการประเมินรอยโรค",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullHistoryCard(Map<String, dynamic> item) {
    String dateStr = _formatThaiDateFull(item['scanned_at'] ?? '');
    String diseaseName = item['result_name'] ?? 'ไม่ทราบผลลัพธ์';
    if (diseaseName.contains('ปกติ') || diseaseName.toLowerCase().contains('normal')) {
      diseaseName = 'ไม่พบโรค';
    }
    String bodyPart = item['body_part'] ?? 'ไม่ระบุบริเวณ';
    String? imageUrl = item['image_url'];
    var riskInfo = _getRiskLevelInfo(diseaseName);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanDetailScreen(historyItem: item, riskInfo: riskInfo),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      cacheHeight: 240,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diseaseName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("บริเวณที่เป็น: $bodyPart", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: riskInfo['bgColor'], borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: riskInfo['color'], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          riskInfo['text'],
                          style: TextStyle(fontSize: 12, color: riskInfo['color'], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
