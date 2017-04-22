({
	handleClick : function(component, event, helper) {
		var domElem = component.find('audioclip').getElement();
        domElem.play();
        helper.buttonDown(component);
	},
    onPlaybackEnded: function(component, event, helper) {
        helper.buttonUp(component);
    },
    doInit: function(component, event, helper) {

        var defaultSound = component.get('v.sound');
        console.log('v.sound=>', defaultSound);
        helper.callServer(component, 'c.getMedia', callback);

        function callback(response) {
            var opts = [];
            for(var opt of response) {
                if(opt.label === defaultSound) {
                    opt.selected = true;
                    helper.setSound(component, it.value);
                }
                opts.push({
                    label: opt.Name,
                    value: opt.url__c
                });
            }
            component.find('soundSelector').set('v.options', opts);
        }

    },
    handleChange: function(component, event, helper) {
        var soundUrl = component.find('soundSelector').get('v.value');
        helper.setSound(component, soundUrl);
    }
})