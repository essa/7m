

(function(){
  var cordovaRef = window.PhoneGap || window.Cordova || window.cordova; // old to new fallbacks
  var utils = cordova.require('cordova/utils');
  var argscheck = cordova.require('cordova/argscheck');
  var mediaObjects = {};

/**
 * This class provides access to the device media, interfaces to both sound and video
 *
 * @constructor
 * @param src                   The file name or url to play
 * @param successCallback       The callback to be called when the file is done playing or recording.
 *                                  successCallback()
 * @param errorCallback         The callback to be called if there is an error.
 *                                  errorCallback(int errorCode) - OPTIONAL
 * @param statusCallback        The callback to be called when media status has changed.
 *                                  statusCallback(int statusCode) - OPTIONAL
 * @param commandCallback        The callback to be called when command event was occured.
 *                                  commandCallback(int mstType, int statusCode) - OPTIONAL
 */
var StreamAudio = function(src, successCallback, errorCallback, statusCallback, commandCallback) {
    console.log('StreamAudio constructor');
    argscheck.checkArgs('SFFF', 'StreamAudio', arguments);
    this.id = utils.createUUID();
    mediaObjects[this.id] = this;
    this.src = src;
    this.successCallback = successCallback;
    this.errorCallback = errorCallback;
    this.statusCallback = statusCallback;
    this.commandCallback = commandCallback;
    this._duration = -1;
    this._position = -1;
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "create", [this.id, this.src]);
};

// StreamAudio messages
StreamAudio.MEDIA_STATE = 1;
StreamAudio.MEDIA_DURATION = 2;
StreamAudio.MEDIA_POSITION = 3;
StreamAudio.MEDIA_COMMAND = 4;
StreamAudio.MEDIA_ERROR = 9;

// StreamAudio states
StreamAudio.MEDIA_NONE = 0;
StreamAudio.MEDIA_STARTING = 1;
StreamAudio.MEDIA_RUNNING = 2;
StreamAudio.MEDIA_PAUSED = 3;
StreamAudio.MEDIA_STOPPED = 4;
StreamAudio.MEDIA_BEGININTERACTION = 5;
StreamAudio.MEDIA_ENDINTERACTION = 6;
StreamAudio.MEDIA_INPUTCHANGED = 7;
StreamAudio.MEDIA_REMOTECONTROL = 8;
StreamAudio.MEDIA_MSG = ["None", "Starting", "Running", "Paused", "Stopped"];

// "static" function to return existing objs.
StreamAudio.get = function(id) {
    return mediaObjects[id];
};

/**
 * Start or resume playing audio file.
 */
StreamAudio.prototype.play = function(options) {
    cordovaRef.exec(null, null, "StreamAudio", "startPlayingAudio", [this.id, this.src, options]);
};

/**
 * Stop playing audio file.
 */
StreamAudio.prototype.stop = function() {
    var me = this;
    cordovaRef.exec(function() {
        me._position = 0;
    }, this.errorCallback, "StreamAudio", "stopPlayingAudio", [this.id]);
};

/**
 * Seek or jump to a new time in the track..
 */
StreamAudio.prototype.seekTo = function(milliseconds) {
  if (isNaN(milliseconds)) {
    milliseconds = 0;
  }
  if (milliseconds == 0) {
    milliseconds = 1;
  }
  console.log("JS seekTo", milliseconds)
    var me = this;
    cordovaRef.exec(function(p) {
        me._position = p;
    }, this.errorCallback, "StreamAudio", "seekToAudio", [this.id, milliseconds]);
};

/**
 * Pause playing audio file.
 */
StreamAudio.prototype.pause = function() {
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "pausePlayingAudio", [this.id]);
};


StreamAudio.prototype.continue = function() {
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "continuePlayingAudio", [this.id]);
};


/**
 * Get duration of an audio file.
 * The duration is only set for audio that is playing, paused or stopped.
 *
 * @return      duration or -1 if not known.
 */
StreamAudio.prototype.getDuration = function() {
    return this._duration;
};

/**
 * Get position of audio.
 */
/*
StreamAudio.prototype.getCurrentPosition = function(success, fail) {
    var me = this;
    cordovaRef.exec(function(p) {
        me._position = p;
        success(p);
    }, fail, "StreamAudio", "getCurrentPositionAudio", [this.id]);
};
*/

StreamAudio.prototype.getCurrentPosition = function(success, fail) {
  var me = this;
  // me._position will be set by onStatus
  success(me._position);
};

/**
 * Start recording audio file.
 */
StreamAudio.prototype.startRecord = function() {
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "startRecordingAudio", [this.id, this.src]);
};

/**
 * Stop recording audio file.
 */
StreamAudio.prototype.stopRecord = function() {
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "stopRecordingAudio", [this.id]);
};

/**
 * Release the resources.
 */
StreamAudio.prototype.release = function() {
    cordovaRef.exec(null, this.errorCallback, "StreamAudio", "release", [this.id]);
};

/**
 * Adjust the volume.
 */
StreamAudio.prototype.setVolume = function(volume) {
    cordovaRef.exec(null, null, "StreamAudio", "setVolume", [this.id, volume]);
};

/**
 * Audio has status update.
 * PRIVATE
 *
 * @param id            The media object id (string)
 * @param msgType       The 'type' of update this is
 * @param value         Use of value is determined by the msgType
 */
StreamAudio.onStatus = function(id, msgType, value, subType) {

    var media = mediaObjects[id];

    if (msgType != StreamAudio.MEDIA_POSITION) {
       console.log("onStatus", msgType, value);
    }

    if(media) {
        switch(msgType) {
            case StreamAudio.MEDIA_STATE :
                media.statusCallback && media.statusCallback(value);
                if(value == StreamAudio.MEDIA_STOPPED) {
                  console.log("calling successCallback()");
                  media.successCallback && media.successCallback();
                }
                break;
            case StreamAudio.MEDIA_DURATION :
                media._duration = value;
                break;
            case StreamAudio.MEDIA_ERROR :
                media.errorCallback && media.errorCallback(value);
                break;
            case StreamAudio.MEDIA_POSITION :
                media._position = Number(value);
                break;
            case StreamAudio.MEDIA_COMMAND:
                console.error && console.error("StreamAudio.onStatus :: " + msgType + value + subType);
                media.commandCallback && media.commandCallback(value, subType);
                break;
            default :
                console.error && console.error("Unhandled StreamAudio.onStatus :: " + msgType);
                break;
        }
    }
    else {
         console.error && console.error("Received StreamAudio.onStatus callback for unknown media :: " + id);
    }

};


	cordovaRef.addConstructor(function(){
		if(!window.plugins)
		{
			window.plugins = {};
		}
		window.plugins.StreamAudio = StreamAudio;
	});
})();
