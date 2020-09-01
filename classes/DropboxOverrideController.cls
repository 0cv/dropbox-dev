public class DropboxOverrideController {
    
    public static Dropbox__c Db;
    public boolean isDocument = false;
    private HttpRequest req = new HttpRequest();
    private HttpResponse res = new HttpResponse();
    
    public DropboxOverrideController (ApexPages.StandardController controller){ 
        if(controller != null) {
            Db = (Dropbox__c) controller.getRecord();
            system.debug('the result:' + Db);
            Db = [select id, Name__c, URL__c from Dropbox__c where Id =: Db.Id];
        }
    }
    
    public  String doJob() {
    //    String BaseFolder = 'Apps/salesforce/' + UserInfo.getOrganizationId() + '/' + DropboxConfig__c.getOrgDefaults().CurrentFolderNumber__c + '/';
        system.debug('dropboxURL:' + Db.URL__c);
        if(Db.URL__c != null && Db.URL__c.contains('https://www.dropbox.com/0/links/')) {
        //////  
            String FileName = Db.URL__c.substring(Db.URL__c.lastIndexOf('/')+1);
             String Folder = UserInfo.getOrganizationId() + '/' + Db.URL__c.split(UserInfo.getOrganizationId() + '/')[1];
             Folder = Folder.substring(0, Folder.lastIndexOf('/') + 1);
        /////
     //       String FileName =  Dropbox.URL__c.split('https://www.dropbox.com/0/links/' +BaseFolder)[1]; 
       //     String Folder = FileName.substring(0, FileName.indexOf('/')+1);
        //    FileName = FileName.substring(FileName.indexOf('/') + 1);
            
            doRequest(FileName, Folder);
  
            if(res != null && res.getBody() != null) {
                if(!res.getBody().contains('{"error":')) {              
                    DropboxPopup DP = new DropboxPopup();
                    String result =  DP.CheckEmptyFolder(/*(isDocument?'':UserInfo.getOrganizationId() + '/' + DropboxConfig__c.getOrgDefaults().CurrentFolderNumber__c + '/') + */ Folder, null); 
                    system.debug('resultFolder:' + result);
                    if(result.contains('"contents": []')) {
                        //we have to delete the folder
                        doRequest(null, Folder);
                    }
                    delete Db; 
                    return 'ok';
                }
                else if(res.getBody().contains(' not found"}')) {
                    delete Db;
                    return res.getBody();
                }
                else
                    return res.getBody();
            }  
       }
       else {
           try {
            delete Db;
           }
           catch(exception e){}
       }
           
       return 'wrong link';
    }
    
    public String doRequest(String FileName, String Folder) {
        req.setTimeout(60000); 
        req.setMethod('GET');
        Http h = new Http();
        String BaseUrl = 'https://api.dropbox.com/1/fileops/delete';
        String oauth_consumer_key = 'd6tt72sdnll62d4';
        String oauth_consumer_secret = 'mbhl3mxgy2rpu8o'; 
        String oauth_token;
        String oauth_token_secret;    
        String BaseUrlEnding = '';
            
        DropboxConfig__c dc = DropboxConfig__c.getOrgDefaults(); 
        oauth_token = dc.oauth_token__c;
        oauth_token_secret = dc.oauth_tokensecret__c;
      
        BaseUrlEnding+= 'oauth_consumer_key='+ oauth_consumer_key;
        BaseUrlEnding+= '&oauth_nonce='+ String.valueOf(system.currentTimeMillis());
        BaseUrlEnding+= '&oauth_signature_method=HMAC-SHA1';
        BaseUrlEnding+= '&oauth_timestamp='+ String.valueOf(system.currentTimeMillis()/1000);
        BaseUrlEnding+= '&oauth_token='+ oauth_token;
        BaseUrlEnding+= '&oauth_version=1.0'; 

        BaseUrlEnding+= '&path=' + /*(isDocument?'':UserInfo.getOrganizationId() + '%2F' + DropboxConfig__c.getOrgDefaults().CurrentFolderNumber__c + '%2F') +*/ (Folder!=null?Folder.replaceAll('/','%2F'):'');
            // + FileName.replace('/','%2F').replace(' ', '%20');
        String BaseUrlEndingEnding = '&root=sandbox';
            
        String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+'&'+EncodingUtil.urlEncode(BaseUrlEnding, 'UTF-8') + (FileName!=null?EncodingUtil.urlEncode(FileName, 'UTF-8').replaceAll('\\+', '%20').replaceAll('%', '%25'):'') + EncodingUtil.urlEncode(BaseUrlEndingEnding, 'UTF-8');
        system.debug('Signature2Encode:' + Signature2Encode);
        String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
        
        BaseUrlEndingEnding += '&oauth_signature='+ macUrl;
        req.setEndPoint(BaseUrl + '?' + BaseUrlEnding + (FileName!=null?EncodingUtil.urlEncode(FileName, 'UTF-8').replaceAll('\\+', '%20'):'') + BaseUrlEndingEnding);
          
        res = h.send(req);
        system.debug('result:' + res.getBody()); 
        return res.getBody();
    }
    
    public PageReference redirectAfterDelete() {    
        doJob();
        PageReference PR = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        return PR;
    }
    

}