global with sharing class DropboxShareFolder {
    private static map<String,String> keyPrefixMap = new Map<String,String>{};
    public static String AlertMessage {get;set;}
    public static String Text2Copy {get;set;}
    public static String Text2Display {get;set;}
    
    webservice static String init(String URL) {
        keyFieldMapping();
        String FieldId = URL.split('force.com/')[1].substring(0,15);
        system.debug('test:' + FieldId);
        if(FieldId.length() == 15) {
            String FieldName = keyPrefixMap.get(FieldId.substring(0,3));
            if(!FieldName.endsWith('__c'))
               FieldName += '__c';
            String Query = 'select URL__c from Dropbox__c where ' + FieldName + ' = \'' + FieldId + '\' limit 1';
            Dropbox__c Dropboxx;
            try {
               Dropboxx = (Dropbox__c)Database.query(query);
            }
            catch(Exception e) {
                return 'Folder not found';
            }
            String URLHelp = '';
            if(Dropboxx.get('URL__c') != null) {
                URLHelp = String.valueOf(Dropboxx.get('URL__c'));
                URLHelp = URLHelp.substring(0, URLHelp.lastIndexOf('/'));
            }
           // return URLHelp;
            DropboxPopup DP = new DropboxPopup();
            DP.URLFromDoc = URLHelp;
            DP.GetShareableLink();
            AlertMessage = DP.AlertMessage;
            Text2Copy = DP.Text2Copy;
            Text2Display = DP.Text2Display;
             //return URLHelp;
        }
        return Text2Display + ' $$ ' + Text2Copy ;
    }
    
    private static void keyFieldMapping() {
        map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
                Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
                if(r.getKeyPrefix() != null)
                  keyPrefixMap.put(r.getKeyPrefix(),r.getName());  
        }
    }
    

}