import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Math;
import Toybox.Application;
using Toybox.Application.Properties as appProperties;
using Toybox.Application.Storage as appStorage;
using Toybox.SensorHistory;

class JF_HebrewCalendarView extends WatchUi.WatchFace {
  var iconFont = null;
  var frankFont = null;
  var sunCalc = null;
  var hasOldApi = false;
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
  var stepsLabel = null;
  var stepsIconLabel = null;
  var sunLabel = null;
  var sunIconLabel = null;
  var shabbatLabel = null;

  // Layout information
  var width = 0.0;
  var height = 0.0;
  var xScale = 1.0;
  var yScale = 1.0;

  // Settings
  var showBattery = true;
  var showTime = true;
  var showSeconds = true;
  var showGregorianDate = true;
  var gregorianDateFormat = 3;
  var showSteps = true;
  var showSunEvent = true;
  var shabbatMode = false;
  var rabbenuTam = false;
  var chutzLaAretz = false;
  var stepsDataType = "steps";
  var sunDataType = "sun";
  var hebrewDateColor = Graphics.COLOR_BLUE;
  var timeColor = Graphics.COLOR_WHITE;
  var secondsColor = Graphics.COLOR_BLUE;
  var gregorianDateColor = Graphics.COLOR_WHITE;
  var sunEventColor = Graphics.COLOR_YELLOW;
  var stepsColor = Graphics.COLOR_GREEN;

  var EIGHTEEN_MINUTES = 18 * 60;
  var SEVENTY_TWO_MINUTES = 72 * 60;
  var THIRTY_SIX_MINUTES = 30 * 60;

  function initialize() {
    WatchFace.initialize();
  }

  function restoreStoredLocation() {
    var storedLat = appStorage.getValue("lat");
    var storedLon = appStorage.getValue("lon");
    if (storedLat != null && storedLon != null) {
      lat = storedLat;
      lon = storedLon;
      sunrise = null;
      sunset = null;
    }
  }

  // Convenience helpers for settings
  function loadBooleanSetting(name, current) {
    var val = null;
    if (!hasOldApi) {
      val = appProperties.getValue(name);
    } else {
      val = Application.getApp().getProperty(name);
    }

    return val == null ? current : val;
  }

  function loadNumberSetting(name, current) {
    var val = null;
    if (!hasOldApi) {
      val = appProperties.getValue(name);
    } else {
      val = Application.getApp().getProperty(name);
    }

    return val == null ? current : val;
  }

  function loadStringSetting(name, current) {
    var val = null;
    if (!hasOldApi) {
      val = appProperties.getValue(name);
    } else {
      val = Application.getApp().getProperty(name);
    }

    return val == null ? current : val;
  }

  function loadColorSetting(name) {
    //
    if (!hasOldApi) {
      return getColor(appProperties.getValue(name));
    } else {
      return getColor(Application.getApp().getProperty(name));
    }
  }

  function loadSettings() {
    showBattery = loadBooleanSetting("showBattery", showBattery);
    showTime = loadBooleanSetting("showTime", showTime);
    showSeconds = loadBooleanSetting("showSeconds", showSeconds);
    showGregorianDate = loadBooleanSetting(
      "showGregorianDate",
      showGregorianDate
    );
    gregorianDateFormat = loadNumberSetting(
      "gregorianDateFormat",
      gregorianDateFormat
    );
    showSteps = loadBooleanSetting("showSteps", showSteps);
    showSunEvent = loadBooleanSetting("showSunEvent", showSunEvent);
    shabbatMode = loadBooleanSetting("shabbatMode", shabbatMode);
    rabbenuTam = loadBooleanSetting("rabbenuTam", rabbenuTam);
    chutzLaAretz = loadBooleanSetting("chutzLaAretz", chutzLaAretz);
    stepsDataType = loadStringSetting("stepsDataType", stepsDataType);
    sunDataType = loadStringSetting("sunDataType", sunDataType);

    hebrewDateColor = loadColorSetting("hebrewDateColor");
    timeColor = loadColorSetting("timeColor");
    secondsColor = loadColorSetting("secondsColor");
    gregorianDateColor = loadColorSetting("gregorianDateColor");
    sunEventColor = loadColorSetting("sunEventColor");
    stepsColor = loadColorSetting("stepsColor");

    HebrewCalendar.setChutzLaAretzMode(chutzLaAretz);
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
    sunCalc = new SunCalc();
  }

