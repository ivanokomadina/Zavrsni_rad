import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/obligation.dart';
import '../services/obligation_service.dart';
import '../services/notification_service.dart';
import 'notification_settings_provider.dart';

const _statusCycle = ['pending', 'in_progress', 'done'];

class ObligationsNotifier extends StateNotifier<List<Obligation>> {
  final ObligationService _service;
  final Ref _ref; // omogućuje čitanje drugih providera iz ovog notifiera

  ObligationsNotifier(this._service, this._ref) : super([]) {
    loadObligations();
  }

  /// Provjerava jesu li notifikacije trenutno dopuštene - čitamo
  /// notificationsEnabledProvider preko _ref.read() (ne watch, jer
  /// StateNotifier ne "rebuilda" ovisno o tuđim promjenama, samo nas
  /// zanima TRENUTNA vrijednost u trenutku poziva).
  bool get _notificationsAllowed => _ref.read(notificationsEnabledProvider);

  Future<void> loadObligations() async {
    state = await _service.getAllObligations();
  }

  Future<void> addObligation(Obligation obligation) async {
    final id = await _service.insertObligation(obligation);

    if (_notificationsAllowed) {
      // obligation u ovom trenutku još nema id (bio je null prije
      // spremanja) - gradimo novu instancu SA stvarnim id-em iz baze,
      // jer notifikacija treba taj id.
      final saved = Obligation(
        id: id,
        name: obligation.name,
        description: obligation.description,
        dueDate: obligation.dueDate,
        priority: obligation.priority,
        categoryId: obligation.categoryId,
        status: obligation.status,
      );
      await NotificationService.instance.scheduleObligationReminder(saved);
    }

    await loadObligations();
  }

  Future<void> updateObligation(Obligation obligation) async {
    await _service.updateObligation(obligation);

    // Ponovno zakazivanje s ISTIM id-em automatski prepisuje staru
    // notifikaciju (vidi objašnjenje u notification_service.dart) -
    // tako promjena roka odmah ažurira i vrijeme podsjetnika.
    if (_notificationsAllowed) {
      await NotificationService.instance.scheduleObligationReminder(obligation);
    }

    await loadObligations();
  }

  Future<void> deleteObligation(int id) async {
    await _service.deleteObligation(id);
    await NotificationService.instance.cancelObligationReminder(id);
    await loadObligations();
  }

  Future<void> cycleStatus(Obligation obligation) async {
    final currentIndex = _statusCycle.indexOf(obligation.status);
    final nextIndex = (currentIndex + 1) % _statusCycle.length;
    final newStatus = _statusCycle[nextIndex];

    await _service.updateStatus(id: obligation.id!, newStatus: newStatus);

    // Ako je obveza sad gotova, nema smisla dalje podsjećati na
    // rok koji je već ispunjen.
    if (newStatus == 'done') {
      await NotificationService.instance.cancelObligationReminder(
        obligation.id!,
      );
    }

    await loadObligations();
  }
}

final obligationsProvider =
    StateNotifierProvider<ObligationsNotifier, List<Obligation>>((ref) {
      return ObligationsNotifier(
        ObligationService(),
        ref,
      ); // ref se sad prosljeđuje
    });
