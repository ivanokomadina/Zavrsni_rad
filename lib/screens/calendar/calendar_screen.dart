import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/obligation_provider.dart';
import '../../widgets/obligation_card.dart';
import '../../widgets/app_bottom_nav.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // focusedDay = koji mjesec je trenutno prikazan u gridu
  // selectedDay = koji je dan korisnik kliknuo (za prikaz obveza ispod)
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final monthLogsAsync = ref.watch(monthLogsProvider(_focusedDay));
    final allObligations = ref.watch(obligationsProvider);

    // Obveze čiji je rok jednak odabranom danu
    final obligationsForSelectedDay = allObligations
        .where((o) => _isSameDay(o.dueDate, _selectedDay))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kalendar')),
      body: Column(
        children: [
          monthLogsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Greška pri učitavanju: $err')),
            ),
            data: (monthLogs) => _buildCalendar(monthLogs, allObligations),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Obveze za odabrani dan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          Expanded(
            child: obligationsForSelectedDay.isEmpty
                ? const Center(child: Text('Nema obveza za ovaj dan'))
                : ListView.builder(
                    itemCount: obligationsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final o = obligationsForSelectedDay[index];
                      return ObligationCard(
                        obligation: o,
                        onStatusTap: () => ref
                            .read(obligationsProvider.notifier)
                            .cycleStatus(o),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildCalendar(List monthLogs, List allObligations) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },

      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      calendarFormat: CalendarFormat.month,

      eventLoader: (day) {
        final events = [];
        events.addAll(
          monthLogs.where((log) => _isSameDay(log.date, day) && log.completed),
        );
        events.addAll(allObligations.where((o) => _isSameDay(o.dueDate, day)));
        return events;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}
