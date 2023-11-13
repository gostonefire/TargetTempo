import Toybox.Lang;
import Toybox.Test;

//! Tests behaviour in SMA mode 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function smaTest(logger as Logger) as Boolean {
    var ma = new MovingAverage(false, 20, 2.0);
    var value = 0.0;

    if (ma.size() != 0) {
        logger.debug("Expected 0, got " + ma.size());
        return false;
    }
 
    // Start with 20 low ones
    for (var i = 0.0; i < 20; i += 1) {
        value = ma.movingAverage(i);
    }

    if (value != 9.5) {
        logger.debug("Expected 9.5, got " + value);
        return false;
    }

    if (ma.size() != 20) {
        logger.debug("Expected 20, got " + ma.size());
        return false;
    }

    // Continue with 20 higher ones, and the lower ones should 
    // then get spooled out given the window size of 20 
    for (var i = 0.0; i < 20; i += 1) {
        value = ma.movingAverage(i + 100);
    }

    if (value != 109.5) {
        logger.debug("Expected 109.5, got " + value);
        return false;
    }

    if (ma.size() != 20) {
        logger.debug("Expected 20, got " + ma.size());
        return false;
    }

    return true;
}

//! Tests behaviour in EMA mode 
//! @param logger Is a Test.Logger object
//! @return A boolean indicating success (true) or fail (false)
(:test)
function emaTest(logger as Logger) as Boolean {
    var ma = new MovingAverage(true, 10, 2.0);

    var value = 0.0;
 
    // Start with 10 low ones, these should go only to SMA since EMA
    // allways starts with SMA.
    for (var i = 0.0; i < 10; i += 1) {
        value = ma.movingAverage(i);
    }

    if (value != 4.5) {
        logger.debug("Expected 4.5, got " + value);
        return false;
    }

    // Size should now be 0 since the MA is supposed to have switched from SMA to EMA
    if (ma.size() != 0) {
        logger.debug("Expected 0, got " + ma.size());
        return false;
    }

    // Continue with next value in series (10), the EMA algorithm
    // should then result in a value of 5.5 if everything goes well.
    // Should the moving average stay in SMA the output is instead 5.0 
    // which in this case would be wrong.
    value = ma.movingAverage(10.0);

    if (value != 5.5) {
        logger.debug("Expected 5.5, got " + value);
        return false;
    }

    // Size should now be 0 since the MA is supposed to have switched from SMA to EMA
    if (ma.size() != 0) {
        logger.debug("Expected 0, got " + ma.size());
        return false;
    }
    
    return true;
}