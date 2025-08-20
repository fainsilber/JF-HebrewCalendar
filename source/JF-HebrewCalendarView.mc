import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Time.SunriseSunset;

class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var myfonts = null;
  var stepsIcon = null;

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
    var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
    var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);

    var gInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var gDate = Lang.format("$1$/$2$/$3$", [ gInfo.day.format("%02d"),gInfo.month.format("%02d"), gInfo.year]);
    var hDate = HebrewCalendar.getFormattedHebrewDate();

    var actInfo = ActivityMonitor.getInfo();
    var steps = actInfo.steps;

    var dev = System.getDeviceSettings();
    var pos = dev.position;
    var now = Time.now();
    var rise = SunriseSunset.getSunrise(now, pos);
    var set = SunriseSunset.getSunset(now, pos);
    var nextLabel = "";
    if (now < rise) {
      nextLabel = Lang.format("SR $1$:$2$", [rise.hour.format("%02d"), rise.min.format("%02d")]);
    } else if (now < set) {
      nextLabel = Lang.format("SS $1$:$2$", [set.hour.format("%02d"), set.min.format("%02d")]);
    } else {
      var tomorrow = now + 86400;
      var rise2 = SunriseSunset.getSunrise(tomorrow, pos);
      nextLabel = Lang.format("SR $1$:$2$", [rise2.hour.format("%02d"), rise2.min.format("%02d")]);
    }

    (View.findDrawableById("TimeLabel") as Text).setText(timeStr);
    (View.findDrawableById("SecondsLabel") as Text).setText(secStr);
    (View.findDrawableById("bottomDateLabel") as Text).setText(gDate);
    (View.findDrawableById("topDateLabel") as Text).setText(hDate);
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