  function cacheDrawables() {
    batteryLabel = View.findDrawableById("batteryLabel") as Text;
    holydayLabel = View.findDrawableById("holydayLabel") as Text;
    topDateLabel = View.findDrawableById("topDateLabel") as Text;
    timeLabel = View.findDrawableById("TimeLabel") as Text;
    secondsLabel = View.findDrawableById("SecondsLabel") as Text;
    bottomDateLabel = View.findDrawableById("bottomDateLabel") as Text;
    stepsLabel = View.findDrawableById("stepsLabel") as Text;
    stepsIconLabel = View.findDrawableById("stepsIconLabel") as Text;
    sunLabel = View.findDrawableById("sunLabel") as Text;
    sunIconLabel = View.findDrawableById("sunIconLabel") as Text;
    shabbatLabel = View.findDrawableById("shabbatLabel") as Text;
  }

  function computeScale(dc as Dc) {
    width = dc.getWidth();
    height = dc.getHeight();
    xScale = width / 260.0;
    yScale = height / 260.0;
    hasOldApi = resolutionToOldApi(width, height);
  }

  function resolutionToOldApi(width, height) {
    if (
      (width == 208 && height == 208) ||
      (width == 205 && height == 148) ||
      (width == 218 && height == 218) ||
      (width == 215 && height == 180)
    ) {
      return true;
    }
    return false;
  }

