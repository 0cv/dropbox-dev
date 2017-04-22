@RestResource(urlMapping='/engine/*')
global class Router_REST_API {

    //we have just one entry point (RequestsHandler) because we have to provide also a custom
    //authentication in the future (open JS Library). Moreover, we wish to manage the API Version more or less dynamically.
    //Methods are defined in the interface classes of each section (e.g Interface_Portal). It means, old API Versions still needs
    //to implement the latest methods, even if they return an error.
    //Finally, the methodMapping method handles the different routes to the different classes.

    @HttpPost   global static void postReq()   {RequestsHandler();}
    @HttpGet    global static void getReq()    {RequestsHandler();}
 
 	public static void RequestsHandler() {
 		system.debug('sessionId: ' + RestContext.request.requestBody.toString());
 	}

}