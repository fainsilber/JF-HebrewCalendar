import Toybox.Lang;
import Toybox.Math;

// Quick test for Hebrew calendar calculation
using Toybox.System as System;

class HebrewCalendarTest {
    static function testTodaysDate() as Void {
        // August 17, 2025
        var abs = HebrewCalendar.gregorianToAbsolute(2025, 8, 17);
        System.println("Absolute day for Aug 17, 2025: " + abs);
        
        var hebrewDate = HebrewCalendar.absoluteToHebrew(abs);
        System.println("Hebrew date array: [" + hebrewDate[0] + ", " + hebrewDate[1] + ", " + hebrewDate[2] + "]");
        
        var formatted = HebrewCalendar.formatHebrewDate(hebrewDate);
        System.println("Formatted: " + formatted);
        
        // Expected: 23 Av 5785 (Hebrew year month 11, standard month 5)
    }

    static function testIsChag() as Void {
        // 16 September 2023 - Rosh Hashana (1 Tishrei 5784)
        var absRh = HebrewCalendar.gregorianToAbsolute(2023, 9, 16);
        var hdRh = HebrewCalendar.absoluteToHebrew(absRh);
        System.println("Rosh Hashana 5784 day 1 is chag: " + HebrewCalendar.isChagForDate(hdRh));

        // 18 September 2023 - 3 Tishrei 5784 (no chag)
        var absChol = HebrewCalendar.gregorianToAbsolute(2023, 9, 18);
        var hdChol = HebrewCalendar.absoluteToHebrew(absChol);
        System.println("18 Sep 2023 is chag: " + HebrewCalendar.isChagForDate(hdChol));
    }
}
