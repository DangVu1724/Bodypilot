import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/data/models/exercise_smart_swap_model.dart';
import 'package:mobile/data/repositories/smart_swap_repository.dart';

class ExerciseSmartSwapBottomSheet extends StatefulWidget {
  final String exerciseId;
  final String currentExerciseName;
  final Function(ExerciseSmartSwapCandidateModel candidate)? onExerciseSwapped;

  const ExerciseSmartSwapBottomSheet({
    super.key,
    required this.exerciseId,
    required this.currentExerciseName,
    this.onExerciseSwapped,
  });

  static void show(
    BuildContext context, {
    required String exerciseId,
    required String currentExerciseName,
    Function(ExerciseSmartSwapCandidateModel candidate)? onExerciseSwapped,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ExerciseSmartSwapBottomSheet(
        exerciseId: exerciseId,
        currentExerciseName: currentExerciseName,
        onExerciseSwapped: onExerciseSwapped,
      ),
    );
  }

  @override
  State<ExerciseSmartSwapBottomSheet> createState() => _ExerciseSmartSwapBottomSheetState();
}

class _ExerciseSmartSwapBottomSheetState extends State<ExerciseSmartSwapBottomSheet> {
  bool _isLoading = true;
  String? _error;
  List<ExerciseSmartSwapCandidateModel> _candidates = [];

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await smartSwapRepository.getExerciseSwapCandidates(exerciseId: widget.exerciseId);
      if (mounted) {
        setState(() {
          _candidates = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark Slate theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đổi Bài Tập Tương Đương',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Đổi "${widget.currentExerciseName}" • An toàn chấn thương',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: Colors.white12),

          // Candidates List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        SizedBox(height: 16),
                        Text(
                          'Đang lọc bài tập an toàn cùng nhóm cơ...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: Color(0xFF38BDF8), size: 36),
                              const SizedBox(height: 12),
                              Text(
                                _error!.contains('DioException') || _error!.contains('connection error')
                                    ? 'Không có kết nối mạng.'
                                    : 'Không thể kết nối máy chủ.',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _fetchCandidates,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Thử lại'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _candidates.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy bài tập thay thế phù hợp.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _candidates.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final candidate = _candidates[index];
                              return _buildExerciseCandidateCard(context, candidate);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCandidateCard(BuildContext context, ExerciseSmartSwapCandidateModel candidate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.network(
                    candidate.mediaUrl ?? 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=200&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF334155),
                      child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhóm cơ: ${candidate.targetMuscleName} • ${candidate.bodyPartName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reason Tag & METs
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  candidate.matchReason,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${candidate.metValue} METs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Select Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onExerciseSwapped?.call(candidate);
              },
              child: Text(
                'Chọn bài tập này',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
