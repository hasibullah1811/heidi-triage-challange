import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

// --- ENUMS & MODEL ---
enum Intent {
  emergency,
  prescription,
  scheduling,
  billing,
  medical_records,
  complaint,
  unknown,
}

enum Urgency { critical, high, medium, low }

enum ItemStatus { inbox, escalated, completed }

class Voicemail {
  final String id;
  final String patientName;
  final String timeReceived;
  final String summary;
  final String fullTranscript;
  final Intent intent;
  final Urgency urgency;
  final List<String> suggestedActions;
  final double confidenceScore;
  final List<String> detectedKeywords;
  ItemStatus status;

  Voicemail({
    required this.id,
    required this.patientName,
    required this.timeReceived,
    required this.summary,
    required this.fullTranscript,
    required this.intent,
    required this.urgency,
    required this.suggestedActions,
    required this.confidenceScore,
    required this.detectedKeywords,
    this.status = ItemStatus.inbox,
  });
}

void main() {
  runApp(const HeidiVoicemailApp());
}

class HeidiVoicemailApp extends StatelessWidget {
  const HeidiVoicemailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heidi Triage',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          surface: Colors.white,
          outline: const Color(0xFFE5E7EB),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: const Color(0xFF1F2937),
              displayColor: const Color(0xFF111827),
            ),
        dividerTheme: const DividerThemeData(color: Color(0xFFF3F4F6)),
      ),
      home: const TriageDashboard(),
    );
  }
}

class TriageDashboard extends StatefulWidget {
  const TriageDashboard({super.key});

  @override
  State<TriageDashboard> createState() => _TriageDashboardState();
}

class _TriageDashboardState extends State<TriageDashboard> {
  List<Voicemail> allVoicemails = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  String _searchQuery = "";

