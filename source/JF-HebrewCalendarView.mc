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
  // Global position and sun times
  var lat = 31.77758;
  var lon = 35.235786;
  var sunrise = null;
  var sunset = null;

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
  var shabbatLabel = null;

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
  var shabbatMode = false;
  var hebrewDateColor = Graphics.COLOR_BLUE;
  var timeColor = Graphics.COLOR_WHITE;
  var secondsColor = Graphics.COLOR_BLUE;
  var gregorianDateColor = Graphics.COLOR_WHITE;
  var sunEventColor = Graphics.COLOR_YELLOW;
  var stepsColor = Graphics.COLOR_GREEN;

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
    shabbatMode = loadBooleanSetting("shabbatMode", shabbatMode);

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
    // Choose a larger font for devices with a display bigger than 280
    if (width > 280 || height > 280) {
      frankFont = WatchUi.loadResource(Rez.Fonts.frank55);
    } else {
    frankFont = WatchUi.loadResource(Rez.Fonts.frank);
    }
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
    shabbatLabel = View.findDrawableById("shabbatLabel") as Text;
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
    shabbatLabel.setLocation(width / 2.0, 204.0 * yScale);

    stepsIconX = 10.0 * xScale;
    stepsIconY = 198.0 * yScale;
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    cacheDrawables();
    computeScale(dc);
    loadResources();
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

  function updateSunTimes(now) {
    if (sunrise == null || sunset == null) {
      sunrise = sunCalc.calculate(now, lat, lon, SUNRISE);
      sunset = sunCalc.calculate(now, lat, lon, SUNSET);
    } else {
      var nowInfo = Time.Gregorian.info(now, Time.FORMAT_LONG);
      var sunsetInfo = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      if (nowInfo.hour > sunsetInfo.hour ||
          (nowInfo.hour == sunsetInfo.hour && nowInfo.min >= sunsetInfo.min)) {
        var tomorrow = now.add(new Time.Duration(86400));
        sunrise = sunCalc.calculate(tomorrow, lat, lon, SUNRISE);
        sunset = sunCalc.calculate(tomorrow, lat, lon, SUNSET);
      }
    }
  }

  function calculateSunInfo() {
    var nextLabel = "";
    var hDate = "hb";
    var holyday = "";
    var iconStr = "0";
    var posInfo = Position.getInfo();
    var isDefaultGPS = true;
    if (posInfo != null) {
      var pos = posInfo.position.toDegrees();
      isDefaultGPS = (pos[0] > 179.99 && pos[1] > 179.99 && pos[0] < 180.01 && pos[1] < 180.01);
    }
    if (!isDefaultGPS && showSunEvent) {
      var posInRadians = posInfo.position.toRadians();
      if (lat != posInRadians[0] || lon != posInRadians[1]) {
      lat = posInRadians[0];
      lon = posInRadians[1];
        sunrise = null;
        sunset = null;
      }
      var now = Time.now();
      updateSunTimes(now);
      var nowInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
      var sunRiseTime = Time.Gregorian.info(sunrise, Time.FORMAT_LONG);
      var sunSetTime = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      var beforeSunrise = nowInfo.hour < sunRiseTime.hour || (nowInfo.hour == sunRiseTime.hour && nowInfo.min < sunRiseTime.min);
      var beforeSunset = nowInfo.hour < sunSetTime.hour || (nowInfo.hour == sunSetTime.hour && nowInfo.min < sunSetTime.min);
      if (beforeSunrise) {
        iconStr = "0>";
        nextLabel = Lang.format("   $1$:$2$", [sunRiseTime.hour.format("%02d"), sunRiseTime.min.format("%02d")]);
      } else if (beforeSunset) {
        iconStr = "0?";
        nextLabel = Lang.format("   $1$:$2$", [sunSetTime.hour.format("%02d"), sunSetTime.min.format("%02d")]);
      } else {
        iconStr = "0>";
        nextLabel = Lang.format("   $1$:$2$", [sunRiseTime.hour.format("%02d"), sunRiseTime.min.format("%02d")]);
        }
      var todaySunset = sunCalc.calculate(now, lat, lon, SUNSET);
      hDate = HebrewCalendar.getFormattedHebrewDateInHebrew(todaySunset);
      holyday = HebrewCalendar.getHebrewHolyday(todaySunset);
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

  function isShabbat(now) {

    var gNow = Time.Gregorian.info(now, Time.FORMAT_SHORT);
    if( gNow.day_of_week != 6 && gNow.day_of_week != 7) {
      return false; // Not Friday or Saturday
    }

    // If it's Friday, we only care if the current time is after the sunset time
    var hadlakatNerot = sunset.subtract(new Time.Duration(18 * 60));
    var hadlakatNerotTime = Time.Gregorian.info(hadlakatNerot, Time.FORMAT_LONG);
    if (gNow.day_of_week == 6 &&
        (gNow.hour > hadlakatNerotTime.hour ||
         (gNow.hour == hadlakatNerotTime.hour && gNow.min >= hadlakatNerotTime.min))) {
      return true; // After sunset on Friday
    }

    var motazsh = sunset.add(new Time.Duration(72 * 60)); // 72 minutes after sunset
    var motazshTime = Time.Gregorian.info(motazsh, Time.FORMAT_LONG);
    if (gNow.day_of_week == 7 &&
        (gNow.hour < motazshTime.hour ||
         (gNow.hour == motazshTime.hour && gNow.min < motazshTime.min))) {
      return true;
    }
    return false;
  }

  function updateShabbat(isActive) {
    if (isActive) {
      shabbatLabel.setText("שבת שלום");
      shabbatLabel.setFont(frankFont);
      shabbatLabel.setColor(hebrewDateColor);
    } else {
      shabbatLabel.setText("");
    }
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    loadSettings();
    computeScale(dc);
    dc.setClip(0, 0, width, height);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var now = Time.now();
    var shabbatActive = shabbatMode && isShabbat(now);
    if (shabbatActive) {
      showSteps = false;
      showSunEvent = false;
    }
    var clockTime = System.getClockTime();
    var gInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
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
    updateShabbat(shabbatActive);

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
