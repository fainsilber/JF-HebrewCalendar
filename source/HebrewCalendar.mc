import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Hebrew Calendar calculation utilities
class HebrewCalendar {

    // --- Integer helpers (force to Long first) ---
    
    // Safely converts a number to Long to avoid overflow issues
    static function toLongSafe(n as Number) as Number {
        return n;
    }

    // Floor division for non-negative integers using integer arithmetic
    static function divFloor(a as Number, b as Number) as Number {
        var ai = toLongSafe(a);
        var bi = toLongSafe(b);
        // Guard b > 0 in our usage
        // a, b >= 0 in our use here
        var c = ai % bi;
        var res = (ai - c) / bi;
        return res;
    }

    // --- Hebrew Calendar Year Functions ---
    
    // Determines if a given Hebrew year is a leap year
    static function isHebrewLeapYear(year as Number) as Boolean {
        return (year * 7 + 1) % 19 < 7;
    }

    // Returns the last month number of a Hebrew year (12 or 13 for leap years)
    static function lastMonthOfHebrewYear(year as Number) as Number {
        return isHebrewLeapYear(year) ? 13 : 12;
    }

    // Calculates months elapsed before the given Hebrew year
    static function monthsElapsedBeforeHebrewYear(year as Number) as Number {
        var y = year - 1; // years completed before 'year'
        var cycles = divFloor(y, 19); // number of full 19-year cycles
        var yc = toLongSafe(y) % 19; // year-in-cycle (0..18)

        // months = 235*cycles + 12*yc + floor((7*yc + 1)/19)
        return 235 * cycles + 12 * yc + divFloor(7 * yc + 1, 19);
    }

    // Calculates days from Hebrew epoch to start of given Hebrew year
    static function hebrewCalendarElapsedDays(year as Number) as Number {
        var months = monthsElapsedBeforeHebrewYear(year);

        var parts = 204 + 793 * (months % 1080);
        var hours = 5 + 12 * months + Math.floor((793 * months) / 1080) + Math.floor(parts / 1080);
        parts = parts % 1080;
        var day = 1 + 29 * months + Math.floor(hours / 24);
        hours = hours % 24;

        var altDay = day;

        // Dehiyyot - postponement rules
        if (hours >= 18 ||
            (!isHebrewLeapYear(year) && hours == 9 && parts >= 204 && day % 7 == 2) ||
            (isHebrewLeapYear(year - 1) && hours == 15 && parts >= 589 && day % 7 == 1)) {
            altDay += 1;
        }

        // If Rosh Hashana would occur on Sunday, Wednesday, or Friday, postpone
        if ([0, 3, 5].indexOf(altDay % 7) >= 0) {
            altDay += 1;
        }

        return altDay;
    }

    // Calculates the number of days in a given Hebrew year
    static function daysInHebrewYear(year as Number) as Number {
        return hebrewCalendarElapsedDays(year + 1) - hebrewCalendarElapsedDays(year);
    }

    // Calculates the number of days in a given Hebrew month and year
    static function daysInHebrewMonth(year as Number, month as Number) as Number {
        if (month == 2 && daysInHebrewYear(year) % 10 != 5) {
            return 29; // Cheshvan short
        }
        if (month == 3 && daysInHebrewYear(year) % 10 == 3) {
            return 29; // Kislev short
        }
        if (month == 12 && !isHebrewLeapYear(year)) {
            return 29; // Adar short in non-leap
        }
        if (month == 13) {
            return 29; // Adar II short
        }
        return 30;
    }

    // --- Gregorian Calendar Functions ---
    
