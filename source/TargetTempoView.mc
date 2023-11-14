import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Application.Properties;


//! Data field that shows target tempo to reach time and distance goal
class TargetTempoView extends WatchUi.SimpleDataField {
    // The Moving Average for target tempo and speed
    private var _emaTempo as MovingAverage;
    private var _smaSpeed as MovingAverage;

    // Stores settings from properties to avoid reading them every second in the compute method
    private var _targetTime as Number;
    private var _targetDist as Number;

    // Display option for when to display ETA instead of target tempo
    private var _displayOption as Number;
    private var _etaAlternate as Number;

    // The done flag and what face to show when we are done
    private var _doneFace as String;
    private var _isDone as Boolean;

    // Initializes variables and sets the label
    function initialize() {
        SimpleDataField.initialize();

        // Load properties values
        var targetMinutes = Properties.getValue("targetMinutes");
        var targetSeconds = Properties.getValue("targetSeconds");
        _targetDist = Properties.getValue("targetDistance");
        _displayOption = Properties.getValue("displayOption");

        // Construct the label that shows current time and distance goal
        var format = Application.loadResource(Rez.Strings.AppLabel);
        var params = [targetMinutes.format("%d"), targetSeconds.format("%02d"), _targetDist.format("%.1f")];
        label = Lang.format(format, params);

        // Set target time in seconds
        _targetTime = targetMinutes * 60 + targetSeconds;

        // Changes in speed when there are much distance left makes the EAT jump very much,
        // hence we give a long moving average window to longer distances. 
        // Later it will be stepped down.
        var smaWindow = 10;
        if (_targetDist >=4.0) {
            smaWindow = 120;
        } else if (_targetDist >= 1.5) {
            smaWindow = 60;
        }
        _emaTempo = new MovingAverage(true, 10, 2.0);
        _smaSpeed = new MovingAverage(false, smaWindow, 2.0);

        _doneFace = "--:--";
        _isDone = false;
        _etaAlternate = -3;
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

            if (deviceTime != null && deviceDistance != null && deviceSpeed != null) {
                elapsedTime = deviceTime / 1000.0;
                elapsedDist = deviceDistance / 1000.0;
                currentSpeed = _smaSpeed.movingAverage(deviceSpeed);
                // System.println(deviceSpeed + " " + currentSpeed + " " + _smaSpeed.size() + " " + elapsedTime + " " + elapsedDist);
                isMoving = true;
            }

            var remainTime = _targetTime - elapsedTime;
            var remainDist = _targetDist - elapsedDist;

            shrinkSpeedMovingAverage(remainDist);

            if (doDoneCheck(remainTime, remainDist)) {
                targetTempo = _doneFace;
            } else {
                if (_displayOption == 1 && remainDist <= 1.0 || _displayOption == 3) {
                    targetTempo = eta(remainDist, elapsedTime, currentSpeed);
                } else {
                    var target = isMoving ? _emaTempo.movingAverage(remainTime / remainDist) : remainTime / remainDist;
                    var minutes = Math.floor(target / 60.0);
                    var seconds = Math.floor(target - minutes * 60.0); 

                    // Let's display only reasonable figures or alternate
                    if (minutes < 2 || minutes >= 20 || (_displayOption == 2 && _etaAlternate >= 0)) {
                        targetTempo = eta(remainDist, elapsedTime, currentSpeed);
                    } else {
                        targetTempo = minutes.format("%d") + ":" + seconds.format("%02d");
                    }

                    _etaAlternate = _etaAlternate == 2 ? -3 : _etaAlternate + 1;
                }
            }
        }

        return targetTempo;
    }

    //! Does a done check and updates the done-flag accordingly. Also sets the done face
    //! to reflect the outcome of the session. This method is one-way, i.e. it can only
    //! set the done flag to true, never the other way around.
    //! @param remainTime The time remaining of set time goal
    //! @param remainDist The distance remaining of set distance goal
    //! @return The value of the done flag for convinience
    private function doDoneCheck(remainTime as Float, remainDist as Float) as Boolean {

        if (remainDist <= 0) {
            _isDone = true;
            var finishTime = _targetTime - remainTime;

            var minutes = Math.floor(finishTime / 60.0);
            var seconds = Math.floor(finishTime - minutes * 60.0);

            _doneFace = "fin " + minutes.format("%d") + ":" + seconds.format("%02d");
        }

        return _isDone;
    }

    //! Dynamically shrinks the moving average for the speed component
    //! @param remainDist The remaining distance to govern the minimum moving average window size
    private function shrinkSpeedMovingAverage(remainDist as Float) {
        if (remainDist < 4.0 && remainDist >= 1.5) {
            _smaSpeed.shrink(60);
        } else if (remainDist < 1.5) {
            _smaSpeed.shrink(10);
        }
    }
}

//! Returns the estimated final time prefixed with est. as a string
//! @param remainDist The distance remaining in km of set distance goal
//! @param elapsedTime The elapsed time, as given from device, in seconds
//! @param currentSpeed The current speed, as given from device, in m/s
//! @return The formatted estimated final time
function eta(remainDist as Float, elapsedTime as Float, currentSpeed as Float) as String {
    if (currentSpeed == 0) {
        return "eta --:--";
    }

    var est = remainDist * 1000.0 / currentSpeed + elapsedTime;
    var minutes = Math.floor(est / 60.0);
    var seconds = Math.floor(est - minutes * 60.0);

    return "eta " + minutes.format("%d") + ":" + seconds.format("%02d");
}
