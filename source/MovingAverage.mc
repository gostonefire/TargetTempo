import Toybox.Lang;

//! Class providing moving average funtionality.
//! It can act both as a Simple Moving Average (SMA) or an
//! Exponential Moving Average (EMA).
class MovingAverage {
    // Theese are set and never changed during the lifetime of a MovingAverage object
    private var _exponential as Boolean;
    private var _emaMultiplier as Float;

    // The window size can be shrunken using the shrink method
    private var _windowSize as Number;

    // Moving Average variables, Simple Moving Average is allways the start of 
    // an Exponential Moving Average 
    private var _sma as Array;
    private var _ema as Float;
    private var _smaMode as Boolean;

    //! The constructor
    //! @param exponential Set to true to work in EMA mode and false for SMA
    //! @param windowSize Sets the window size for the SMA/EMA
    //! @param smoothingFactor Used in EMA mode, usually 2.0 is choosen
    function initialize(exponential as Boolean, windowSize as Number, smoothingFactor as Float) {
        _exponential = exponential;
        _windowSize = windowSize;

        _emaMultiplier = smoothingFactor / (1.0 + windowSize);
        
        // Initializes some working variables, and SMA is allways the start regardless of SMA or EMA choosen
        _sma = [];
        _ema = 0.0;
        _smaMode = true;
    }

    //! Get the Moving Average value given some input
    //! @param value The value to add to the running moving average
    //! @return The moving average output
    function movingAverage(value as Float) as Float {

        if (_smaMode) {
            if (_sma.size() >= _windowSize) {
                _sma.remove(_sma[0]);
            }
            _sma.add(value);

            var sum = 0;
            for (var i = 0; i < _sma.size(); i += 1) {
                sum += _sma[i];
            }
            value = sum / _sma.size();

            if (_sma.size() >= _windowSize && _exponential) {
                _sma = [];
                _ema = value;
                _smaMode = false;
            }
            
        } else {
            value = value * _emaMultiplier + _ema * (1 - _emaMultiplier);
            _ema = value;
        }

        return value;
    }

    //! Shrinks the window size by one and removes the oldest value from the 
    //! buffer. Smallest window size allowed is 1. 
    //! This will only affect a Simple Moving Average.
    //! @param minSize The minimum window size to step down to
    //! @return The new (or unchanged) window size
    function shrink(minSize as Number) as Number {
        if (_windowSize > 1 && _windowSize > minSize && !_exponential) {
            if (_sma.size() >= _windowSize) {
                _sma.remove(_sma[0]);
            }
            _windowSize -= 1;
        }

        return _windowSize;
    }

    //! Get the size of the Simple Moving Average buffer array.
    //! The buffer is emptied once the MA mode goes over to EMA (if exponential is true).
    function size() as Number {
        return _sma.size();
    }
}