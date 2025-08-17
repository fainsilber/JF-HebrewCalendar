# Hebrew Calendar Project Organization

## Overview
This project has been reorganized to better separate concerns and improve maintainability. All Hebrew calendar calculation functions have been moved to a dedicated module.

## File Structure

### `/source/HebrewCalendar.mc`
**Purpose**: Contains all Hebrew calendar calculation functions and utilities.

**Key Functions**:
- `getHebrewDateThisMorning()` - Gets current Hebrew date [year, hebrewYearMonth, day]
- `getFormattedHebrewDate()` - Gets current Hebrew date as formatted string
- `formatHebrewDate(hebrewDate)` - Formats Hebrew date array as string  
- `gregorianToHebrew(year, month, day)` - Converts Gregorian to Hebrew date
- `getHebrewDate(gregorianInfo)` - Converts Gregorian.Info to Hebrew date
- `getHebrewMonthName(standardMonth, isLeapYear)` - Gets Hebrew month name (1=Nisan)
- `hebrewYearMonthToStandardMonth(hebrewYearMonth, isLeapYear)` - Converts Hebrew year month to standard numbering
- `isHebrewLeapYear(year)` - Checks if Hebrew year is leap year
- `daysInHebrewYear(year)` - Gets days in Hebrew year
- `daysInHebrewMonth(year, month)` - Gets days in Hebrew month
- `hebrewYearStartGregorian(hebrewYear)` - Gets Gregorian date for Hebrew New Year

**Internal Helper Functions**:
- `toLongSafe()` - Safe number conversion
- `divFloor()` - Integer floor division
- `isGregorianLeapYear()` - Gregorian leap year check
- `gregorianToAbsolute()` - Converts Gregorian to absolute day number
- `absoluteToHebrew()` - Converts absolute day number to Hebrew date
- `hebrewCalendarElapsedDays()` - Days from Hebrew epoch to year start
- `monthsElapsedBeforeHebrewYear()` - Months before Hebrew year

### `/source/JF-HebrewCalendarView.mc`
**Purpose**: Contains only UI/display logic for the watch face.

**Key Functions**:
- `onUpdate()` - Main display update function
- `onLayout()` - Layout initialization
- UI event handlers (`onShow`, `onHide`, `onEnterSleep`, `onExitSleep`)

## Benefits of This Organization

1. **Separation of Concerns**: Calendar calculations are separate from UI logic
2. **Reusability**: Hebrew calendar functions can be reused in other parts of the project
3. **Maintainability**: Easier to test and modify calendar logic
4. **Readability**: Each file has a clear, focused purpose
5. **Modularity**: The HebrewCalendar class can be easily extended or replaced

## Usage Example

```monkeyc
// Get current Hebrew date as formatted string  
var hebrewDateString = HebrewCalendar.getFormattedHebrewDate();
// Returns: "23 אב 5785" (for August 17, 2025)

// Get current Hebrew date as array
var hebrewDate = HebrewCalendar.getHebrewDateThisMorning();
var year = hebrewDate[0];         // 5785
var hebrewYearMonth = hebrewDate[1]; // 12 (12th month in Hebrew year = Av)
var day = hebrewDate[2];          // 23

// Convert Hebrew year month to standard month (1=Nisan)
var isLeap = HebrewCalendar.isHebrewLeapYear(year);
var standardMonth = HebrewCalendar.hebrewYearMonthToStandardMonth(hebrewYearMonth, isLeap); // 5 (Av)

// Convert specific Gregorian date
var hebrewDate2 = HebrewCalendar.gregorianToHebrew(2025, 8, 17); // [5785, 12, 23]

// Get Hebrew month name by standard numbering
var monthName = HebrewCalendar.getHebrewMonthName(5, false); // "אב" (Av)

// Format custom Hebrew date
var customDate = [5785, 12, 23]; // Year, Hebrew year month, day
var formatted = HebrewCalendar.formatHebrewDate(customDate); // "23 אב 5785"
```

## Important Notes

**Month Numbering**: The Hebrew calendar uses two different month numbering systems:
1. **Hebrew Year Months** (returned by calculation functions): 1=Tishrei, 2=Cheshvan, ..., 12=Av (or 13=Elul in leap years)
2. **Standard Months** (used for display): 1=Nisan, 2=Iyar, ..., 5=Av, ..., 12=Adar (13=Adar II in leap years)

The conversion between these is handled automatically by the formatting functions.

## Future Enhancements

The HebrewCalendar module can be easily extended with additional features:
- Hebrew month names
- Holiday calculations  
- Day of week in Hebrew
- Hebrew date formatting
- Zmanim (prayer times) calculations
