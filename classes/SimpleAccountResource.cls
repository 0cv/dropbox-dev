@RestResource(urlMapping='/simpleAccount/*')
  global with sharing class SimpleAccountResource {
      static String getIdFromURI() {
          RestRequest req = RestContext.request;
          return req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
      }
      
      @HttpGet global static Map<String, String> doGet() {
          String id = getIdFromURI();
          Account acc = [select Id, Name from Account 
                         where Id = :id];
          return new Map<String, String>{
              'accountId'=>acc.Id, 'accountName'=>acc.Name};
      }
  
      @HttpPost global static Map<String, String> doPost(String accountName) {
              Account acc = new Account(Name=accountName);
              insert acc;
              return new Map<String, String>{'id'=>acc.Id, 'Name'=>accountName};
      }
  
      @HttpPatch global static Map<String, String> 
          doPatch(String accountName) {
              String id = getIdFromURI();
              Account acc = [select Id from Account where Id = :id];
              acc.Name = accountName;
              update acc;
              return new Map<String, String>{
                  'accountId'=>acc.Id, 'accountName'=>acc.Name};
      }
  
      @HttpDelete global static void doDelete() {
          String id = getIdFromURI();
          Account acc = [select Id from Account where Id = :id];
          delete acc;
          RestContext.response.statusCode = 204;
      }
  }