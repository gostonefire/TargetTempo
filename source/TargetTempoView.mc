import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Application.Properties;


//! Data field that shows target tempo to reach time and distance goal
class TargetTempoView extends WatchUi.SimpleDataField {
    // Movin Average constants
    private const SMA_WINDOW = 10;
    private const EMA_SMOOTHING = 2.0;
    private const EMA_MULTIPLIER as Float = EMA_SMOOTHING / (1.0 + SMA_WINDOW);

    // Moving Average variables, Simple Moving Average is allways the start of 
    // an Exponential Moving Average 
    private var _targetSMA as Array;
    private var _targetEMA as Float;
    private var _smaMode as Boolean;

    // Stores settings from properties to avoid reading them every second in the compute method
    private var _targetTime as Number;
    private var _targetDist as Number;

    // The done flag and what face to show when we are done
    private var _doneFace as String;
    private var _isDone as Boolean;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();

        var targetMinutes = Properties.getValue("targetMinutes");
        var targetSeconds = Properties.getValue("targetSeconds");
        var targetDistance = Properties.getValue("targetDistance");

        var format = Application.loadResource(Rez.Strings.AppLabel);
        var params = [targetMinutes.format("%d"), targetSeconds.format("%02d"), targetDistance.format("%.1f")];
        label = Lang.format(format, params);

        _targetTime = targetMinutes * 60 + targetSeconds;
        _targetDist = targetDistance;

        _targetSMA = [];
        _targetEMA = 0.0;
        _smaMode = true;

        _doneFace = "--:--";
        _isDone = false;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {

        return targetTempo(info.elapsedTime, info.elapsedDistance, info.currentSpeed);
    }

    //! Get the target tempo necessary to reach time and distance goal,
    //! given device measured elapsed time and distance.
    //! @param deviceTime The elapsed time in milliseconds given from device
    //! @param deviceDistance The elapsed distance in meters given from device
    //! @param deviceSpeed The current speed in m/s from device
    //! @return The proposed target tempo
    private function targetTempo(deviceTime as Number or Null, deviceDistance as Float or Null, deviceSpeed as Float or Null) as String {
        var targetTempo = _doneFace;

        if (!_isDone) {
            var elapsedTime = 0.0;
            var elapsedDist = 0.0;
            var currentSpeed = 0.0;
            var isMoving = false;

            if (deviceTime != null && deviceDistance != null) {
                elapsedTime = deviceTime / 1000.0;
                elapsedDist = deviceDistance / 1000.0;
                currentSpeed = deviceSpeed;
                isMoving = true;
            }

            var remainTime = _targetTime - elapsedTime;
            var remainDist = _targetDist - elapsedDist;

            if (doDoneCheck(remainTime, remainDist)) {
                targetTempo = _doneFace;
            } else {
                var target = ema(isMoving, remainTime, remainDist);
                var minutes = Math.floor(target / 60.0);
                var seconds = Math.floor(target - minutes * 60.0); 

                // Let's display only reasonable figures
                if (minutes < 2) {
                    // targetTempo = "<2:00";
                    targetTempo = eta(remainDist, elapsedTime, currentSpeed);
                } else if (minutes >= 20) {
                    // targetTempo = ">20:00";
                    targetTempo = eta(remainDist, elapsedTime, currentSpeed);
                } else {
                    targetTempo = minutes.format("%d") + ":" + seconds.format("%02d");
                }
            }
        }

        return targetTempo;
    }

    //! Get the Exponential Moving Average over window size defined by SMA_WINDOW
    //! @param isMoving The indication that the device has started to record movement in time and space
    //! @param remainTime The time remaining of set time goal
    //! @param remainDist The distance remaining of set distance goal
    //! @return The target tempo
    private function ema(isMoving as Boolean, remainTime as Float, remainDist as Float) as Float {
        var target = remainTime / remainDist;

        // We don't want to start calculating any SMA or EMA until we have live
        // data in both elapsed time as well as elapsed distance from the device
        if (isMoving) {
            if (_smaMode) {
                _targetSMA.add(target);

                var sum = 0;
                for (var i = 0; i < _targetSMA.size(); i += 1) {
                    sum += _targetSMA[i];
                }
                target = sum / _targetSMA.size();

                if (_targetSMA.size() >= SMA_WINDOW) {
                    _targetSMA = [];
                    _targetEMA = target;
                    _smaMode = false;
                }
                
            } else {
                target = target * EMA_MULTIPLIER + _targetEMA * (1 - EMA_MULTIPLIER);
                _targetEMA = target;
            }

        }

        return target;
    }

    //! Does a done check and updates the done-flag accordingly. Also sets the done face
    //! to reflect the outcome of the session. This method is one-way, i.e. it can only
    //! set the done flag to true, never the other way around.
    //! @param remainTime The time remaining of set time goal
    //! @param remainDist The distance remaining of set distance goal
    //! @return The value of the done flag for convinience
    private function doDoneCheck(remainTime as Float, remainDist as Float) as Boolean {

        // If we are not done, then just return the current state of the done flag
        if (remainDist > 0 && remainTime > 0) {
            return _isDone;
        }

        // If there is still distance to do, but the time is out, then we are done with a sad face
        if (remainDist > 0 && remainTime <= 0) {
            _isDone = true;
            _doneFace = ":-(";
            return _isDone;
        }

        // Very slim chance that we have remain dist equal to zero (it's a float), but if so and the time 
        // has already passed zero, we are done with a sad face
        if (remainDist == 0 && remainTime < 0) {
            _isDone = true;
            _doneFace = ":-(";
            return _isDone;
        }

        // Very slim chance that we have remain dist equal to zero (it's a float), but if so and 
        // there is time left (or in fact exactly zero), we are done with a happy face
        if (remainDist == 0 && remainTime >= 0) {
            _isDone = true;
            _doneFace = ":-)";
            return _isDone;
        }

        // If all above is not true, then the only remaining situation is that we completed the distance
        // and either have time left or completed time at the same step, hence we are done with a happy face
        _isDone = true;
        _doneFace = ":-)";
        return _isDone;
    }
}

//! Returns the estimated final time prefixed with est. as a string
//! @param remainDist The distance remaining in km of set distance goal
//! @param elapsedTime The elapsed time, as given from device, in seconds
//! @param currentSpeed The current speed, as given from device, in m/s
//! @return The formatted estimated final time
function eta(remainDist as Float, elapsedTime as Float, currentSpeed as Float) as String {
    if (currentSpeed == 0) {
        return "est. --:--";
    }

    var est = remainDist * 1000.0 / currentSpeed + elapsedTime;
    var minutes = Math.floor(est / 60.0);
    var seconds = Math.floor(est - minutes * 60.0);

    return "est. " + minutes.format("%d") + ":" + seconds.format("%02d");
}
