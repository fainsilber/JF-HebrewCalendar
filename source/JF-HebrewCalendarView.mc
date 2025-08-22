import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Math;

class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var myfonts = null;
  var stepsIcon = null;
  var sunCalc = null;

  function initialize() {
    WatchFace.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    myfonts = WatchUi.loadResource(Rez.Fonts.frank);
    var hebLabel = View.findDrawableById("topDateLabel") as Text;
    //hebLabel.setFont(myfonts);
    stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
    sunCalc = new SunCalc();
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

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
        nextLabel = Lang.format("   $1$:$2$", [
          sunRiseTime.hour.format("%02d"),
          sunRiseTime.min.format("%02d"),
        ]);
      } else if (sunset != null && beforeSunset) {
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
          nextLabel = Lang.format(" SR $1$:$2$", [
            sunrise2.hour.format("%02d"),
            sunrise2.min.format("%02d"),
          ]);
        }
      }
      hDate = HebrewCalendar.getFormattedHebrewDate(sunset);
    } else {
      hDate = HebrewCalendar.getFormattedHebrewDateThisMorning();
    }

    (View.findDrawableById("TimeLabel") as Text).setText(timeStr);
    (View.findDrawableById("SecondsLabel") as Text).setText(secStr);
    (View.findDrawableById("bottomDateLabel") as Text).setText(gDate);
    (View.findDrawableById("topDateLabel") as Text).setText(hDate.toString());
    (View.findDrawableById("stepsLabel") as Text).setText(steps.toString());
    (View.findDrawableById("sunLabel") as Text).setText(nextLabel);

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
