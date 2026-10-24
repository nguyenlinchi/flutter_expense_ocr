
class AiRecommendation {
  final String title;
  final String detail;
  final double weeklyLimit;

  const AiRecommendation({
    required this.title,
    required this.detail,
    required this.weeklyLimit,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      title: json['title']?.toString() ?? 'Đề xuất',
      detail: json['detail']?.toString() ?? '',
      weeklyLimit: (json['weeklyLimit'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AiAnalysis {
  final String status;
  final String summary;
  final List<String> insights;
  final List<AiRecommendation> recommendations;
  final double recommendedWeeklyLimit;
  final String weeklyReason;
  final String disclaimer;

  const AiAnalysis({
    required this.status,
    required this.summary,
    required this.insights,
    required this.recommendations,
    required this.recommendedWeeklyLimit,
    required this.weeklyReason,
    required this.disclaimer,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    final plan = json['weeklyPlan'] is Map
        ? Map<String, dynamic>.from(json['weeklyPlan'] as Map)
        : <String, dynamic>{};

    final insights = json['insights'] as List? ?? [];
    final recommendations = json['recommendations'] as List? ?? [];

    return AiAnalysis(
      status: json['status']?.toString() ?? 'insufficient_data',
      summary: json['summary']?.toString() ?? '',
      insights: insights.map((e) => e.toString()).toList(),
      recommendations: recommendations
          .whereType<Map>()
          .map(
            (e) => AiRecommendation.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      recommendedWeeklyLimit:
          (plan['recommendedWeeklyLimit'] as num?)?.toDouble() ?? 0,
      weeklyReason: plan['reason']?.toString() ?? '',
      disclaimer: json['disclaimer']?.toString() ?? '',
    );
  }
}
