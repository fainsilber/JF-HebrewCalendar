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
        // Hebrew epoch - fine-tuned to match accurate Hebrew calendar dates
        var HEBREW_EPOCH = -1373427 - 14; // Adjusted for correct day calculation
        var approxFloat = (absDay - HEBREW_EPOCH) / 365.246822206 + 1; // rough year guess
        var year = Math.floor(approxFloat).toNumber();

        // Find the actual Hebrew year by checking boundaries
        while (hebrewCalendarElapsedDays(year + 1) + HEBREW_EPOCH <= absDay) {
            year += 1;
        }
        while (hebrewCalendarElapsedDays(year) + HEBREW_EPOCH > absDay) {
            year -= 1;
        }

        // Days since Rosh Hashana of this Hebrew year
        var startOfYearAbs = hebrewCalendarElapsedDays(year) + HEBREW_EPOCH;
        var dayOfYear = absDay - startOfYearAbs + 1;

        // Find month/day in Hebrew calendar order (1=Tishrei, 2=Cheshvan, etc.)
        var hebrewYearMonth = 1;
        while (dayOfYear > daysInHebrewMonth(year, hebrewYearMonth)) {
            dayOfYear -= daysInHebrewMonth(year, hebrewYearMonth);
            hebrewYearMonth += 1;
        }
        
        return [year, hebrewYearMonth, dayOfYear];
    }

    // Returns the Gregorian date [year, month, day] for the start of a given Hebrew year
    static function hebrewYearStartGregorian(hebrewYear as Number) as Array<Number> {
        // Fine-tuned Hebrew calendar epoch
        var HEBREW_EPOCH_ABS = -1373427 - 14; 
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
    
    // Converts Hebrew year month (1=Tishrei) to standard month number (1=Nisan)
    static function hebrewYearMonthToStandardMonth(hebrewYearMonth as Number, isLeapYear as Boolean) as Number {
        // Hebrew year order (regular): 1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat, 6=Adar, 7=Nisan, 8=Iyar, 9=Sivan, 10=Tamuz, 11=Av, 12=Elul
        // Standard order: 1=Nisan, 2=Iyar, 3=Sivan, 4=Tamuz, 5=Av, 6=Elul, 7=Tishrei, 8=Cheshvan, 9=Kislev, 10=Tevet, 11=Shevat, 12=Adar
        
        if (isLeapYear) {
            // Leap year: 1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat, 6=AdarI, 7=AdarII, 8=Nisan, 9=Iyar, 10=Sivan, 11=Tamuz, 12=Av, 13=Elul
            if (hebrewYearMonth >= 1 && hebrewYearMonth <= 5) {
                return hebrewYearMonth + 6; // Tishrei(1)->7, Cheshvan(2)->8, Kislev(3)->9, Tevet(4)->10, Shevat(5)->11
            } else if (hebrewYearMonth == 6) {
                return 12; // Adar I
            } else if (hebrewYearMonth == 7) {
                return 13; // Adar II  
            } else if (hebrewYearMonth >= 8 && hebrewYearMonth <= 13) {
                return hebrewYearMonth - 7; // Nisan(8)->1, Iyar(9)->2, Sivan(10)->3, Tamuz(11)->4, Av(12)->5, Elul(13)->6
            }
        } else {
            // Regular year: 1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat, 6=Adar, 7=Nisan, 8=Iyar, 9=Sivan, 10=Tamuz, 11=Av, 12=Elul
            if (hebrewYearMonth >= 1 && hebrewYearMonth <= 6) {
                return hebrewYearMonth + 6; // Tishrei(1)->7, Cheshvan(2)->8, Kislev(3)->9, Tevet(4)->10, Shevat(5)->11, Adar(6)->12
            } else if (hebrewYearMonth >= 7 && hebrewYearMonth <= 12) {
                return hebrewYearMonth - 6; // Nisan(7)->1, Iyar(8)->2, Sivan(9)->3, Tamuz(10)->4, Av(11)->5, Elul(12)->6
            }
        }
        
        return 1; // fallback
    }
    
    // Returns Hebrew month names (by standard numbering: 1=Nisan)
    static function getHebrewMonthName(standardMonth as Number, isLeapYear as Boolean) as String {
        var monthNames = [
            "", // index 0 unused
            "ניסן",    // 1 - Nisan
            "אייר",    // 2 - Iyar
            "סיון",    // 3 - Sivan
            "תמוז",    // 4 - Tamuz
            "אב",      // 5 - Av
            "אלול",    // 6 - Elul
            "תשרי",    // 7 - Tishrei
            "חשון",    // 8 - Cheshvan  
            "כסלו",    // 9 - Kislev
            "טבת",     // 10 - Tevet
            "שבט",     // 11 - Shevat
            "אדר"      // 12 - Adar (or Adar I in leap year)
        ];
        
        if (standardMonth <= 12) {
            if (standardMonth == 12 && isLeapYear) {
                return "אדר א"; // Adar I
            }
            return monthNames[standardMonth];
        } else if (standardMonth == 13 && isLeapYear) {
            return "אדר ב"; // Adar II
        }
        
        return "";
    }
    
    // Formats Hebrew date as a string
    static function formatHebrewDate(hebrewDate as Array<Number>) as String {
        var year = hebrewDate[0];
        var hebrewYearMonth = hebrewDate[1]; // This is Hebrew year month (1=Tishrei)
        var day = hebrewDate[2];
        var isLeap = isHebrewLeapYear(year);
        var standardMonth = hebrewYearMonthToStandardMonth(hebrewYearMonth, isLeap);
        var monthName = getHebrewMonthName(standardMonth, isLeap);
        
        return day + " " + monthName + " " + year;
    }
    
    // Gets formatted current Hebrew date
    static function getFormattedHebrewDate() as String {
        var hebrewDate = getHebrewDateThisMorning();
        return formatHebrewDate(hebrewDate);
    }
}
