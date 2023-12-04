import Toybox.Activity;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Application.Properties;
import Toybox.System;

//! Tests behaviour when device still reports nulls. 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoNullTest(logger as Logger) as Boolean {
    var targetValue = "6:00";
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "6:00";
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = null;
    ai.elapsedDistance = null;
    ai.currentSpeed = null;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when device reports zeros for elapsed values. 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoZeroTest(logger as Logger) as Boolean {
    var targetValue = "6:00";
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "6:00";
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 0;
    ai.elapsedDistance = 0.0;
    ai.currentSpeed = 0.0;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when SMA window is filled. 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoFillSMATest(logger as Logger) as Boolean {
    var targetValue = "6:10";
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "6:06";
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();
    var target = "";
 
    for (var i = 0; i < 10; i += 1) {
        ai.elapsedTime = i * 1000;
        ai.elapsedDistance = i * 60.0;
        ai.currentSpeed = 3.0;
        target = tt.compute(ai);
    }

    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour after SMA has handed over to EMA. 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoEMATest(logger as Logger) as Boolean {
    var targetValue = "6:10";
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "6:06";
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();
    var target = "";
 
    for (var i = 0; i < 10; i += 1) {
        ai.elapsedTime = i * 1000;
        ai.elapsedDistance = i * 60.0;
        ai.currentSpeed = 3.0;
        tt.compute(ai);
    }

    ai.elapsedTime = 10000;
    ai.elapsedDistance = 400.0;
    target = tt.compute(ai);

    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is left and time is out 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistLeftTimeEqualTest(logger as Logger) as Boolean {
    var targetValue = "eta 60:10";
    var statuteMultiplier = 1.0;
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "eta 60:16";
        statuteMultiplier = 1.609344;
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3600000;
    ai.elapsedDistance = 9970.0 * statuteMultiplier;
    ai.currentSpeed = 3.0;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is done and time has passed 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistEqualTimePassedTest(logger as Logger) as Boolean {
    var targetValue = "fin 60:10";
    var statuteMultiplier = 1.0;
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "fin 60:10";
        statuteMultiplier = 1.609344;
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3610000;
    ai.elapsedDistance = 10000.0 * statuteMultiplier;
    ai.currentSpeed = 3.0;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when internal target may blow up, i.e.
//! when there is a small fraction of distance left.
//! This also test that we can get an estimated output of 'eta 0:00'.
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistFractionLeftTest(logger as Logger) as Boolean {
    var targetValue = "eta 0:00";
    var statuteMultiplier = 1.0;
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "eta 0:00";
        statuteMultiplier = 1.609344;
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 0;
    ai.elapsedDistance = 10000.0 * statuteMultiplier - 0.001;
    ai.currentSpeed = 3.0;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Test that we can get eta output instead of target tempo when target tempo to high.
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoToHighTempoTest(logger as Logger) as Boolean {
    var targetValue = "eta 65:50";
    var elapsedTime = 3450;
    if (System.getDeviceSettings().distanceUnits == 1) {
        targetValue = "eta 88:51";
        elapsedTime = 2800;
    }

    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = elapsedTime * 1000;
    ai.elapsedDistance = 8500.0;
    ai.currentSpeed = 3.0;
    var target = tt.compute(ai);
    if (!target.equals(targetValue)) {
        logger.debug("Expected '" + targetValue + "', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests SMA dynamic Moving Average for ETA. 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoETATest(logger as Logger) as Boolean {
    var targetValue1 = "eta 55:07";
    var targetValue2 = "eta 55:14";
    var targetValue3 = "eta 54:56";
    var statuteAdder = 0.0;
    if (System.getDeviceSettings().distanceUnits == 1) {
        statuteAdder = 6093.44;
    }

    Properties.setValue("displayOption", 3);
    var tt = new TargetTempoView();
    Properties.setValue("displayOption", 0);
    var ai = new Activity.Info();
    var target = "";
 
    for (var i = 0; i < 200; i += 1) {
        ai.elapsedTime = i * 1000;
        ai.elapsedDistance = i * 3.0 + statuteAdder;
        ai.currentSpeed = 3.0;
        tt.compute(ai);
    }

    ai.elapsedTime = 200000;
    ai.elapsedDistance = 600.0 + statuteAdder;
    ai.currentSpeed = 6.0;
    target = tt.compute(ai);

    // expected output given a moving window size of 120
    if (!target.equals(targetValue1)) {
        logger.debug("Expected '" + targetValue1 + "', got '" + target + "'");
        return false;
    }

    for (var i = 0; i < 200; i += 1) {
        ai.elapsedTime = i * 1000 + 2000000;
        ai.elapsedDistance = i * 3.0 + 6000 + statuteAdder;
        ai.currentSpeed = 3.0;
        tt.compute(ai);
    }

    ai.elapsedTime = 2200000;
    ai.elapsedDistance = 6600.0 + statuteAdder;
    ai.currentSpeed = 6.0;
    target = tt.compute(ai);

    // expected output given a moving window size of 60
    if (!target.equals(targetValue2)) {
        logger.debug("Expected '" + targetValue2 + "', got '" + target + "'");
        return false;
    }

    for (var i = 0; i < 100; i += 1) {
        ai.elapsedTime = i * 1000 + 2833333;
        ai.elapsedDistance = i * 3.0 + 8500 + statuteAdder;
        ai.currentSpeed = 3.0;
        tt.compute(ai);
    }

    ai.elapsedTime = 2933333;
    ai.elapsedDistance = 8800.0 + statuteAdder;
    ai.currentSpeed = 6.0;
    target = tt.compute(ai);

    // expected output given a moving window size of 10
    if (!target.equals(targetValue3)) {
        logger.debug("Expected '" + targetValue3 + "', got '" + target + "'");
        return false;
    }

    return true;
}