  function positionLabels() {
    holydayLabel.setLocation(width / 2.0, 25.0 * yScale);
    topDateLabel.setLocation(width / 2.0, 55.0 * yScale);
    secondsLabel.setLocation(200.0 * xScale, 118.0 * yScale);
    bottomDateLabel.setLocation(width / 2.0, 162.0 * yScale);
    var baselineY = 204.0 * yScale;
    var centerX = width / 2.0;

    stepsLabel.setLocation(centerX - 35.0 * xScale, baselineY);
    stepsIconLabel.setLocation(centerX - 25.0 * xScale, baselineY);
    sunIconLabel.setLocation(centerX + 25.0 * xScale, baselineY);
    sunLabel.setLocation(centerX + 30.0 * xScale, baselineY);
    shabbatLabel.setLocation(width / 2.0, 204.0 * yScale);
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    cacheDrawables();
    computeScale(dc);
    if (!hasOldApi) {
      restoreStoredLocation();
    }
    loadResources();
    positionLabels();
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  function onPartialUpdate(dc) {
    if (!hasOldApi) {
      var clockTime = System.getClockTime();
      var secStr = Lang.format(":$1$", [clockTime.sec.format("%02d")]);

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

  function updateBattery(stats) {
    var myStats = stats;
    if (myStats == null) {
      myStats = System.getSystemStats();
    }
    if (!showBattery) {
      batteryLabel.setText("");
      return;
    }
    var batteryLevel = myStats.battery;
    var battery = "";
    var color = Graphics.COLOR_GREEN;
    if (batteryLevel > 80) {
      battery = "B";
    } else if (batteryLevel > 60) {
      battery = "C";
    } else if (batteryLevel > 40) {
      battery = "D";
    } else if (batteryLevel > 10) {
      battery = "E";
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
      //bottomDateLabel.setFont(frankFont);
    } else {
      bottomDateLabel.setText("");
    }
  }

  function getOrdinalDay(day) {
    var mod100 = day % 100;
    var suffix = "th";
    if (mod100 < 11 || mod100 > 13) {
      var mod10 = day % 10;
      if (mod10 == 1) {
        suffix = "st";
      } else if (mod10 == 2) {
        suffix = "nd";
      } else if (mod10 == 3) {
        suffix = "rd";
      }
    }
    return Lang.format("$1$$2$", [day.format("%d"), suffix]);
  }

  function formatGregorianDate(now) {
    var info = Time.Gregorian.info(now, Time.FORMAT_LONG);
    var day = info.day;
    var month = info.month;
    var year = info.year;
    var weekDay = info.day_of_week;

    var dayStr = day.format("%d");
    var monthStr = month; //.format("%d");
    var yearStr = year.format("%d");

    var weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    var monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    // var weekdayIndex = weekDay;
    // if (weekdayIndex < 1 || weekdayIndex > weekdayNames.size()) {
    //   weekdayIndex = 1;
    // }
    // var monthIndex = month;
    // if (monthIndex < 1 || monthIndex > monthNames.size()) {
    //   monthIndex = 1;
    // }

    var weekdayName = weekDay; //weekdayNames[weekdayIndex - 1];
    var monthName = monthStr; // monthNames[monthIndex - 1];
    var format = gregorianDateFormat;
    if (format == null) {
      format = 3;
    }

    if (format == 1 || format == "1") {
      return Lang.format("$1$, $2$ $3$", [weekdayName, dayStr, monthName]);
    } else if (format == 2 || format == "2") {
      return Lang.format("$1$, $2$ $3$", [
        weekdayName,
        monthName,
        getOrdinalDay(day),
      ]);
    } else if (format == 3 || format == "3") {
      return Lang.format("$1$/$2$/$3$", [dayStr, monthStr, yearStr]);
    } else if (format == 4 || format == "4") {
      return Lang.format("$1$ $2$, $3$", [monthName, dayStr, yearStr]);
    }

    return Lang.format("$1$/$2$/$3$", [dayStr, monthStr, yearStr]);
  }

  function formatIntValue(value) {
    if (value == null) {
      return "--";
    }
    return value.format("%d");
  }

  function formatPercentValue(value) {
    if (value == null) {
      return "--";
    }
    return Lang.format("$1$%", [value.format("%d")]);
  }

  function getDataFieldData(dataType, actInfo, stats, sunInfo, hrInfo) {
    /*
            <settingConfig type="list">
            <listEntry value="1">@Strings.DataNextSunEvent</listEntry>
            <listEntry value="2">@Strings.DataSteps</listEntry>
            <listEntry value="3">@Strings.DataHeartRate</listEntry>
            <listEntry value="4">@Strings.DataBodyBattery</listEntry>
            <listEntry value="5">@Strings.DataFloors</listEntry>
            <listEntry value="6">@Strings.DataIntensityMinutes</listEntry>
            <listEntry value="7">@Strings.DataCalories</listEntry>
            <listEntry value="8">@Strings.DataBattery</listEntry>
        </settingConfig>
    */
    if (dataType == null) {
      return null;
    }

    if (dataType == "off") {
      return null;
    }
    
    if (dataType == 1) {
      if (sunInfo != null) {
        var SunEvent = "";
        var icon = "";
        if (sunInfo != null ) {
          SunEvent = sunInfo["label"];
          icon = sunInfo["sunIcon"];  
        }
        return {
          "text" => SunEvent,
          "icon" => icon,
          "iconFont" => iconFont,
        };
      }
    }

    if (dataType == 2) {
      var stepsNum = null;
      if (actInfo != null) {
        if (actInfo.steps != null) {
          stepsNum = actInfo.steps;
        } else {
          stepsNum = null;
        }
      }
      return {
        "text" => formatIntValue(stepsNum),
        "icon" => "0",
        "iconFont" => iconFont,
      };
    }

    if (dataType == 3) {
      var heartRate = null;
      if (hrInfo != null) {
        heartRate = hrInfo.currentHeartRate;// actInfo.currentHeartRate;
      }
      if (heartRate == null || heartRate <= 0) {
        heartRate = null;
      }
      return {
        "text" => formatIntValue(heartRate),
        "icon" => "HR",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    if (dataType == 4) {
      var bodyBattery = null;
      // get the body battery iterator object
      var bbIterator = getIterator();
      var bbSample = bbIterator.next();                         // get the body battery data
      if (actInfo != null ) {
        bodyBattery = bbSample.data;
      }
      return {
        "text" => formatPercentValue(bodyBattery),
        "icon" => "BB",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    if (dataType == 5) {
      var floors = null;
      if (actInfo != null && !hasOldApi) {
        floors = actInfo.floorsClimbed;
      }
      return {
        "text" => formatIntValue(floors),
        "icon" => "FL",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    if (dataType == 6) {
      var minutes = null;
      if (actInfo != null && !hasOldApi) {
        var actMinutes = actInfo.activeMinutesDay;
        var moderateMinutes = actMinutes.moderate;
        var vigorousMinutes = actMinutes.vigorous;
            
            // Calculate the total based on Garmin's display logic (vigorous minutes count double)
        minutes = moderateMinutes + (vigorousMinutes * 2);
        // actInfo.intensity;//need fix
      }
      return {
        "text" => formatIntValue(minutes),
        "icon" => "IM",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    if (dataType == 7) {
      var calories = null;
      if (actInfo != null && !hasOldApi) {
        calories = actInfo.calories;
      }
      return {
        "text" => formatIntValue(calories),
        "icon" => "CAL",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    if (dataType == 8) {
      var batteryLevel = stats != null ? stats.battery : null;
      return {
        "text" => formatPercentValue(batteryLevel),
        "icon" => "BT",
        "iconFont" => Graphics.FONT_TINY,
      };
    }

    return null;
  }

  // Create a method to get the SensorHistoryIterator object
  function getIterator() {
      // Check device for SensorHistory compatibility
      if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
          // Set up the method with parameters
          return Toybox.SensorHistory.getBodyBatteryHistory({});
      }
      return null;
  }
  

  function applyDataToLabels(valueLabel, iconLabel, color, data) {
    if (data == null) {
      valueLabel.setText("");
      iconLabel.setText("");
      return;
    }

    var text = data["text"];
    if (text == null) {
      text = "--";
    }
    valueLabel.setColor(color);
    valueLabel.setText(text);

    var iconText = data["icon"];
    if (iconText == null || iconText == "") {
      iconLabel.setText("");
      return;
    }

    var fontToUse = data["iconFont"];
    if (fontToUse == null) {
      fontToUse = iconFont;
    }
    iconLabel.setColor(color);
    iconLabel.setText(iconText);
    if (fontToUse == iconFont) {
      iconLabel.setFont(iconFont);
    } else {
      iconLabel.setFont(fontToUse);
    }
  }

  function updateLeftData(actInfo, stats, sunInfo, hrInfo) {
    // if (!showSteps) {
    //   stepsLabel.setText("");
    //   stepsIconLabel.setText("");
    //   return;
    // }

    var data = getDataFieldData(stepsDataType, actInfo, stats, sunInfo, hrInfo);
    applyDataToLabels(stepsLabel, stepsIconLabel, stepsColor, data);
  }

  function updateRightData(actInfo, stats, sunInfo, hrInfo) {
    // if (!showSunEvent) {
    //   sunLabel.setText("");
    //   sunIconLabel.setText("");
    //   return;
    // }

    var data = getDataFieldData(sunDataType, actInfo, stats, sunInfo, hrInfo);
    applyDataToLabels(sunLabel, sunIconLabel, sunEventColor, data);
  }

  function updateSunTimes(now) {
    if (sunrise == null || sunset == null) {
      sunrise = sunCalc.calculate(now, lat, lon, SUNRISE);
      sunset = sunCalc.calculate(now, lat, lon, SUNSET);
    } else {
      var nowInfo = Time.Gregorian.info(now, Time.FORMAT_LONG);
      var sunsetInfo = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      if (
        nowInfo.hour > sunsetInfo.hour ||
        (nowInfo.hour == sunsetInfo.hour && nowInfo.min >= sunsetInfo.min)
      ) {
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
    var sunIcon = "";
    var posInfo = Position.getInfo();
    var hasValidFix = false;
    if (posInfo != null) {
      var pos = posInfo.position.toDegrees();
      hasValidFix = !(
        pos[0] > 179.99 &&
        pos[1] > 179.99 &&
        pos[0] < 180.01 &&
        pos[1] < 180.01
      );
      if (hasValidFix) {
        var posInRadians = posInfo.position.toRadians();
        if (lat != posInRadians[0] || lon != posInRadians[1]) {
          lat = posInRadians[0];
          lon = posInRadians[1];
          sunrise = null;
          sunset = null;
          if (!hasOldApi) {
            appStorage.setValue("lat", lat);
            appStorage.setValue("lon", lon);
          }
        }
      }
    }
    var haveStoredLocation = false;
    if (!hasOldApi) {
      haveStoredLocation =
        appStorage.getValue("lat") != null &&
        appStorage.getValue("lon") != null;
    }
    var shouldShowSunData = showSunEvent && sunDataType == 1;
    var hasLocation = hasValidFix || haveStoredLocation;

    if (hasLocation) {
      var now = Time.now();
      updateSunTimes(now);
      var nowInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
      var sunRiseTime = Time.Gregorian.info(sunrise, Time.FORMAT_LONG);
      var sunSetTime = Time.Gregorian.info(sunset, Time.FORMAT_LONG);
      var beforeSunrise =
        nowInfo.hour < sunRiseTime.hour ||
        (nowInfo.hour == sunRiseTime.hour && nowInfo.min < sunRiseTime.min);
      var beforeSunset =
        nowInfo.hour < sunSetTime.hour ||
        (nowInfo.hour == sunSetTime.hour && nowInfo.min < sunSetTime.min);

      if (shouldShowSunData) {
        if (beforeSunrise) {
          sunIcon = ">";
          nextLabel = Lang.format("$1$:$2$", [
            sunRiseTime.hour.format("%02d"),
            sunRiseTime.min.format("%02d"),
          ]);
        } else if (beforeSunset) {
          sunIcon = "?";
          nextLabel = Lang.format("$1$:$2$", [
            sunSetTime.hour.format("%02d"),
            sunSetTime.min.format("%02d"),
          ]);
        } else {
          sunIcon = ">";
          nextLabel = Lang.format("$1$:$2$", [
            sunRiseTime.hour.format("%02d"),
            sunRiseTime.min.format("%02d"),
          ]);
        }
      }
      var todaySunset = sunCalc.calculate(now, lat, lon, SUNSET);
      hDate = HebrewCalendar.getFormattedHebrewDateInHebrew(todaySunset);
      holyday = HebrewCalendar.getHebrewHolyday(todaySunset);
    } else {
      hDate = HebrewCalendar.getFormattedHebrewDateThisMorningInHebrew();
      holyday = HebrewCalendar.getHebrewHolydayForThisMorning();
      if (shouldShowSunData) {
        nextLabel = "GPS?";
      }
    }
    return {
      "sunIcon" => sunIcon,
      "label" => nextLabel,
      "hDate" => hDate,
      "holyday" => holyday,
    };
  }

  function isShabbat(now) {
    var gNow = Time.Gregorian.info(now, Time.FORMAT_SHORT);
    if (sunset == null) {
      if (gNow.day_of_week != 7) {
        return false;
      } else {
        return true; // It's Saturday, but we don't know the sunset time, so assume it's Shabbat
      }
    }

    if (gNow.day_of_week != 6 && gNow.day_of_week != 7) {
      return false; // Not Friday or Saturday
    }

    // If it's Friday, we only care if the current time is after the sunset time
    var hadlakatNerot = sunset.subtract(new Time.Duration(EIGHTEEN_MINUTES));
    var hadlakatNerotTime = Time.Gregorian.info(
      hadlakatNerot,
      Time.FORMAT_LONG
    );
    if (
      gNow.day_of_week == 6 &&
      (gNow.hour > hadlakatNerotTime.hour ||
        (gNow.hour == hadlakatNerotTime.hour &&
          gNow.min >= hadlakatNerotTime.min))
    ) {
      return true; // After sunset on Friday
    }

    var minutesAfterSunset = 0;
    if (!rabbenuTam) {
      minutesAfterSunset = THIRTY_SIX_MINUTES; // 36 minutes after sunset for standard
    } else {
      minutesAfterSunset = SEVENTY_TWO_MINUTES; // 72 minutes after sunset for Rabbenu Tam
    }

    var motazsh = sunset.add(new Time.Duration(minutesAfterSunset));
    var motazshTime = Time.Gregorian.info(motazsh, Time.FORMAT_LONG);
    if (
      gNow.day_of_week == 7 &&
      (gNow.hour < motazshTime.hour ||
        (gNow.hour == motazshTime.hour && gNow.min < motazshTime.min))
    ) {
      return true;
    }
    return false;
  }

  // Return true when a chag is in effect
  function isChag(now) {
    var gNow = Time.Gregorian.info(now, Time.FORMAT_LONG);
    if (sunset == null) {
      if (!HebrewCalendar.isChagForThisMorning()) {
        return false;
      } else {
        return true; // It's Chag, but we don't know the sunset time
      }
    }

    // Check if the upcoming evening begins a chag
    var hadlakatNerot = sunset.subtract(new Time.Duration(EIGHTEEN_MINUTES));
    var hadlakatNerotTime = Time.Gregorian.info(
      hadlakatNerot,
      Time.FORMAT_LONG
    );
    if (
      HebrewCalendar.isChagForTomorrowMorning() &&
      (gNow.hour > hadlakatNerotTime.hour ||
        (gNow.hour == hadlakatNerotTime.hour &&
          gNow.min >= hadlakatNerotTime.min))
    ) {
      return true;
    }

    // Check if today is chag and we have not yet passed 72 minutes after sunset
    if (HebrewCalendar.isChagForThisMorning()) {
      var todaySunset = sunCalc.calculate(now, lat, lon, SUNSET);
      var minutesAfterSunset = 0;
      if (!rabbenuTam) {
        minutesAfterSunset = THIRTY_SIX_MINUTES; // 36 minutes after sunset for standard
      } else {
        minutesAfterSunset = SEVENTY_TWO_MINUTES; // 72 minutes after sunset for Rabbenu Tam
      }
      var motzaeiChag = todaySunset.add(new Time.Duration(minutesAfterSunset));
      if (now.value() < motzaeiChag.value()) {
        return true;
      }
    }
    return false;
  }

  function updateYomTovLabel(shabbatActive, chagActive) {
    if (shabbatActive) {
      shabbatLabel.setText("שבת שלום");
      shabbatLabel.setFont(frankFont);
      shabbatLabel.setColor(hebrewDateColor);
    } else if (chagActive) {
      shabbatLabel.setText("חג שמח");
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
    if (!hasOldApi) {
      dc.setClip(0, 0, width, height);
    }
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var now = Time.now();

    var clockTime = System.getClockTime();
    var gDate = formatGregorianDate(now);
    var actInfo = ActivityMonitor.getInfo();
    var hrInfo = Activity.getActivityInfo();
    var systemStats = System.getSystemStats();
    var sunInfo = calculateSunInfo();

    var shabbatActive = shabbatMode && isShabbat(now);
    var chagActive = shabbatMode && !shabbatActive && isChag(now);
    if (shabbatActive || chagActive) {
      showSteps = false;
      showSunEvent = false;
      sunInfo["sunIcon"] = "";
    }

    updateHebrewDate(sunInfo["hDate"], sunInfo["holyday"]);
    updateBattery(systemStats);
    updateTime(clockTime);
    updateGregorianDate(gDate);
    updateLeftData(actInfo, systemStats, sunInfo, hrInfo);
    updateRightData(actInfo, systemStats, sunInfo, hrInfo);
    updateYomTovLabel(shabbatActive, chagActive);

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
