public class DropboxPopup { 
    public static boolean deactivateFolderNumber = false;
    static private Http h = new Http();
    static private HttpRequest req = new HttpRequest();
    static private HttpResponse res = new HttpResponse();
    private static String oauth_consumer_key = 'd6tt72sdnll62d4';
    private static String oauth_consumer_secret = 'mbhl3mxgy2rpu8o';
    private static String oauth_token = DropboxConfig__c.getOrgDefaults().oauth_token__c;
    private static String oauth_token_secret = DropboxConfig__c.getOrgDefaults().oauth_tokensecret__c;
    private map<String,String> keyPrefixMap = new Map<String,String>{};
    private string Field;
    private static string CurrentFolderNumber = DropboxConfig__c.getOrgDefaults().CurrentFolderNumber__c;
    private String BaseFolder = 'Apps/salesforce/' + UserInfo.getOrganizationId() + '/' + CurrentFolderNumber + '/';
    private String FileType {get;set;}
    private final Id FieldId {get;set;}
    private Blob filebody {get;set;}
    private list<Dropbox__c> Dropboxes ;
    
    public static String myFolder {
        get ;
        set;
    }
    public String AlertMessage {get;set;}
    public static String urlEndPoint {get;set;}
    public static Boolean hasMessages {get;set;}
    public Boolean isLogged {get;set;}
    public static String FileName {get;set;}
    public String SessionId {get;set;}
    public String FileAttachIds{get;set;}
    public String FileNames{get;set;}
    public String URLs{get;set;}
    public String PrefixOrg {get;set;}
    public Integer totalNumber {get;set;}
    public String Sources {get;set;}
    public String Text2Display{get;set;}
    public String Text2Copy{get;set;}
    public String URLFromDoc = '';
    
    public class ShareableLink {
        public String error;
        public String url;
        public String expires;
    }
    
    
    public class metadataFolderList {
        public String hash;
        public Integer revision;
        public String rev;
        public boolean thumb_exists;
        public Long bytes;
        public String modified;
        public String path;
        public boolean is_dir;
        public String icon;
        public String root;
        public list<metadata> contents;
        public String size;
    }
    public class metadataList {
        public list<metadata> metadata;
    }
    
    public class Metadata {
        public Integer revision {get;set;}
        public String rev {get;set;}
        public boolean thumb_exists {get;set;}
        public Long bytes {get;set;}
        public String modified {get;set;} 
        public String path {get;set;}
        public boolean is_dir {get;set;}
        public String icon {get;set;}
        public String root {get;set;}
        public String mime_type {get;set;}
        public String size {get;set;}
        public String error {get;set;}
        public boolean is_deleted {get;set;}
        public String client_mtime {get;set;}
    }
    
    private static String getMyFolder() {
        try {
           Id test = ApexPages.currentPage().getParameters().get('url').split('force.com/')[1].substring(0,15);
           return test;
        }
        catch(exception e) {}
        return 'error';
    }
    
    public DropboxPopup() {
        SessionId  = UserInfo.getSessionId();  
        keyFieldMapping();
        hasMessages = true;
        oauth_token = null;
        oauth_token_secret = null;
     //   for(String s:ApexPages.currentPage().getHeaders().keySet()) {
    //      system.debug('String:' +  s + '--' + ApexPages.currentPage().getHeaders().get(s));
     //   }
        
        if(ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().get('url') != null) {
            try {
            //    Id test = ApexPages.currentPage().getParameters().get('url').split('force.com/')[1].substring(0,15);
                FieldId = getMyFolder();
                Field = !keyPrefixMap.get(String.valueOf(FieldId).substring(0,3)).contains('__c')?(keyPrefixMap.get(String.valueOf(FieldId).substring(0,3)) + '__c'):keyPrefixMap.get(String.valueOf(FieldId).substring(0,3));
            }
            catch(exception e){}
        }
        system.debug('FieldId:' + FieldId);

    //    isLogged = false;


        
        myFolder = FieldId;
        
        DropboxConfig__c dc = DropboxConfig__c.getOrgDefaults();
        oauth_token = dc.oauth_token__c;
        oauth_token_secret = dc.oauth_tokensecret__c;

        urlEndPoint = '';
       // if(oauth_token != null && oauth_token_secret != null)
            isLogged = true;
    }
   
