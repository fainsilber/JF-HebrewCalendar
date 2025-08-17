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
    var hDate = HebrewCalendar.getFormattedHebrewDate();
    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      dc.getWidth() / 2, // gets the width of the device and divides by 2
      dc.getHeight() / 4, // gets the height of the device and divides by 2
      myfonts,
      hDate, // the String to display
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

}
