import 'dart:ui';

import 'package:flutter_bootstrap/i18n/i18n.dart';
import 'package:intl/intl.dart';

abstract class DefaultI18nDates implements I18nDelegate {
  /// Intl DateFormats
  late final DateFormat _longDate;
  late final DateFormat _shortDate;
  late final DateFormat _longFullMonth;
  late final DateFormat _timeFormat;
  late final DateFormat _dayOnlyFormat;


  void initializeDates(Locale locale) {
    _longDate = DateFormat.yMMMd(locale.languageCode);
    _shortDate = DateFormat.yMd(locale.languageCode);
    _timeFormat = DateFormat.Hm(locale.languageCode);
    _longFullMonth = DateFormat.MMMMd(locale.languageCode);
    _dayOnlyFormat = DateFormat.EEEE(locale.languageCode);
  }

  @override
  String dateLongFullMonth(DateTime time) => _longFullMonth.format(time);

  @override
  String dateLong(DateTime time) => _longDate.format(time);

  @override
  String dateShort(DateTime time) => _shortDate.format(time);

  @override
  String timeFormat(DateTime time) => _timeFormat.format(time);

  @override
  String dayOfWeekFormat(DateTime time) => _dayOnlyFormat.format(time);

}