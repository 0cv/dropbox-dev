({
	toggle: function(component) {
		var msgElem = component.find('message');
		$A.util.toggleClass(msgElem, 'slds-hide');

		$A.log('!!msgElem1!!', msgElem);
		// $A.warning('!!msgElem4!!', msgElem);
		// $A.error('!!msgElem2!!', msgElem);
	},
	buttonDown: function(component) {
		this.toggle(...arguments);
		var audioElem = component.find('audioclip').getElement();
		audioElem.play();
	},
	buttonUp: function(component) {
		this.toggle(...arguments);
		var audioElem = component.find('audioclip').getElement();
		audioElem.pause();
		audioElem.currentTime = 0;
	},
	setSound: function(component, mediaUrl) {
		component.set('v.audioFilePath', mediaUrl);
	},
	callServer: function(component, method, callback, params, cacheable) {
		var action = component.get(method);
		if (params) {
			action.setParams(params);
		}
		if (cacheable) {
			action.setStorable();
		}
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				// pass returned value to callback function
				callback.call(this, response.getReturnValue());
			}
			else if (state === "ERROR") {
				// generic error handler
				var errors = response.getError();
				if (errors) {
					$A.logf("Errors", errors);
					if (errors[0] && errors[0].message) {
						throw new Error("Error" + errors[0].message);
					}
				}
				else {
					throw new Error("Unknown Error");
				}
			}
		});

		$A.enqueueAction(action);
	}

})