  // Helper to check screen size
  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    loadMockData();
  }

  Future<void> loadMockData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/mock_voicemails.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        allVoicemails = data
            .map(
              (item) => Voicemail(
                id: item['id'],
                patientName: item['patientName'],
                timeReceived: item['timeReceived'],
                summary: item['summary'],
                fullTranscript: item['fullTranscript'],
                intent: _parseIntent(item['intent']),
                urgency: _parseUrgency(item['urgency']),
                suggestedActions: List<String>.from(item['suggestedActions']),
                confidenceScore: item['confidenceScore'].toDouble(),
                detectedKeywords: List<String>.from(
                  item['detectedKeywords'] ?? [],
                ),
              ),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Intent _parseIntent(String value) => Intent.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => Intent.unknown,
  );
  Urgency _parseUrgency(String value) => Urgency.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => Urgency.low,
  );

  List<Voicemail> get currentList {
    List<Voicemail> filtered;
    if (_selectedIndex == 0)
      filtered = allVoicemails
          .where((v) => v.status == ItemStatus.inbox)
          .toList();
    else if (_selectedIndex == 1)
      filtered = allVoicemails
          .where((v) => v.status == ItemStatus.escalated)
          .toList();
    else
      filtered = allVoicemails
          .where((v) => v.status == ItemStatus.completed)
          .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (v) =>
                v.patientName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                v.summary.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedIndex != 2)
      filtered.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
    return filtered;
  }

  String _generateDraftMessage(Voicemail vm, String actionLabel) {
    String greeting = "Hi ${vm.patientName.split(' ')[0]},";
    if (actionLabel.contains("Ready"))
      return "$greeting your prescription is ready for pickup. \n\n- Harbour GP";
    if (actionLabel.contains("Confirm"))
      return "$greeting appointment cancelled as requested. \n\n- Harbour GP";
    return "$greeting regarding your voicemail: request received and actioned. \n\n- Harbour GP";
  }

  void _processAction(Voicemail vm, String action) {
    if (action.contains("SMS") ||
        action.contains("Message") ||
        action.contains("Confirm")) {
      _showSMSPreview(vm, action);
      return;
    }
    _executeAction(vm, action);
  }

  void _executeAction(Voicemail vm, String action, {String? customMessage}) {
    setState(() {
      if (action.toLowerCase().contains("escalate") ||
          action.toLowerCase().contains("call now")) {
        vm.status = ItemStatus.escalated;
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnack("Escalated to Dr. Kelly", Colors.amber.shade900, vm),
        );
      } else {
        vm.status = ItemStatus.completed;
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnack("Action completed", Colors.green.shade700, vm),
        );
      }
    });
  }

  SnackBar _buildSnack(String msg, Color color, Voicemail vm) {
    return SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      width: isMobile(context) ? null : 400, // Full width on mobile
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: SnackBarAction(
        label: "UNDO",
        textColor: Colors.white,
        onPressed: () => setState(() => vm.status = ItemStatus.inbox),
      ),
    );
  }

  Future<void> _showSMSPreview(Voicemail vm, String actionLabel) async {
    TextEditingController controller = TextEditingController(
      text: _generateDraftMessage(vm, actionLabel),
    );
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Review Draft',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _executeAction(vm, actionLabel, customMessage: controller.text);
            },
            child: const Text("Send Message"),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      "H",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Heidi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _navItem(
            0,
            "Inbox",
            Icons.inbox_outlined,
            count: allVoicemails
                .where((v) => v.status == ItemStatus.inbox)
                .length,
          ),
          _navItem(
            1,
            "Escalated",
            Icons.warning_amber_rounded,
            count: allVoicemails
                .where((v) => v.status == ItemStatus.escalated)
                .length,
          ),
          _navItem(
            2,
            "Completed",
            Icons.check_circle_outline,
            count: allVoicemails
                .where((v) => v.status == ItemStatus.completed)
                .length,
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String title, IconData icon, {int count = 0}) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (isMobile(context)) Navigator.pop(context); // Close drawer on mobile
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool mobile = isMobile(context);

    // THE RESPONSIVE SCAFFOLD
    return Scaffold(
      appBar: mobile
          ? AppBar(
              title: const Text(
                "Heidi Triage",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            )
          : null,
      drawer: mobile
          ? Drawer(child: _buildSidebar())
          : null, // Sidebar becomes Drawer on Mobile
      body: Row(
        children: [
          // Sidebar (Only visible on Desktop)
          if (!mobile)
            Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: _buildSidebar(),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar (Only visible on Desktop)
                if (!mobile)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedIndex == 0
                              ? "Triage Inbox"
                              : _selectedIndex == 1
                              ? "Escalations"
                              : "History",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 240,
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: "Search...",
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // List Area
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : currentList.isEmpty
                      ? Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(mobile ? 16 : 32),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) => VoicemailCard(
                            vm: currentList[index],
                            onAction: (a) =>
                                _processAction(currentList[index], a),
                            isMobile: mobile,
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

class VoicemailCard extends StatefulWidget {
  final Voicemail vm;
  final Function(String) onAction;
  final bool isMobile;
  const VoicemailCard({
    super.key,
    required this.vm,
    required this.onAction,
    this.isMobile = false,
  });

  @override
  State<VoicemailCard> createState() => _VoicemailCardState();
}

class _VoicemailCardState extends State<VoicemailCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isCritical = widget.vm.urgency == Urgency.critical;

    Color statusBg = isCritical
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    Color statusText = isCritical
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    if (widget.vm.urgency == Urgency.medium) {
      statusBg = const Color(0xFFFFF7ED);
      statusText = const Color(0xFFEA580C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isExpanded ? Icons.pause : Icons.play_arrow_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row (Name + Badge)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.vm.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.vm.urgency.name.toUpperCase(),
                                style: TextStyle(
                                  color: statusText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (!widget.isMobile) ...[
                              const Spacer(),
                              Text(
                                widget.vm.timeReceived,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.isMobile) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.vm.timeReceived,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),
                        Text(
                          widget.vm.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            height: 1.4,
                          ),
                        ),

                        // KEYWORDS
                        if (widget.vm.detectedKeywords.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.vm.detectedKeywords
                                .map(
                                  (k) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      k,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ACTIONS (Using Wrap for Mobile Safety)
          if (widget.vm.suggestedActions.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isMobile ? 20 : 72,
                0,
                20,
                20,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.vm.suggestedActions.map((action) {
                  bool isAlert =
                      action.toLowerCase().contains("call") ||
                      action.toLowerCase().contains("escalate");
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isAlert
                          ? Colors.red.shade700
                          : Colors.black87,
                      side: BorderSide(
                        color: isAlert
                            ? Colors.red.shade100
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      backgroundColor: isAlert
                          ? Colors.red.shade50.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    onPressed: () => widget.onAction(action),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // EXPANDED TRANSCRIPT
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                color: Color(0xFFFAFAFA),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TRANSCRIPT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.vm.fullTranscript,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Extra Actions for Mobile inside expansion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          "Escalate",
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () => widget.onAction("Manual Escalate"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
