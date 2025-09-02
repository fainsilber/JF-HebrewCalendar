import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Math;
import Toybox.Application;

class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var iconFont = null;
  var frankFont = null;
  var stepsIcon = null;
  var sunCalc = null;

  // Cached drawable references
  var batteryLabel = null;
  var holydayLabel = null;
  var topDateLabel = null;
  var timeLabel = null;
  var secondsLabel = null;
  var bottomDateLabel = null;
  var iconsLabel = null;
  var stepsLabel = null;
  var sunLabel = null;

  // Layout information
  var width = 0.0;
  var height = 0.0;
  var xScale = 1.0;
  var yScale = 1.0;
  var stepsIconX = 0.0;
  var stepsIconY = 0.0;

  // Settings
  var showBattery = true;
  var showTime = true;
  var showSeconds = true;
  var showGregorianDate = true;
  var showSteps = true;
  var showSunEvent = true;
  var hebrewDateColor = Graphics.COLOR_WHITE;
  var timeColor = Graphics.COLOR_WHITE;
  var secondsColor = Graphics.COLOR_WHITE;
  var gregorianDateColor = Graphics.COLOR_WHITE;
  var sunEventColor = Graphics.COLOR_WHITE;
  var stepsColor = Graphics.COLOR_WHITE;

  function initialize() {
    WatchFace.initialize();
  }

  // Convenience helpers for settings
  function loadBooleanSetting(name, current) {
    var val = Properties.getValue(name);
    return val == null ? current : val;
  }

  function loadColorSetting(name) {
    return getColor(Properties.getValue(name));
  }

  function loadSettings() {
    showBattery = loadBooleanSetting("showBattery", showBattery);
    showTime = loadBooleanSetting("showTime", showTime);
    showSeconds = loadBooleanSetting("showSeconds", showSeconds);
    showGregorianDate = loadBooleanSetting("showGregorianDate", showGregorianDate);
    showSteps = loadBooleanSetting("showSteps", showSteps);
    showSunEvent = loadBooleanSetting("showSunEvent", showSunEvent);

    hebrewDateColor = loadColorSetting("hebrewDateColor");
    timeColor = loadColorSetting("timeColor");
    secondsColor = loadColorSetting("secondsColor");
    gregorianDateColor = loadColorSetting("gregorianDateColor");
    sunEventColor = loadColorSetting("sunEventColor");
    stepsColor = loadColorSetting("stepsColor");
  }

  // Resource loading and layout helpers
  function loadResources() {
    iconFont = WatchUi.loadResource(Rez.Fonts.icons);
    frankFont = WatchUi.loadResource(Rez.Fonts.frank);
    stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
    sunCalc = new SunCalc();
  }

  function cacheDrawables() {
    batteryLabel = View.findDrawableById("batteryLabel") as Text;
    holydayLabel = View.findDrawableById("holydayLabel") as Text;
    topDateLabel = View.findDrawableById("topDateLabel") as Text;
    timeLabel = View.findDrawableById("TimeLabel") as Text;
    secondsLabel = View.findDrawableById("SecondsLabel") as Text;
    bottomDateLabel = View.findDrawableById("bottomDateLabel") as Text;
    iconsLabel = View.findDrawableById("iconsLabel") as Text;
    stepsLabel = View.findDrawableById("stepsLabel") as Text;
    sunLabel = View.findDrawableById("sunLabel") as Text;
  }

  function computeScale(dc as Dc) {
    width = dc.getWidth();
    height = dc.getHeight();
    xScale = width / 260.0;
    yScale = height / 260.0;
  }

  function positionLabels() {
    holydayLabel.setLocation(width / 2.0, 25.0 * yScale);
    topDateLabel.setLocation(width / 2.0, 55.0 * yScale);
    secondsLabel.setLocation(200.0 * xScale, 118.0 * yScale);
    bottomDateLabel.setLocation(width / 2.0, 162.0 * yScale);
    iconsLabel.setLocation(width / 2.0, 204.0 * yScale);
    stepsLabel.setLocation(100.0 * xScale, 204.0 * yScale);
    sunLabel.setLocation(150.0 * xScale, 204.0 * yScale);

    stepsIconX = 10.0 * xScale;
    stepsIconY = 198.0 * yScale;
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    loadResources();
    cacheDrawables();
    computeScale(dc);
    positionLabels();
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  function onPartialUpdate(dc) {
    var clockTime = System.getClockTime();
    var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);

    computeScale(dc);
    var secondsX = 200.0 * xScale;
    var secondsY = 118.0 * yScale;

    dc.setClip(secondsX, secondsY, 60, 60);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(secondsColor, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      secondsX,
      secondsY,
      Graphics.FONT_NUMBER_MILD,
      secStr,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  // Update helpers
  function updateHebrewDate(hDate, holyday) {
    holydayLabel.setText(holyday.toString());
    holydayLabel.setFont(frankFont);
    holydayLabel.setColor(hebrewDateColor);

    topDateLabel.setText(hDate.toString());
    topDateLabel.setFont(frankFont);
    topDateLabel.setColor(hebrewDateColor);
  }

  function updateBattery() {
    if (!showBattery) {
      batteryLabel.setText("");
      return;
    }
    var myStats = System.getSystemStats();
    var batteryLevel = myStats.battery;
    var battery = "";
    var color = Graphics.COLOR_GREEN;
    if (batteryLevel > 80) {
      battery = "B";
    } else if (batteryLevel > 60) {
      battery = "C";
    } else if (batteryLevel > 40) {
      battery = "D";
    } else if (batteryLevel > 20) {
      battery = "E";
      color = Graphics.COLOR_ORANGE;
    } else {
      battery = "F";
      color = Graphics.COLOR_RED;
    }
    batteryLabel.setColor(color);
    batteryLabel.setText(battery.toString());
    batteryLabel.setFont(iconFont);
  }

  function updateTime(clockTime) {
    if (showTime) {
      var timeStr = Lang.format("$1$:$2$", [
        clockTime.hour.format("%02d"),
        clockTime.min.format("%02d"),
      ]);
      timeLabel.setColor(timeColor);
      timeLabel.setText(timeStr);
    } else {
      timeLabel.setText("");
    }

    if (showSeconds) {
      var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);
      secondsLabel.setColor(secondsColor);
      secondsLabel.setText(secStr);
    } else {
      secondsLabel.setText("");
    }
  }

  function updateGregorianDate(gDate) {
    if (showGregorianDate) {
      bottomDateLabel.setColor(gregorianDateColor);
      bottomDateLabel.setText(gDate);
      bottomDateLabel.setFont(frankFont);
    } else {
      bottomDateLabel.setText("");
    }
  }

  function updateSteps(dc as Dc, stepsNum) {
    if (showSteps) {
      var steps = Lang.format("$1$ ", [stepsNum, ""]);
      stepsLabel.setText(steps.toString());
      stepsLabel.setColor(stepsColor);
      dc.drawBitmap(stepsIconX, stepsIconY, stepsIcon);
    } else {
      stepsLabel.setText("");
    }
  }

  function updateSunEvent(info) {
    if (showSunEvent) {
      sunLabel.setColor(sunEventColor);
      sunLabel.setText(info["label"]);
      iconsLabel.setText(info["icon"]);
      iconsLabel.setFont(iconFont);
    } else {
      sunLabel.setText("");
      iconsLabel.setText("");
    }
  }

  function calculateSunInfo() {
    var nextLabel = "";
    var hDate = "hb";
    var holyday = "";
    var iconStr = "0";
    var lat = 31.77758;
    var lon = 35.235786;
    var posInfo = Position.getInfo();
    var isDefaultGPS = true;
    if (posInfo != null) {
      var pos = posInfo.position.toDegrees();
      isDefaultGPS = (pos[0] > 179.99 && pos[1] > 179.99 && pos[0] < 180.01 && pos[1] < 180.01);
    }
    if (!isDefaultGPS && showSunEvent) {
      var posInRadians = posInfo.position.toRadians();
      lat = posInRadians[0];
      lon = posInRadians[1];
      var now = Time.now();
      var sunrise = sunCalc.calculate(now, lat, lon, SUNRISE);
      var sunset = sunCalc.calculate(now, lat, lon, SUNSET);
      now = Time.Gregorian.info(now, Time.FORMAT_SHORT);
      var sunRiseTime = Time.Gregorian.info(sunrise, Time.FORMAT_LONG);
      var sunSetTime = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      var afterSunrise = now.hour > sunRiseTime.hour ||
        (now.hour == sunRiseTime.hour && now.min >= sunRiseTime.min);
      var beforeSunset = now.hour < sunSetTime.hour ||
        (now.hour == sunSetTime.hour && now.min <= sunSetTime.min);
      if (sunrise != null && !afterSunrise) {
        iconStr = "0>";
        nextLabel = Lang.format("   $1$:$2$", [
          sunRiseTime.hour.format("%02d"),
          sunRiseTime.min.format("%02d"),
        ]);
      } else if (sunset != null && beforeSunset) {
        iconStr = "0?";
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
          iconStr = "0?";
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
    return {
      "icon" => iconStr,
      "label" => nextLabel,
      "hDate" => hDate,
      "holyday" => holyday,
    };
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    loadSettings();
    computeScale(dc);
    dc.setClip(0, 0, width, height);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var clockTime = System.getClockTime();
    var gInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var gDate = Lang.format("$1$/$2$/$3$", [
      gInfo.day.format("%02d"),
      gInfo.month.format("%02d"),
      gInfo.year,
    ]);
    var actInfo = ActivityMonitor.getInfo();
    var stepsNum = actInfo != null ? actInfo.steps : 0;
    var sunInfo = calculateSunInfo();

    updateHebrewDate(sunInfo["hDate"], sunInfo["holyday"]);
    updateBattery();
    updateTime(clockTime);
    updateGregorianDate(gDate);
    updateSteps(dc, stepsNum);
    updateSunEvent(sunInfo);

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

  // Simplified color lookup
  function getColor(color) as ColorValue {
    var colors = [
      Graphics.COLOR_WHITE,
      Graphics.COLOR_DK_GRAY,
      Graphics.COLOR_BLUE,
      Graphics.COLOR_RED,
      Graphics.COLOR_GREEN,
      Graphics.COLOR_ORANGE,
      Graphics.COLOR_YELLOW,
    ];
    if (color == null) {
      return Graphics.COLOR_WHITE;
    }
    if (color >= 1 && color <= colors.size()) {
      return colors[color - 1];
    }
    return Graphics.COLOR_WHITE;
  }
}
