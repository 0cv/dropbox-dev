({
   getObject : function(component, event) {
       console.log('fetching...')
      
        var action = component.get("c.get");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var user = response.getReturnValue();
                console.log('test user:', user.FirstName )
                component.set("v.user", user); 
                $A.createComponent("force:inputField",{
                    "label" : 'My Field',
                    "value" : user.FirstName
                    },
                    function(newcmp ){
                        if (component.isValid()) {
                            console.log('cmp is valid');
                            var body = component.get("v.body");
                            body.push(newcmp);
     						console.log('body', body)
                            component.set("v.body", body);
                        }
                    }
                );
            }
        });
        $A.enqueueAction(action);
    } 
})