    public void GetShareableLink(){
        String theURL;
        if(URLFromDoc == '')
           theURL = ApexPages.currentPage().getParameters().get('theURL');
        else
           theURL = URLFromDoc;
        String URL = URLGeneration(theURL, 'shares', null);
        if(URL != null) {
            req.setEndPoint(URL);
            req.setMethod('GET');
            if(!test.isRunningTest())
                res = h.send(req);
         
           system.debug('resBody:' + res.getBody());
            ShareableLink metaObj = new ShareableLink();
            Type wrapperType = Type.forName('DropboxPopup.ShareableLink'); 
            if(!test.isRunningTest())
               metaObj = (DropboxPopup.ShareableLink)JSON.deserialize(res.getBody(), wrapperType);
            system.debug('metaObj:' + metaObj);
            AlertMessage = '';
            Text2Copy = metaObj.url;
            Text2Display = metaObj.expires;
        }
        else {
            AlertMessage = 'File not found!';
        }
    }
    
    private void keyFieldMapping() {
        map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
                Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
                if(r.getKeyPrefix() != null)
                  keyPrefixMap.put(r.getKeyPrefix(),r.getName());  
        }
    }
    
    public map<Integer, list<String>> getFile4Email(list<Dropbox__c> Dropboxes) {
        map<Integer, list<String>> returnValues = new map<Integer, list<String>>();
        if(Dropboxes == null)
            return null;
        list<String> Helper;
        Integer i = 0;
        String test = '';
        for(Dropbox__c Drop:Dropboxes) {
            Helper = new list<String>();
            Helper.add(getFileName(Drop.URL__c));
            Helper.add(test=URLGeneration(Drop.URL__c, 'files', null));
            Helper.add(Drop.Id);
            returnValues.put(i, Helper);
            i++;
            system.debug('URL GENerated:' + test);
        }
        return returnValues;
    }
    public String getFileName(string theURL) {
        system.debug('base:'+BaseFolder);
        return theURL!=null?theURL.substring(theURL.lastIndexOf('/')+1):'';
    }
    
    public void DeleteIt() {
        String theId = ApexPages.currentPage().getParameters().get('theId');
        system.debug('test:' + theId );
        ApexPages.StandardController controller =  new ApexPages.StandardController([select id from Dropbox__c where Id =: theId limit 1]);
        DropboxOverrideController OC = new DropboxOverrideController (controller);
        String result = OC.doJob(); 
        if(result == 'ok')  {
            //do nothing
        }
        else if(result == 'wrong link') {
            AlertMessage = 'Problem with the link, please synchronize the record.';
        }
        else {
            AlertMessage = result;
        }
        getDropboxes();
    }
    
    public String URLGeneration(String theURL, String type, String ParamRevLimit) {
        String File = getFileName(theURL);
        system.debug('my file: ' + File); 
        //String Path = theURL.split('https://www.dropbox.com/0/links/' + BaseFolder)[1];
        //myFolder = UserInfo.getOrganizationId() + '/' + CurrentFolderNumber + '/' + Path.substring(0,Path.lastIndexOf('/')+1);
        myFolder = UserInfo.getOrganizationId() + '/' + (theURL!=null?theURL.split(UserInfo.getOrganizationId() + '/')[1]:'');
        myFolder = myFolder.substring(0, myFolder.lastIndexOf('/') + 1);
        
        CheckFileExist(myFolder, File);
        
        if(!test.isRunningTest()) {
            if(res.getBody() == null || res.getBody().contains('{"error":') ) {
                    AlertMessage = 'This file does not exists';
                    return null;
            }
            if(res != null && res.getBody().contains('"is_deleted": true')) {
                AlertMessage = 'This file has been deleted';
                    return null;
            }
        }
        String BaseUrl = 'https://api'+(type=='files'?'-content':'')+'.dropbox.com/1/'+type+'/sandbox/' ;
        String BaseUrlEnding = ''; 
        BaseUrlEnding+= 'oauth_consumer_key='+ oauth_consumer_key;
        BaseUrlEnding+= '&oauth_nonce='+ String.valueOf(system.currentTimeMillis());
        BaseUrlEnding+= '&oauth_signature_method='+ 'HMAC-SHA1';
        BaseUrlEnding+= '&oauth_timestamp='+ String.valueOf(system.currentTimeMillis()/1000);
        BaseUrlEnding+= '&oauth_token='+ oauth_token;
        BaseUrlEnding+= '&oauth_version='+ '1.0';
        BaseUrlEnding+= (ParamRevLimit!=null?ParamRevLimit:'');
        

        String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+EncodingUtil.urlEncode(myFolder, 'UTF-8')+EncodingUtil.urlEncode(File, 'UTF-8').replaceAll('\\+', '%20').replaceAll('%', '%25')+'&'+EncodingUtil.urlEncode(BaseUrlEnding.replaceAll('/', '%2F'), 'UTF-8');
        system.debug('signature:' + Signature2Encode);
        String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
        BaseUrlEnding += '&oauth_signature='+ macUrl;
        return BaseUrl + myFolder + (EncodingUtil.urlEncode(File, 'UTF-8')).replaceAll('\\+', '%20') + '?' +BaseUrlEnding;
    }
    
    public PageReference getFile() {
        AlertMessage = '';
        
        String theURL = ApexPages.currentPage().getParameters().get('theURL');
    //  system.debug('theURL:' + theURL);
        if(theURL != null) {
                String URL =  URLGeneration(theURL, 'files', null);
                if(URL == null)
                    return null;
                PageReference PR = new PageReference(URL);
                
                PR.setRedirect(true);  
                system.debug('download url:' + PR.getURL());
                return PR;
        }
        return null;
    }
    
    public void DataTransfer() {
        //String Sources = ApexPages.currentPage().getParameters().get('Sources');
        system.debug('sources:' + Sources);
        metadataList metaObj = new metadataList();
        Type wrapperType = Type.forName('DropboxPopup.metadataList'); 
        if(!Test.isRunningTest())
            metaObj = (DropboxPopup.metadataList)JSON.deserialize(Sources, wrapperType);
        
        list<String> Paths = new list<String>();
        if(metaObj.metadata != null) {
            for(metadata meta:metaObj.metadata) {
                Paths.add(meta.path);
            }
        }
        map<String, Dropbox__c> ExistingDropboxes = new map<String, Dropbox__c>();
        for(Dropbox__c drop:[select id, Path__c from Dropbox__c where Path__c IN: Paths]) {
            ExistingDropboxes.put(drop.Path__c, drop);
        }
        list<sObject> DropboxList = new list<Dropbox__c>();
        sObject Dropboxx;
        String FolderId = ApexPages.currentPage().getParameters().get('url').split('force.com/')[1].substring(0,15);
        String FieldAPIName = keyPrefixMap.get(String.valueOf(FolderId).substring(0,3));
        if(!FieldAPIName.endsWith('__c'))
            FieldAPIName += '__c';
        if(metaObj.metadata != null) {
            for(metadata meta:metaObj.metadata) {
                if(!ExistingDropboxes.containsKey(meta.path)) {
                    //we have to create a new row
                    Dropboxx = new Dropbox__c();
                    Dropboxx.put('URL__c', 'https://www.dropbox.com/0/links/Apps/salesforce'  + meta.path);
                    Dropboxx.put('Name__c', meta.path.substring(meta.path.lastIndexOf('/') + 1));
                    Dropboxx.put(FieldAPIName, FolderId);
                    DropboxList.add(Dropboxx);
                }
            }
        }
        if(!DropboxList.isEmpty())
            insert DropboxList;
        //system.debug('metaObj:' + metaObj);
    }   
        
    @RemoteAction
    public static String getEncryptedURLs4Applet(string fns, String FolderId) {
        
        list<String> fileNames = fns.split('/');
        String URLs = '';
        
        
        //if(FieldId != null) {
            try {
                myFolder = FolderId;
                 
                system.debug('myFolder:' + myFolder);

                for(String s:fileNames) {
                    FileName = s;
                    UploadIt();
                    URLs += urlEndPoint + ' ';
                }
                system.debug('URLS: ' + URLs);
                return URLs;
            }
            catch(exception e){}
      //  }
        return '';
        
    }
   
    public PageReference UploadThemAll() {
        PrefixOrg =  ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');

        myFolder = FieldId;
        FileAttachIds = '';
        URLs = '';
        FileNames = ''; 
        totalNumber = 0;
        for(Attachment att:[select Id, Name from Attachment where ParentId=:FieldId ]){
            FileAttachIds += att.Id + ',';
            FileNames += att.Name + '/';
            FileName = att.Name;
            UploadIt();
            URLs += urlEndPoint + ' ';
            totalNumber ++;
        }
        system.debug('URLs:' + URLs);
        system.debug('FileAttachIds:' + FileAttachIds);
        system.debug('FileNames:' + FileNames);
        return null;
    }   
    
    public static PageReference UploadIt() {
        
        hasMessages = false;
        String BaseUrl = 'https://api-content.dropbox.com/1/files/sandbox/';
        String BaseUrlEnding = '';    
        String File = 'file=';    
        BaseUrlEnding+= '&oauth_consumer_key='+ oauth_consumer_key;
        BaseUrlEnding+= '&oauth_nonce='+ String.valueOf(system.currentTimeMillis());
        BaseUrlEnding+= '&oauth_signature_method='+ 'HMAC-SHA1';
        BaseUrlEnding+= '&oauth_timestamp='+ String.valueOf(system.currentTimeMillis()/1000);
        BaseUrlEnding+= '&oauth_token='+ oauth_token;
        BaseUrlEnding+= '&oauth_version='+ '1.0';
        BaseUrlEnding+= '&path='+ UserInfo.getOrganizationId() + '/' + (deactivateFolderNumber?'':CurrentFolderNumber + '/') + (myFolder==null?getMyFolder():myFolder); 
        system.debug('baseUrlEnding:'+BaseUrlEnding);
        String Signature2Encode = 'POST&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+'&'+EncodingUtil.urlEncode(File, 'UTF-8') + ((EncodingUtil.urlEncode(FileName, 'UTF-8')).replaceAll('\\+', '%20').replaceAll('%7E', '~').replaceAll('%', '%25')) + EncodingUtil.urlEncode(BaseUrlEnding.replace('/', '%2F'), 'UTF-8');
        system.debug('Signature2Encode:'+Signature2Encode);
        String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
        BaseUrlEnding += '&oauth_signature='+ macUrl;
        
        urlEndPoint = BaseUrl + '?' + File + (EncodingUtil.urlEncode(FileName, 'UTF-8')) + BaseUrlEnding;
        system.debug('my url endpoint: '+ urlEndPoint);
        system.debug('my folder: ' + (myFolder==null?getMyFolder():myFolder));
            return null;
    }
    
    public list<Dropbox__c> getDropboxes() {
        if(FieldId == null)
            return null;
        String query = 'select id, URL__c, Name__c from Dropbox__c where ' + Field + ' =: FieldId';
        return Database.query(query);
    }
    /*
    public void checkBigMetadata() {
        String Folder = '00DU0000000HRPfMAO';
        CheckFileExist(Folder, null); 
    }*/
    
    public String CheckEmptyFolder(String Folder, String FN) {
        return CheckFileExist(Folder, FN);
    } 
    
    private String CheckFileExist(string Folder, String FN) {
        system.debug('Folder:' + Folder);
        system.debug('my folder:' + myFolder);  
        system.debug('FileName:' + FN);
        req.setTimeout(60000);
        req.setMethod('GET');
        String BaseUrl = 'https://api.dropbox.com/1/metadata/sandbox/';
        String BaseUrlEnding = '';  
      
        BaseUrlEnding+= 'oauth_consumer_key='+ oauth_consumer_key;
        BaseUrlEnding+= '&oauth_nonce='+ String.valueOf(system.currentTimeMillis());
        BaseUrlEnding+= '&oauth_signature_method='+ 'HMAC-SHA1';
        BaseUrlEnding+= '&oauth_timestamp='+ String.valueOf(system.currentTimeMillis()/1000);
        BaseUrlEnding+= '&oauth_token='+ oauth_token;
        BaseUrlEnding+= '&oauth_version='+ '1.0';

        String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+ EncodingUtil.urlEncode(Folder, 'UTF-8')+(FN!=null?(EncodingUtil.urlEncode(FN, 'UTF-8')).replaceAll('\\+', '%20').replaceAll('%', '%25'):'') +'&'+EncodingUtil.urlEncode(BaseUrlEnding.replaceAll('/', '%2F'), 'UTF-8');
          system.debug('signature2Encode:' + Signature2Encode);
            String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
    
            BaseUrlEnding += '&oauth_signature='+ macUrl;
        req.setEndPoint(BaseUrl + Folder + (FN!=null?EncodingUtil.urlEncode(FN, 'UTF-8').replaceAll('\\+', ' '):'') + '?' + BaseUrlEnding);
        if(!test.isRunningTest())
            res = h.send(req);

        return res.getBody();
    }
    
    public PageReference AfterUpload() {
        CheckFileExist(UserInfo.getOrganizationId() + '/' +  CurrentFolderNumber + '/' + (myFolder==null?getMyFolder():myFolder)+ '/', FileName);
        
          if(res.getBody() != null && !res.getBody().contains('{"error":')) {
                hasMessages = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your file has been uploaded'));
                SObject Dropboxx = new Dropbox__c(Name__c = FileName, URL__c = 'https://www.dropbox.com/0/links/' + BaseFolder + (myFolder==null?getMyFolder():myFolder) + '/' + FileName);
                Dropboxx.put(Field, FieldId);
                insert Dropboxx;
          }
            else {
                hasMessages = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'An error has happened'));
            }
        return null; 
    }
    
    @isTest
    public static void testing() {
        Account acc = new Account(Name = 'test');
        insert acc;
        Dropbox__c drop = [select id, URL__c from Dropbox__c order by createddate desc limit 1];
        ApexPages.currentPage().getParameters().put('url', 'https://www.salesforce.com/' + acc.Id);
        DropboxPopup DP = new DropboxPopup();
        DropboxPopup.ShareableLink SL = new DropboxPopup.ShareableLink();
        DropboxPopup.metadataFolderList SL2 = new DropboxPopup.metadataFolderList();
        DropboxPopup.metadataList SL3 = new DropboxPopup.metadataList();
        DropboxPopup.metadata SL4 = new DropboxPopup.metadata();
        ApexPages.currentPage().getParameters().put('theURL', drop.URL__c);
        DP.GetShareableLink();
        DP.getFile4Email(new list<Dropbox__c>{drop});
        ApexPages.currentPage().getParameters().put('theId', drop.Id);
        DP.deleteIt();
    }
    
    @isTest
    public static void testing2() {
        Account acc = new Account(Name = 'test');
        insert acc;
        Dropbox__c drop = [select id, URL__c from Dropbox__c order by createddate desc limit 1];
        ApexPages.currentPage().getParameters().put('url', 'https://www.salesforce.com/' + acc.Id);
        DropboxPopup DP = new DropboxPopup();
        DP.URLGeneration(drop.URL__c, 'files', null);
        ApexPages.currentPage().getParameters().put('theURL', drop.URL__c);
        DP.getFile();
        DP.dataTransfer();
        DP.UploadThemAll();
        DropboxPopup.FileName = 'test';
        DropboxPopup.UploadIt();
        DP.getDropboxes();
        DP.CheckEmptyFolder('test', 'test');
        DP.AfterUpload();
    }
}