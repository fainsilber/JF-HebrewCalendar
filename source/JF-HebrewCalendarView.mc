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
    var hebLabel = View.findDrawableById("HebDateLabel") as Text;
    hebLabel.setFont(myfonts);
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
    var secStr = clockTime.sec.format("%02d");

    var gInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var gDate = Lang.format("$1$/$2$/$3$", [gInfo.month.format("%02d"), gInfo.day.format("%02d"), gInfo.year]);
    var hDate = HebrewCalendar.getFormattedHebrewDate();

    (View.findDrawableById("TimeLabel") as Text).setText(timeStr);
    (View.findDrawableById("SecondsLabel") as Text).setText(secStr);
    (View.findDrawableById("GregDateLabel") as Text).setText(gDate);
    (View.findDrawableById("HebDateLabel") as Text).setText(hDate);

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
