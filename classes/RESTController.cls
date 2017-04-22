@RestResource(urlMapping='/test/*')
global class RESTController {

@HttpGet  
  global static String createNewCase() {
     
          
     return 'test';
  }
}