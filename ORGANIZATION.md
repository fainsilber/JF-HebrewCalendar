# Hebrew Calendar Project Organization

## Overview
This project has been reorganized to better separate concerns and improve maintainability. All Hebrew calendar calculation functions have been moved to a dedicated module.

## File Structure

### `/source/HebrewCalendar.mc`
**Purpose**: Contains all Hebrew calendar calculation functions and utilities.

**Key Functions**:
- `getHebrewDateThisMorning()` - Gets current Hebrew date [year, month, day]
- `getFormattedHebrewDate()` - Gets current Hebrew date as formatted string
- `formatHebrewDate(hebrewDate)` - Formats Hebrew date array as string  
- `gregorianToHebrew(year, month, day)` - Converts Gregorian to Hebrew date
- `getHebrewDate(gregorianInfo)` - Converts Gregorian.Info to Hebrew date
- `getHebrewMonthName(month, isLeapYear)` - Gets Hebrew month name
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
// Returns: "17 אב 5785" (example)

// Get current Hebrew date as array
var hebrewDate = HebrewCalendar.getHebrewDateThisMorning();
var year = hebrewDate[0];   // 5785
var month = hebrewDate[1];  // 11 (Av)
var day = hebrewDate[2];    // 17

// Convert specific Gregorian date
var hebrewDate2 = HebrewCalendar.gregorianToHebrew(2025, 8, 17);

// Check if Hebrew year is leap year
var isLeap = HebrewCalendar.isHebrewLeapYear(5785);

// Get Hebrew month name
var monthName = HebrewCalendar.getHebrewMonthName(11, false); // "אב"

// Format custom Hebrew date
var customDate = [5785, 11, 17];
var formatted = HebrewCalendar.formatHebrewDate(customDate); // "17 אב 5785"
```

## Future Enhancements

The HebrewCalendar module can be easily extended with additional features:
- Hebrew month names
- Holiday calculations  
- Day of week in Hebrew
- Hebrew date formatting
- Zmanim (prayer times) calculations
