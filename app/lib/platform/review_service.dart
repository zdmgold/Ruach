import 'package:in_app_review/in_app_review.dart';
import 'package:ruach/core/ports/device_ports.dart';

/// The store's own rating prompt. The store decides whether it appears; the
/// game asks at most once, after a podium finish (blueprint section 3).
final class ReviewService implements ReviewPort {
  ReviewService({InAppReview? review}) : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } on Object {
      // Not being able to ask is not an error.
    }
  }
}