    // Determines if a Gregorian year is a leap year
    static function isGregorianLeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    }

    // Converts a Gregorian date to absolute day number
    static function gregorianToAbsolute(year as Number, month as Number, day as Number) as Number {
        // Days in prior years
        var abs = 365 * (year - 1) + 
                 Math.floor((year - 1) / 4) - 
                 Math.floor((year - 1) / 100) + 
                 Math.floor((year - 1) / 400);

        // Days in prior months this year
        var monthLengths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (isGregorianLeapYear(year)) {
            monthLengths[2] = 29;
        }
        for (var m = 1; m < month; m += 1) {
            abs += monthLengths[m];
        }

        // Add days this month
        abs += day;

        return abs;
    }

    // --- Conversion Functions ---
    
    // Converts absolute day number to Hebrew date [year, month, day]
    static function absoluteToHebrew(absDay as Number) as Array<Number> {
        var HEBREW_EPOCH = -1373429; // days between Hebrew epoch and 1 Jan 1 CE
        var approxFloat = (absDay - HEBREW_EPOCH) / 365.246822206 + 1; // rough year guess
        var year = Math.floor(approxFloat).toNumber();

        // Find the start of the Hebrew year this gregorian year
        var startOfHebrewYearThisGregorianYear = hebrewYearStartGregorian(year);
        var startOfHebrewYearNextGregorianYear = hebrewYearStartGregorian(year + 1);
        var absGregorianNextYear = gregorianToAbsolute(
            startOfHebrewYearNextGregorianYear[0],
            startOfHebrewYearNextGregorianYear[1],
            startOfHebrewYearNextGregorianYear[2]
        );
        var absGregorianThisYear = gregorianToAbsolute(
            startOfHebrewYearThisGregorianYear[0],
            startOfHebrewYearThisGregorianYear[1],
            startOfHebrewYearThisGregorianYear[2]
        );

        // Find actual Hebrew year
        while (absDay >= absGregorianNextYear) {
            year += 1;
            startOfHebrewYearThisGregorianYear = startOfHebrewYearNextGregorianYear;
            startOfHebrewYearNextGregorianYear = hebrewYearStartGregorian(year + 1);
            absGregorianThisYear = absGregorianNextYear;
            absGregorianNextYear = gregorianToAbsolute(
                startOfHebrewYearNextGregorianYear[0],
                startOfHebrewYearNextGregorianYear[1],
                startOfHebrewYearNextGregorianYear[2]
            );
        }
        while (absDay < absGregorianThisYear) {
            year -= 1;
            startOfHebrewYearNextGregorianYear = startOfHebrewYearThisGregorianYear;
            startOfHebrewYearThisGregorianYear = hebrewYearStartGregorian(year);
            absGregorianNextYear = absGregorianThisYear;
            absGregorianThisYear = gregorianToAbsolute(
                startOfHebrewYearThisGregorianYear[0],
                startOfHebrewYearThisGregorianYear[1],
                startOfHebrewYearThisGregorianYear[2]
            );
        }

        // Days since Rosh Hashana
        var startOfYearAbs = hebrewCalendarElapsedDays(year) - 1373429; // Hebrew epoch offset
        var dayOfYear = absDay - startOfYearAbs + 1;

        // Find month/day
        var month = 1;
        while (dayOfYear > daysInHebrewMonth(year, month)) {
            dayOfYear -= daysInHebrewMonth(year, month);
            month += 1;
        }
        
        return [year, month, dayOfYear];
    }

    // Returns the Gregorian date [year, month, day] for the start of a given Hebrew year
    static function hebrewYearStartGregorian(hebrewYear as Number) as Array<Number> {
        // The Hebrew epoch is absolute day 1373429 (Monday, October 7, 3761 BCE Gregorian)
        var HEBREW_EPOCH_ABS = -1373429; // Hebrew epoch relative to your Gregorian abs system
        var abs = hebrewCalendarElapsedDays(hebrewYear) + HEBREW_EPOCH_ABS;

        // Now convert absolute day to Gregorian date
        var gregorianYear = 1;
        
        // Estimate Gregorian year
        var approxYear = (abs - 1) / 365.2425 + 1;
        gregorianYear = Math.floor(approxYear).toNumber();
        
        // Find the correct Gregorian year
        while (gregorianToAbsolute(gregorianYear + 1, 1, 1) <= abs) {
            gregorianYear += 1;
        }
        while (gregorianToAbsolute(gregorianYear, 1, 1) > abs) {
            gregorianYear -= 1;
        }
        
        // Find month and day
        var month = 1;
        while (gregorianToAbsolute(gregorianYear, month + 1, 1) <= abs) {
            month += 1;
        }
        var day = abs - gregorianToAbsolute(gregorianYear, month, 1) + 1;
        
        return [gregorianYear, month, day];
    }

    // --- Public API Functions ---
    
    // Gets the current Hebrew date [year, month, day]
    static function getHebrewDateThisMorning() as Array<Number> {
        var gd = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var abs = gregorianToAbsolute(
            toLongSafe(gd.year),
            toLongSafe(gd.month),
            toLongSafe(gd.day)
        );
        var hd = absoluteToHebrew(abs);
        return hd;
    }

    // Converts a Gregorian date to Hebrew date [year, month, day]
    static function gregorianToHebrew(year as Number, month as Number, day as Number) as Array<Number> {
        var abs = gregorianToAbsolute(year, month, day);
        return absoluteToHebrew(abs);
    }

    // Gets the Hebrew date for a specific Gregorian date
    static function getHebrewDate(gregorianInfo as Gregorian.Info) as Array<Number> {
        var abs = gregorianToAbsolute(
            toLongSafe(gregorianInfo.year),
            toLongSafe(gregorianInfo.month),
            toLongSafe(gregorianInfo.day)
        );
        return absoluteToHebrew(abs);
    }

    // --- Hebrew Calendar Display Functions ---
    
    // Returns Hebrew month names
    static function getHebrewMonthName(month as Number, isLeapYear as Boolean) as String {
        var monthNames = [
            "", // index 0 unused
            "תשרי",    // 1 - Tishrei
            "חשון",    // 2 - Cheshvan  
            "כסלו",    // 3 - Kislev
            "טבת",     // 4 - Tevet
            "שבט",     // 5 - Shevat
            "אדר",     // 6 - Adar (or Adar I in leap year)
            "ניסן",    // 7 - Nisan
            "אייר",    // 8 - Iyar
            "סיון",    // 9 - Sivan
            "תמוז",    // 10 - Tamuz
            "אב",      // 11 - Av
            "אלול"     // 12 - Elul
        ];
        
        if (month <= 12) {
            if (month == 6 && isLeapYear) {
                return "אדר א"; // Adar I
            }
            return monthNames[month];
        } else if (month == 13 && isLeapYear) {
            return "אדר ב"; // Adar II
        }
        
        return "";
    }
    
    // Formats Hebrew date as a string
    static function formatHebrewDate(hebrewDate as Array<Number>) as String {
        var year = hebrewDate[0];
        var month = hebrewDate[1];
        var day = hebrewDate[2];
        var isLeap = isHebrewLeapYear(year);
        var monthName = getHebrewMonthName(month, isLeap);
        
        return day + " " + monthName + " " + year;
    }
    
    // Gets formatted current Hebrew date
    static function getFormattedHebrewDate() as String {
        var hebrewDate = getHebrewDateThisMorning();
        return formatHebrewDate(hebrewDate);
    }
}
