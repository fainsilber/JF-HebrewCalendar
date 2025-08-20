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
    var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
    var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);

    var gInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var gDate = Lang.format("$1$/$2$/$3$", [ gInfo.day.format("%02d"),gInfo.month.format("%02d"), gInfo.year]);
    var hDate = HebrewCalendar.getFormattedHebrewDate();

    var actInfo = Activity.getActivityInfo();
    var steps = actInfo != null ? actInfo.steps : 0;

    var nextLabel = "";
    var posInfo = Position.getInfo();
    if (posInfo != null) {
      var lat = posInfo.latitude * Math.PI / 180.0;
      var lon = posInfo.longitude * Math.PI / 180.0;
      var now = Time.now();
      var sunrise = sunCalc.calculate(now, lat, lon, SUNRISE);
      var sunset = sunCalc.calculate(now, lat, lon, SUNSET);
      if (sunrise != null && now < sunrise) {
        nextLabel = Lang.format("SR $1$:$2$", [sunrise.hour.format("%02d"), sunrise.min.format("%02d")]);
      } else if (sunset != null && now < sunset) {
        nextLabel = Lang.format("SS $1$:$2$", [sunset.hour.format("%02d"), sunset.min.format("%02d")]);
      } else {
        var tomorrow = new Time.Moment(now.value() + 86400);
        var sunrise2 = sunCalc.calculate(tomorrow, lat, lon, SUNRISE);
        if (sunrise2 != null) {
          nextLabel = Lang.format("SR $1$:$2$", [sunrise2.hour.format("%02d"), sunrise2.min.format("%02d")]);
        }
      }
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
