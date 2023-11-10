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
        label = Application.loadResource(Rez.Strings.AppLabel);
        
        _targetSMA = [];
        _targetEMA = 0.0;
        _smaMode = true;

        _targetTime = Properties.getValue("targetTime") * 60;
        _targetDist = Properties.getValue("targetDistance");

        _doneFace = "--:--";
        _isDone = false;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {

        return targetTempo(info.elapsedTime, info.elapsedDistance);
    }

    //! Get the target tempo necessary to reach time and distance goal,
    //! given device measured elapsed time and distance.
    //! @param deviceTime The elapsed time in milliseconds given from device
    //! @param deviceDistance The elapsed distance in meters given from device
    //! @return The proposed target tempo
    private function targetTempo(deviceTime as Number or Null, deviceDistance as Float or Null) as String {
        var targetTempo = _doneFace;

        if (!_isDone) {
            var elapsedTime = 0.0;
            var elapsedDist = 0.0;
            var isMoving = false;

            if (deviceTime != null && deviceDistance != null) {
                elapsedTime = deviceTime / 1000.0;
                elapsedDist = deviceDistance / 1000.0;
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
                    targetTempo = "<2:00";
                } else if (minutes >= 20) {
                    targetTempo = ">20:00";
                } else {
                    targetTempo = minutes.format("%2d") + ":" + seconds.format("%02d");
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
        System.print("Remain time: " + remainTime / 60 + " Remain dist: " + remainDist + " Raw target: " + target);
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
        System.println(" Calc target: " + target);

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

