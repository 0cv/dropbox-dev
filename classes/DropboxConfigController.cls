public class DropboxConfigController {
    
    private               static Http h = new Http();
    private static HttpRequest req = new HttpRequest();
    private static HttpResponse res = new HttpResponse();
    private String oauth_consumer_key{get;set;}
    private String oauth_consumer_secret {get;set;}
    private String oauth_token{get;set;}
    private String oauth_token_secret{get;set;}
    private String newToken {get;set;}
    private String newSecret {get;set;}
    public DropboxConfig__c keys {get;set;}
    public CronTrigger CT1{get;set;}
    public CronTrigger CT2{get;set;}
    
    public DropboxConfigController() {
        oauth_consumer_key = 'd6tt72sdnll62d4';
        oauth_consumer_secret = 'mbhl3mxgy2rpu8o';  
        if(DropboxConfig__c.getOrgDefaults().RemoveScheduleId__c != null) {
            try {
                CT1 = [select CreatedDate, NextFireTime from CronTrigger where Id =: DropboxConfig__c.getOrgDefaults().RemoveScheduleId__c];
            }
            catch(exception e) {}
        }
        if(DropboxConfig__c.getOrgDefaults().ContentVersionAndCurrentFolderScheduleId__c != null) {
            try {
                CT2 = [select CreatedDate, NextFireTime from CronTrigger where Id =: DropboxConfig__c.getOrgDefaults().ContentVersionAndCurrentFolderScheduleId__c];
            }
            catch(exception e) {}
        }
    }
    
    public void DeleteSchedule24Hours() {
        if(CT2 != null) {
            try{
                System.abortjob(CT2.Id);
                CT2 = null;
            }
                catch(exception e) {
            }
        }
    }
    
    public void Reschedule24Hours() {
        DeleteSchedule24Hours();
        DropboxScheduleCleaning Schedule = new DropboxScheduleCleaning();
        Schedule.execute(null); 
        try {
            CT2 = [select CreatedDate, NextFireTime from CronTrigger where Id =: DropboxConfig__c.getOrgDefaults().ContentVersionAndCurrentFolderScheduleId__c];
        }
        catch(exception e) {}
    }
    
    public void DeleteScheduleRemove() {
        if(CT1 != null) {
            try{
                System.abortjob(CT1.Id);
                CT1 = null;
            }
                catch(exception e) {
            }
        }
    }
    
    public void RescheduleRemove() {
        DeleteScheduleRemove();
        DropboxScheduleDeleteDropbox Schedule = new DropboxScheduleDeleteDropbox();
        Schedule.execute(null);
        try {
            CT1 = [select CreatedDate, NextFireTime from CronTrigger where Id =: DropboxConfig__c.getOrgDefaults().RemoveScheduleId__c];
        }
        catch(exception e) {}
    }
    
    private void analyzeResult() {
        system.debug('body:'+res.getBody());
        list<String> auth = res.getBody()==null?null:res.getBody().split('&');
        if(auth!= null) {
            for(String s:auth) {
                list<String> Param = s.split('=');
                if(Param[0] == 'oauth_token_secret')
                    oauth_token_secret = Param[1];
                else if(Param[0] == 'oauth_token')
                    oauth_token = Param[1]; 
            }
        }
    }
    
    public PageReference save() {
        String value0 = system.currentPageReference().getParameters().get('oauth_token');
        if(value0 == null) {
            String BaseURL = 'https://api.dropbox.com/1/oauth/request_token';
            String BaseUrlEnding = 'oauth_consumer_key='+oauth_consumer_key + '&oauth_nonce='+ String.valueOf(system.currentTimeMillis()) + '&oauth_signature_method=HMAC-SHA1' + '&oauth_timestamp=' + String.valueOf(system.currentTimeMillis()/1000)+'&oauth_version=1.0';
            String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+'&'+EncodingUtil.urlEncode(BaseUrlEnding, 'UTF-8');
            system.debug('Signature2Encode:' + Signature2Encode);
            String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'))), 'UTF-8');
            BaseUrlEnding += '&oauth_signature='+ macUrl;
        
            req.setTimeout(60000);
            req.setMethod('GET');
            req.setEndPoint(BaseUrl + '?' + BaseUrlEnding);
            req.setHeader('Content-type','text/xml');
            if(!test.isRunningTest())
                res = h.send(req);
            
            analyzeResult();
        }
        
        String value = system.currentPageReference().getParameters().get('return');
        
        if(value != null && value.equals('logged'))  {
            keys = DropboxConfig__c.getOrgDefaults();
            oauth_token_secret = keys.oauth_tokensecret__c;
            oauth_token = system.currentPageReference().getParameters().get('oauth_token');
            String BaseURL = 'https://api.dropbox.com/1/oauth/access_token';
            String BaseUrlEnding = 'oauth_consumer_key='+oauth_consumer_key + '&oauth_nonce='+ String.valueOf(system.currentTimeMillis()) + '&oauth_signature_method=HMAC-SHA1' + '&oauth_timestamp=' + String.valueOf(system.currentTimeMillis()/1000)+ '&oauth_token='+ oauth_token + '&oauth_version=1.0';
            String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+'&'+EncodingUtil.urlEncode(BaseUrlEnding, 'UTF-8');
            system.debug('Signature2Encode:' + Signature2Encode);
            system.debug('the key:' + oauth_consumer_secret+'&'+oauth_token_secret);
            String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
            BaseUrlEnding += '&oauth_signature='+ macUrl;
            
            req.setTimeout(60000);
            req.setMethod('GET');
            req.setEndPoint(BaseUrl + '?' + BaseUrlEnding);  //we got authenticated, we now have a token in the parameters.
            if(!test.isRunningTest())
                res = h.send(req);
            system.debug('result:' + res.getBody());
            analyzeResult();
            delete keys;
            insert new DropboxConfig__c(oauth_token__c = oauth_token, oauth_tokensecret__c = oauth_token_secret, CurrentFolderNumber__c = '0');
        }
        keys = DropboxConfig__c.getOrgDefaults();

        return null;
    }
    
    public PageReference auth2dropboxsite() {   
        delete [Select oauth_token__c, oauth_tokensecret__c From DropboxConfig__c];
        insert new DropboxConfig__c(oauth_token__c = oauth_token, oauth_tokensecret__c = oauth_token_secret);
        PageReference pageRef = new PageReference('https://www.dropbox.com/1/oauth/authorize?oauth_token='+oauth_token+'&oauth_callback=https://'+ApexPages.currentPage().getHeaders().get('Host')+'/apex/DropboxConfigPage?return=logged');
        pageRef.setredirect(true);
        return pageRef;
    }
    

}