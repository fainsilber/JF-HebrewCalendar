import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;


class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var myfonts = null;

  function initialize() {
    WatchFace.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    myfonts = WatchUi.loadResource(Rez.Fonts.frank);
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    myfonts = WatchUi.loadResource(Rez.Fonts.frank);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    // Get and show the current time
    var clockTime = System.getClockTime();
    var h = clockTime.hour + ":" + clockTime.min.format("%02d");
    // var t = "שלום";
    // dc.drawText(
    //   dc.getWidth() / 2,
    //   dc.getHeight(),
    //   myfonts,
    //   t,
    //   Graphics.TEXT_JUSTIFY_CENTER
    // );
    //dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, myfonts, h, Graphics.TEXT_JUSTIFY_CENTER);
    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      dc.getWidth() / 2, // gets the width of the device and divides by 2
      dc.getHeight() / 4, // gets the height of the device and divides by 2
      myfonts,
      "שלום", // the String to display
      Graphics.TEXT_JUSTIFY_CENTER // sets the justification for the text
    );
    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      dc.getWidth() / 2, // gets the width of the device and divides by 2
      dc.getHeight() / 2, // gets the height of the device and divides by 2
      myfonts, // sets the font size
      h, // the String to display
      Graphics.TEXT_JUSTIFY_CENTER // sets the justification for the text
    );

    // var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
    // var view = View.findDrawableById("TimeLabel") as Text;
    // view.setText(timeString);

    // // Call the parent onUpdate function to redraw the layout
    // View.onUpdate(dc);
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {}

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {}

  function getMorningGregorianDate() {
    var now = Time.now();  // current moment
    var g = Gregorian.info(now, Time.FORMAT_SHORT);  // get date info
    return g.year + "-" + g.month.format("%02d") + "-" + g.day.format("%02d");
    //return { year: g.year, month: g.month, day: g.day };
  }

  function isHebrewLeapYear(year) {
    return (((year * 7) + 1) % 19) < 7;
}

function gregorianToAbsolute(year, month, day) {
    // Days in prior years
    var abs = (365 * (year - 1)) +
              ((year - 1) / 4).toNumber().floor() -
              ((year - 1) / 100).toNumber().floor() +
              ((year - 1) / 400).toNumber().floor();
    
    // Days in prior months this year
    var monthLengths = [0, 31, 28, 31, 30, 31, 30,
                        31, 31, 30, 31, 30, 31];
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

function isGregorianLeapYear(year) {
    return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
}


function isHebrewLeapYear(year) {
    return (((year * 7) + 1) % 19) < 7;
}

function lastMonthOfHebrewYear(year) {
    return isHebrewLeapYear(year) ? 13 : 12;
}

// Days from Hebrew epoch to start of given Hebrew year
function hebrewCalendarElapsedDays(year) {
    var months = Math.floor(((235 * Math.floor((year - 1) / 19)) +
              (12 * ((year - 1) % 19)) +
              Math.floor((((year - 1) % 19) * 7 + 1) / 19)));

    var parts = 204 + 793 * (months % 1080);
    var hours = 5 + 12 * months + Math.floor(793 * months / 1080) + Math.floor(parts / 1080);
    parts = parts % 1080;
    var day = 1 + 29 * months + Math.floor(hours / 24);
    hours = hours % 24;

    var altDay = day;

    // Dehiyyot - postponement rules
    if ((hours >= 18) ||
        ((!isHebrewLeapYear(year)) && (hours == 9) && (parts >= 204) && (day % 7 == 2)) ||
        (isHebrewLeapYear(year - 1) && (hours == 15) && (parts >= 589) && (day % 7 == 1))) {
        altDay += 1;
    }

    // If Rosh Hashana would occur on Sunday, Wednesday, or Friday, postpone
    if ([0, 3, 5].indexOf(altDay % 7) >= 0) {
        altDay += 1;
    }

    return altDay;
}

function daysInHebrewYear(year) {
    return hebrewCalendarElapsedDays(year + 1) - hebrewCalendarElapsedDays(year);
}

function daysInHebrewMonth(year, month) {
    if (month == 2 && daysInHebrewYear(year) % 10 != 5) return 29; // Cheshvan short
    if (month == 3 && daysInHebrewYear(year) % 10 == 3) return 29; // Kislev short
    if (month == 12 && !isHebrewLeapYear(year)) return 29; // Adar short in non-leap
    if (month == 13) return 29; // Adar II short
    return 30;
}

function absoluteToHebrew(absDay) {
    var approx = Math.floor((absDay - 2067025) / 365.246822206) + 1; // rough year guess
    var year = approx;

    // Find actual Hebrew year
    while (absDay >= gregorianToAbsolute(hebrewYearStartGregorian(year + 1).year,
                                         hebrewYearStartGregorian(year + 1).month,
                                         hebrewYearStartGregorian(year + 1).day)) {
        year += 1;
    }
    while (absDay < gregorianToAbsolute(hebrewYearStartGregorian(year).year,
                                        hebrewYearStartGregorian(year).month,
                                        hebrewYearStartGregorian(year).day)) {
        year -= 1;
    }

    // Days since Rosh Hashana
    var startOfYearAbs = hebrewCalendarElapsedDays(year) + 1373429; // Hebrew epoch offset
    var dayOfYear = absDay - startOfYearAbs + 1;

    // Find month/day
    var month = 1;
    while (dayOfYear > daysInHebrewMonth(year, month)) {
        dayOfYear -= daysInHebrewMonth(year, month);
        month += 1;
    }
    return [year, month, day];

    //return { year: year, month: month, day: dayOfYear };
}


function getHebrewDateThisMorning() {
    var gd = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var abs = gregorianToAbsolute(gd.year, gd.month, gd.day);
    var hd = absoluteToHebrew(abs);
    return hd;  // {year—with Hebrew year, month, day}
}
}
