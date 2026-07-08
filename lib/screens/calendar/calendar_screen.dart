import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'widgets/add_event_bottom_sheet.dart';

class CalendarScreen extends StatefulWidget {
  final String coupleId;
  const CalendarScreen({super.key, required this.coupleId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Stream<List<EventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsStream = FirestoreService().streamEvents(widget.coupleId);
  }

  int _calculateDaysLeft(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eDate.difference(today).inDays;
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventBottomSheet(coupleId: widget.coupleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('ڕۆژژمێر و بۆنەکان', style: AppTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          final upcomingEvents = events.where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
          upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

          return CustomScrollView(
            slivers: [
              // Countdowns Section
              if (upcomingEvents.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('بۆنە نزیکەکان ⏳', style: AppTheme.titleLarge),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: upcomingEvents.length,
                            itemBuilder: (context, index) {
                              final event = upcomingEvents[index];
                              final daysLeft = _calculateDaysLeft(event.date);
                              
                              return Container(
                                width: 260,
                                margin: const EdgeInsets.only(left: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(event.icon, style: const TextStyle(fontSize: 28)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            event.title,
                                            style: AppTheme.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          daysLeft == 0 ? 'ئەمڕۆیە!' : '$daysLeft',
                                          style: AppTheme.displayLarge.copyWith(color: Colors.white, fontSize: 36, height: 1),
                                        ),
                                        if (daysLeft > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4, right: 8),
                                            child: Text('ڕۆژی ماوە', style: AppTheme.bodyLarge.copyWith(color: Colors.white70)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Calendar Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF33334A)),
                  ),
                  child: TableCalendar<EventModel>(
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: (day) {
                      return events.where((e) => isSameDay(e.date, day)).toList();
                    },
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: AppTheme.onSurface),
                      weekendTextStyle: TextStyle(color: AppTheme.accent),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF33334A),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleTextStyle: AppTheme.titleLarge,
                      formatButtonVisible: false,
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.onSurface),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.onSurface),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: AppTheme.onSurfaceMuted),
                      weekendStyle: TextStyle(color: AppTheme.accent),
                    ),
                  ),
                ),
              ),

              // Selected Day Events
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dayEvents = events.where((e) => isSameDay(e.date, _selectedDay)).toList();
                      if (dayEvents.isEmpty && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text('هیچ بۆنەیەک نییە لەم ڕۆژەدا', style: AppTheme.bodyMedium),
                          ),
                        );
                      }
                      if (index >= dayEvents.length) return null;

                      final event = dayEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(event.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title, style: AppTheme.titleLarge),
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(event.description, style: AppTheme.bodyMedium),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(event.date),
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                              onPressed: () => FirestoreService().deleteEvent(widget.coupleId, event.id),
                            )
                          ],
                        ),
                      );
                    },
                    childCount: events.where((e) => isSameDay(e.date, _selectedDay)).length.clamp(1, 100),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
