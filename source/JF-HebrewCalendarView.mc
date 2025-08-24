import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Math;

class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var iconFont = null;
  var frankFont = null;
  var stepsIcon = null;
  var sunCalc = null;

  function initialize() {
    WatchFace.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    iconFont = WatchUi.loadResource(Rez.Fonts.icons);
    frankFont = WatchUi.loadResource(Rez.Fonts.frank);
    stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
    sunCalc = new SunCalc();
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  function onPartialUpdate(dc) {
    var clockTime = System.getClockTime();
    var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);
    (View.findDrawableById("SecondsLabel") as Text).setText(secStr);
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var clockTime = System.getClockTime();
    var timeStr = Lang.format("$1$:$2$", [
      clockTime.hour.format("%02d"),
      clockTime.min.format("%02d"),
    ]);
    var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);

    var gInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var gDate = Lang.format("$1$/$2$/$3$", [
      gInfo.day.format("%02d"),
      gInfo.month.format("%02d"),
      gInfo.year,
    ]);

    var actInfo = ActivityMonitor.getInfo();
    var stepsNum = actInfo != null ? actInfo.steps : 0;
    var steps = Lang.format("$1$ ", [stepsNum, ""]);

    var nextLabel = "";
    var hDate = "hb";
    var holyday = "";
    var iconStr = "0 ";
    var posInfo = Position.getInfo();
    if (posInfo != null) {
      var posInRadians = posInfo.position.toRadians();
      var lat = posInRadians[0];
      var lon = posInRadians[1];
      var now = Time.now();
      var sunrise = sunCalc.calculate(now, lat, lon, SUNRISE);
      var sunset = sunCalc.calculate(now, lat, lon, SUNSET);
      now = Time.Gregorian.info(now, Time.FORMAT_SHORT);
      var sunRiseTime = Time.Gregorian.info(sunrise, Time.FORMAT_LONG);
      var sunSetTime = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      // afterSunrise is true when current time is equal or later than sunrise
      var afterSunrise =
        now.hour > sunRiseTime.hour ||
        (now.hour == sunRiseTime.hour && now.min >= sunRiseTime.min);
      // beforeSunset is true when current time is earlier or equal than sunset
      var beforeSunset =
        now.hour < sunSetTime.hour ||
        (now.hour == sunSetTime.hour && now.min <= sunSetTime.min);
      // If we're before sunrise, the next event is sunrise; otherwise if we're before sunset, it's sunset
      if (sunrise != null && !afterSunrise) {
        iconStr = "0?";
        nextLabel = Lang.format("   $1$:$2$", [
          sunRiseTime.hour.format("%02d"),
          sunRiseTime.min.format("%02d"),
        ]);
      } else if (sunset != null && beforeSunset) {
        iconStr = "0>";
        nextLabel = Lang.format("   $1$:$2$", [
          sunSetTime.hour.format("%02d"),
          sunSetTime.min.format("%02d"),
        ]);
      } else {
        var today = Time.now();
        var oneDay = new Time.Duration(86400);
        var tomorrow = today.add(oneDay);
        var sunrise2 = sunCalc.calculate(tomorrow, lat, lon, SUNRISE);
        if (sunrise2 != null) {
          sunrise2 = Time.Gregorian.info(sunrise2, Time.FORMAT_SHORT);
          iconStr = "0>";
          nextLabel = Lang.format("    $1$:$2$", [
            sunrise2.hour.format("%02d"),
            sunrise2.min.format("%02d"),
          ]);
        }
      }
      hDate = HebrewCalendar.getFormattedHebrewDateInHebrew(sunset);
      holyday = HebrewCalendar.getHebrewHolyday(sunset);
    } else {
      hDate = HebrewCalendar.getFormattedHebrewDateThisMorningInHebrew();
      holyday = HebrewCalendar.getHebrewHolydayForThisMorning();
    }

    // --- start dynamic layout drawing (replaces fixed-layout Text.setText calls) ---
    var w = dc.getWidth();
    var h = dc.getHeight();
    var cx = Math.floor(w / 2);
    // vertical positions as fractions of screen height (tweak as needed)
    //var holydayY = Math.floor(h * 0.12);
    //var topDateY = Math.floor(h * 0.22);
    //var timeY = Math.floor(h * 0.48);
    //var secondsY = Math.floor(timeY - (h * 0.04)); // slightly above time baseline if desired
    //var bottomDateY = Math.floor(h * 0.72);
    //var iconsY = Math.floor(h * 0.88);

    (View.findDrawableById("holydayLabel") as Text).setText(holyday.toString());
    (View.findDrawableById("holydayLabel") as Text).setFont(frankFont);
    var holydayY = Math.floor(h * 0.12);
    (View.findDrawableById("holydayLabel") as Text).setLocation(cx, holydayY);
    
    (View.findDrawableById("topDateLabel") as Text).setText(hDate.toString());
    (View.findDrawableById("topDateLabel") as Text).setFont(frankFont);
    var topDateY = Math.floor(h * 0.22);
    (View.findDrawableById("topDateLabel") as Text).setLocation(cx, topDateY);

    (View.findDrawableById("TimeLabel") as Text).setText(timeStr);
    var timeY = Math.floor(h * 0.48);
    (View.findDrawableById("TimeLabel") as Text).setLocation(cx, timeY);

    (View.findDrawableById("SecondsLabel") as Text).setText(secStr);
    var secondsY = Math.floor(timeY - (h * 0.04)); // slightly above time baseline if desired
    (View.findDrawableById("SecondsLabel") as Text).setLocation(cx + 60, secondsY); // adjust horizontal position as needed

    (View.findDrawableById("bottomDateLabel") as Text).setText(gDate);
    (View.findDrawableById("bottomDateLabel") as Text).setFont(frankFont);
    var bottomDateY = Math.floor(h * 0.72);
    (View.findDrawableById("bottomDateLabel") as Text).setLocation(cx, bottomDateY);
    
    var iconsY = Math.floor(h * 0.88);
    (View.findDrawableById("stepsLabel") as Text).setText(steps.toString());
    (View.findDrawableById("stepsLabel") as Text).setLocation(cx - 10, iconsY);
    //(View.findDrawableById("stepsLabel") as Text).setFont(frankFont);
    (View.findDrawableById("sunLabel") as Text).setText(nextLabel);
    (View.findDrawableById("sunLabel") as Text).setLocation(cx + 70, iconsY);

    //(View.findDrawableById("sunLabel") as Text).setFont(frankFont);
    (View.findDrawableById("iconsLabel") as Text).setText(iconStr);
    (View.findDrawableById("iconsLabel") as Text).setFont(iconFont);
    (View.findDrawableById("iconsLabel") as Text).setLocation(cx, iconsY);

    dc.drawBitmap(10, 198, stepsIcon);

    View.onUpdate(dc);
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {}

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {}
}
