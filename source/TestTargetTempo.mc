import Toybox.Activity;
import Toybox.Lang;
import Toybox.Test;

//! Tests behaviour when device still reports nulls. 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoNullTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = null;
    ai.elapsedDistance = null;
    var target = tt.compute(ai);
    if (!target.equals("6:00")) {
        logger.debug("Expected '6:00', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when device reports zeros for elapsed values. 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoZeroTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 0;
    ai.elapsedDistance = 0.0;
    var target = tt.compute(ai);
    if (!target.equals("6:00")) {
        logger.debug("Expected '6:00', got '" + target + "'");
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
    var tt = new TargetTempoView();
    var ai = new Activity.Info();
    var target = "";
 
    tt = new TargetTempoView();
    for (var i = 0; i < 10; i += 1) {
        ai.elapsedTime = i * 1000;
        ai.elapsedDistance = i * 60.0;
        target = tt.compute(ai);
    }

    if (!target.equals("6:09")) {
        logger.debug("Expected '6:09', got '" + target + "'");
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
    var tt = new TargetTempoView();
    var ai = new Activity.Info();
    var target = "";
 
    tt = new TargetTempoView();
    for (var i = 0; i < 10; i += 1) {
        ai.elapsedTime = i * 1000;
        ai.elapsedDistance = i * 60.0;
        tt.compute(ai);
    }

    ai.elapsedTime = 10000;
    ai.elapsedDistance = 460.0;
    target = tt.compute(ai);

    if (!target.equals("6:10")) {
        logger.debug("Expected '6:10', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is left and time is exactly out 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistLeftTimeEqualTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3600000;
    ai.elapsedDistance = 9995.0;
    var target = tt.compute(ai);
    if (!target.equals(":-(")) {
        logger.debug("Expected ':-(', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is left and time passed 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistLeftTimePassedTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3601000;
    ai.elapsedDistance = 9995.0;
    var target = tt.compute(ai);
    if (!target.equals(":-(")) {
        logger.debug("Expected ':-(', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is exactly out and time is left 
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistEqualTimeLeftTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3599000;
    ai.elapsedDistance = 10000.0;
    var target = tt.compute(ai);
    if (!target.equals(":-)")) {
        logger.debug("Expected ':-)', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is exactly out and time is exactly out
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistEqualTimeEqualTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3600000;
    ai.elapsedDistance = 10000.0;
    var target = tt.compute(ai);
    if (!target.equals(":-)")) {
        logger.debug("Expected ':-)', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance is exactly out and time passed
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistEqualTimePassedTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3601000;
    ai.elapsedDistance = 10000.0;
    var target = tt.compute(ai);
    if (!target.equals(":-(")) {
        logger.debug("Expected ':-(', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance passed and time is left
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistPassedTimeLeftTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3599000;
    ai.elapsedDistance = 10001.0;
    var target = tt.compute(ai);
    if (!target.equals(":-)")) {
        logger.debug("Expected ':-)', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance passed and time is exactly out
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistPassedTimeEqualTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3600000;
    ai.elapsedDistance = 10001.0;
    var target = tt.compute(ai);
    if (!target.equals(":-)")) {
        logger.debug("Expected ':-)', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when distance passed and time passed
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistPassedTimePassedTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3601000;
    ai.elapsedDistance = 10001.0;
    var target = tt.compute(ai);
    if (!target.equals(":-)")) {
        logger.debug("Expected ':-)', got '" + target + "'");
        return false;
    }

    return true;
}

//! Tests behaviour when internal target may blow up, i.e.
//! when there is a small fraction of distance left.
//! This also test that we can get an estimated output of 'est. 0:00'.
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoDistFractionLeftTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 0;
    ai.elapsedDistance = 10000.0 - 0.001;
    ai.currentSpeed = 4.2;
    var target = tt.compute(ai);
    if (!target.equals("est. 0:00")) {
        logger.debug("Expected 'est. 0:00', got '" + target + "'");
        return false;
    }

    return true;
}

//! Test that we can get the limited output of 'est. 63:57'.
//! This test is dependent on the default property values in
//! targeDistance and targetTime, so make sure to revert back to default
//! after having modified persistent storage from within the simulator.
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function targetTempoToHighTempoTest(logger as Logger) as Boolean {
    var tt = new TargetTempoView();
    var ai = new Activity.Info();

    ai.elapsedTime = 3599000;
    ai.elapsedDistance = 9000.0;
    ai.currentSpeed = 4.2;
    var target = tt.compute(ai);
    if (!target.equals("est. 63:57")) {
        logger.debug("Expected 'est. 63:57', got '" + target + "'");
        return false;
    }

    return true;
}