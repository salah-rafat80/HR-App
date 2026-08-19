class LeaveErrorMapper {
  static String mapError(String errorString) {
    final clean = errorString.toUpperCase();

    if (clean.contains('POLICY_NOT_FOUND_OR_INACTIVE')) {
      return '╪│┘è╪º╪│╪⌐ ╪º┘ä╪Ñ╪¼╪º╪▓╪⌐ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»╪⌐ ╪ú┘ê ╪║┘è╪▒ ┘å╪┤╪╖╪⌐ ╪¡╪º┘ä┘è╪º┘ï.';
    }
    if (clean.contains('START_DATE_BEFORE_TODAY')) {
      return '╪¬╪º╪▒┘è╪« ╪¿╪»╪í ╪º┘ä╪Ñ╪¼╪º╪▓╪⌐ ┘ä╪º ┘è┘à┘â┘å ╪ú┘å ┘è┘â┘ê┘å ┘ü┘è ╪º┘ä┘à╪º╪╢┘è.';
    }
    if (clean.contains('MINIMUM_NOTICE_NOT_MET')) {
      return '┘ä┘à ┘è╪¬┘à ╪º╪│╪¬┘è┘ü╪º╪í ╪º┘ä╪¡╪» ╪º┘ä╪ú╪»┘å┘ë ┘ä╪ú┘è╪º┘à ╪º┘ä╪Ñ╪┤╪╣╪º╪▒ ╪º┘ä┘à╪│╪¿┘é ╪º┘ä┘à╪╖┘ä┘ê╪¿╪⌐ ┘ä┘ç╪░┘ç ╪º┘ä╪Ñ╪¼╪º╪▓╪⌐.';
    }
    if (clean.contains('REASON_REQUIRED')) {
      return '╪│╪¿╪¿ ╪º┘ä╪Ñ╪¼╪º╪▓╪⌐ ┘à╪╖┘ä┘ê╪¿ ┘ê┘ä╪º ┘è┘à┘â┘å ╪¬╪▒┘â┘ç ┘ü╪º╪▒╪║╪º┘ï.';
    }
    if (clean.contains('HALFDAY_NOT_ALLOWED')) {
      return '╪Ñ╪¼╪º╪▓╪⌐ ┘å╪╡┘ü ╪º┘ä┘è┘ê┘à ╪║┘è╪▒ ┘à╪│┘à┘ê╪¡ ╪¿┘ç╪º ┘ä┘ç╪░╪º ╪º┘ä┘å┘ê╪╣ ┘à┘å ╪º┘ä╪Ñ╪¼╪º╪▓╪º╪¬.';
    }
    if (clean.contains('HALFDAY_MUST_SPAN_ONE_DAY')) {
      return '╪╖┘ä╪¿ ┘å╪╡┘ü ┘è┘ê┘à ┘è╪¼╪¿ ╪ú┘å ┘è╪¿╪»╪ú ┘ê┘è┘å╪¬┘ç┘è ┘ü┘è ┘å┘ü╪│ ╪º┘ä╪¬╪º╪▒┘è╪«.';
    }
    if (clean.contains('HALFDAY_PERIOD_REQUIRED')) {
      return '┘è╪▒╪¼┘ë ╪¬╪¡╪»┘è╪» ╪º┘ä┘ü╪¬╪▒╪⌐ ╪º┘ä┘à╪╖┘ä┘ê╪¿╪⌐ ┘ä┘å╪╡┘ü ╪º┘ä┘è┘ê┘à (╪╡╪¿╪º╪¡┘è╪⌐/┘à╪│╪º╪ª┘è╪⌐).';
    }
    if (clean.contains('NO_WORKING_DAYS_IN_RANGE')) {
      return '╪º┘ä┘å╪╖╪º┘é ╪º┘ä┘à╪¡╪»╪» ┘è╪¡╪¬┘ê┘è ╪╣┘ä┘ë ╪╣╪╖┘ä╪º╪¬ ╪▒╪│┘à┘è╪⌐ ╪ú┘ê ╪ú╪│╪¿┘ê╪╣┘è╪⌐ ┘ü┘é╪╖.';
    }
    if (clean.contains('LEAVE_OVERLAP')) {
      return '╪¬┘ê╪¼╪» ╪Ñ╪¼╪º╪▓╪⌐ ╪ú╪«╪▒┘ë ┘à╪╣┘ä┘é╪⌐ ╪ú┘ê ┘à╪╣╪¬┘à╪»╪⌐ ┘à╪¬╪»╪º╪«┘ä╪⌐ ┘à╪╣ ┘ç╪░┘ç ╪º┘ä╪¬┘ê╪º╪▒┘è╪«.';
    }
    if (clean.contains('ATTENDANCE_CONFLICT')) {
      return '┘è┘ê╪¼╪» ╪│╪¼┘ä ╪¡╪╢┘ê╪▒ ┘à╪│╪¼┘ä ╪¿╪º┘ä┘ü╪╣┘ä ┘ü┘è ╪ú╪¡╪» ╪ú┘è╪º┘à ╪º┘ä╪╣┘à┘ä ╪º┘ä┘à╪¡╪»╪»╪⌐.';
    }
    if (clean.contains('LEAVE_BALANCE_NOT_FOUND')) {
      return '┘ä╪º ┘è┘ê╪¼╪» ╪▒╪╡┘è╪» ╪Ñ╪¼╪º╪▓╪º╪¬ ┘à┘ç┘è╪ú ┘ä┘ç╪░╪º ╪º┘ä┘à╪│╪¬╪«╪»┘à ┘ä┘ç╪░╪º ╪º┘ä╪╣╪º┘à.';
    }
    if (clean.contains('INSUFFICIENT_LEAVE_BALANCE')) {
      return '╪▒╪╡┘è╪» ╪º┘ä╪Ñ╪¼╪º╪▓╪º╪¬ ╪º┘ä┘à╪¬╪º╪¡ ╪║┘è╪▒ ┘â╪º┘ü┘ì ┘ä╪Ñ╪¬┘à╪º┘à ╪º┘ä╪╖┘ä╪¿.';
    }
    if (clean.contains('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED')) {
      return '╪│┘ä╪│┘ä╪⌐ ╪º┘ä┘à┘ê╪º┘ü┘é╪º╪¬ ╪║┘è╪▒ ┘à┘ç┘è╪ú╪⌐ (┘è╪▒╪¼┘ë ╪º┘ä╪¬╪ú┘â╪» ┘à┘å ╪¬╪╣┘è┘è┘å ╪º┘ä┘à╪»┘è╪▒ ╪º┘ä┘à╪¿╪º╪┤╪▒╪î ┘à╪»┘è╪▒ ╪º┘ä╪Ñ╪»╪º╪▒╪⌐╪î ┘ê╪¬╪╣┘è┘è┘å ┘à╪│╪ñ┘ê┘ä HR ╪º┘ä┘à╪╣╪¬┘à╪» ┘ä┘ä╪┤╪▒┘â╪⌐).';
    }
    if (clean.contains('APPROVED_LEAVE_ACTIVE')) {
      return '┘ä╪º ┘è┘à┘â┘å┘â ╪¬╪│╪¼┘è┘ä ╪º┘ä╪¡╪╢┘ê╪▒ ╪º┘ä┘è┘ê┘à ┘å╪╕╪▒╪º┘ï ┘ä┘ê╪¼┘ê╪» ╪Ñ╪¼╪º╪▓╪⌐ ┘à╪╣╪¬┘à╪»╪⌐ ┘ê┘å╪┤╪╖╪⌐.';
    }
    if (clean.contains('REJECTION_REASON_REQUIRED')) {
      return '╪│╪¿╪¿ ╪º┘ä╪▒┘ü╪╢ ┘à╪╖┘ä┘ê╪¿ ┘ê╪Ñ┘ä╪▓╪º┘à┘è ┘ä╪Ñ╪¬┘à╪º┘à ╪º┘ä╪╣┘à┘ä┘è╪⌐.';
    }
    if (clean.contains('INVALID_BALANCE_STATE') || clean.contains('INVALID_BALANCE')) {
      return '┘ü╪┤┘ä╪¬ ╪º┘ä╪╣┘à┘ä┘è╪⌐: ╪│╪¬╪ñ╪»┘è ╪Ñ┘ä┘ë ╪¡╪º┘ä╪⌐ ╪▒╪╡┘è╪» ╪║┘è╪▒ ╪╡╪º┘ä╪¡╪⌐ ╪ú┘ê ╪▒╪╡┘è╪» ╪│╪º┘ä╪¿.';
    }

    return errorString;
  }
}
