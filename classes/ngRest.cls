@RestResource(urlMapping='/entryPoint/*')
global class ngRest {

    //we have just one entry point (RequestsHandler) because we have to provide also a custom
    //authentication in the future (open JS Library). Moreover, we wish to manage the API Version more or less dynamically.
    //Methods are defined in the interface classes of each section (e.g Interface_Portal). It means, old API Versions still needs
    //to implement the latest methods, even if they return an error.
    //Finally, the methodMapping method handles the different routes to the different classes.

    @HttpPost   global static void postReq()   {RequestsHandler();}
    @HttpGet    global static void getReq()    {RequestsHandler();}
    @HttpPut    global static void putReq()    {RequestsHandler();}

    global static void RequestsHandler() {
       // List<User> users = [Select id, email, username, CreatedDate, Date__c from user];
        //RestContext.response.responseBody = Blob.valueOf(users);
        //https://devdropboxchris-developer-edition.na14.force.com/service/apexrest/entryPoint
        Map<Object, List<Object>> test = new Map<Object, List<Object>>();
        for(Integer i=0;i<10;i++) {
            test.put('id' + i, new List<Integer>());
            test.get('id' + i).add(i);
            test.get('id' + i).add(i +1);
            test.get('id' + i).add(i + 2);
        }
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(test));
        return;
       /* String callback = RestContext.request.requestBody;
        list<String> myPath = path(RestContext.request.requestURI);
        system.debug(myPath);
        if(myPath.size() != 2) {
            //we need exactly the name of the class and of the method
            return;
        }
        

        //we build a dynamic class name based on the first part of the path.
        Type allMethods = Type.forName(myPath.get(0));
        
        String result = methodMapping(myPath.get(0), myPath.get(1));
        if(result==null) {
            result = '';
        }
        if(RestContext.response.statusCode != 200 && RestContext.response.statusCode != null) {
            //error code has been set, and it's an error code. We send back JSON so we have to 
            //add some tags.
            result = '{"error":"' + result + '"}';
        }
        RestContext.response.responseBody = Blob.valueOf(callback + '(' +  result + ')');*/
        
    }

    private static list<String> path(String path) {
        //in the get(0), we have the API Version. In the get(1), the class name and in the get(3)
        //an eventual Method Name.
        List<String> res = new List<String>();
        for(Integer i=2 ; i<path.split('/').size() ; i++) {
            res.add(path.split('/')[i]);
        }
        return res;
    }

    private static String methodMapping(String myClass, String myMethod) {
        if(RestContext.request.httpMethod == 'GET'){
            if(myClass == 'ngMainControllerDev' && myMethod == 'getAccounts'){
                return JSON.serialize(ngMainControllerDev.getAccounts());
            }
            else if(myClass == 'ngMainControllerDev' && myMethod == 'getContacts'){
                return JSON.serialize(ngMainControllerDev.getContacts());
            }
            //...
        }
        else if(RestContext.request.httpMethod == 'POST'){
            //...
        }
        else if(RestContext.request.httpMethod == 'PUT'){
            //...
        }

        RestContext.response.statusCode = 400;
        return 'Route not found';
    }

}