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
        
        // Expected: 23 Av 5785 (Hebrew year month 12, standard month 5)
    }
}
