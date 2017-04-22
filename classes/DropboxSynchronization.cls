global class DropboxSynchronization {
    private static String oauth_consumer_key;
    private static String oauth_consumer_secret;
    private static String oauth_token;
    private static String oauth_token_secret;
    private static Http h = new Http();
    private static HttpRequest req = new HttpRequest();
    private static HttpResponse res = new HttpResponse();
    private static DropboxSynchronization.metadata metaObj;
    private static map<String,String> keyPrefixMap = new Map<String,String>{};
    public static boolean isDocument = false;
    
    public class metadata {
        public String error;
        public String hash;
        public Integer revision;
        public String rev;
        public Boolean thumb_exists;
        public Integer bytes;
        public String modified;
        public String path;
        public boolean is_dir;
        public String icon;
        public String root;
        public Content[] contents;
        public String size;

    }

    public class Content {
        public Integer revision;
        public String rev;
        public boolean thumb_exists;
        public Integer bytes;
        public String modified;
        public String path;
        public boolean is_dir;
        public String icon;
        public String root;
        public String mime_type;
        public String size;
        public String client_mtime;
    }
      
    webservice static void init(String URL) {
        isDocument = false;
        String FieldId = URL.split('force.com/')[1].substring(0,15);
        system.debug('test:' + FieldId);
        GetDirectory(Id.valueOf(FieldId));
        updateDirectory(FieldId);
    }
    
    public static DropboxSynchronization.metadata makeCallDocument(String Directory) {
        isDocument = true;
        GetDirectory(Directory);
        return metaObj;
    }
    
    private static void updateDirectory(Id FileDirectory) {
        keyFieldMapping();
        String Field = keyPrefixMap.get(String.valueOf(FileDirectory).substring(0,3));
        if(!Field.contains('__c'))
            Field += '__c';
        String Query = 'select id, URL__c, Name__c from Dropbox__c where ' + Field + ' =: FileDirectory';
        list<Dropbox__c> Dropboxes = (list<Dropbox__c>)Database.query(query);
        delete Dropboxes;
        Dropboxes = new list<Dropbox__c>();
        sObject Dropbox;
        if(metaObj != null) {
            for(Content content:metaObj.contents) {
                system.debug('content:' + content);
                if(content.is_dir == false) {
                    Dropbox = new Dropbox__c();
                    Dropbox.put('Name__c', content.path.substring(content.path.lastIndexOf('/')+1));
                    Dropbox.put('URL__c' , 'https://www.dropbox.com/0/links/Apps/salesforce' + content.path);
                    Dropbox.put(Field, FileDirectory);
                    Dropboxes.add((Dropbox__c)Dropbox);
                }
            }
            if(!Dropboxes.isEmpty())
                insert Dropboxes; 
        }
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
    
    private static void GetDirectory(String FileDirectory) {
        oauth_consumer_key = 'd6tt72sdnll62d4';
        oauth_consumer_secret = 'mbhl3mxgy2rpu8o';
        DropboxConfig__c dc = DropboxConfig__c.getOrgDefaults();
        oauth_token = dc.oauth_token__c;
        oauth_token_secret = dc.oauth_tokensecret__c;

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

        String Signature2Encode = 'GET&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+ UserInfo.getOrganizationId()+ '%2F' + (isDocument?'':(dc.CurrentFolderNumber__c + '%2F'))+ EncodingUtil.urlEncode(FileDirectory, 'UTF-8') +'&'+EncodingUtil.urlEncode(BaseUrlEnding.replaceAll('/', '%2F'), 'UTF-8');
        system.debug('signature2Encode:' + Signature2Encode);
        String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
    
        BaseUrlEnding += '&oauth_signature='+ macUrl;
        req.setEndPoint(BaseUrl + UserInfo.getOrganizationId() + '/' + (isDocument?'':(dc.CurrentFolderNumber__c + '%2F') + '/') + FileDirectory + '?' + BaseUrlEnding);
        if(!test.isRunningTest())
            res = h.send(req);
        system.debug('result:'+res.getBody());
        if(res.getBody() != null && res.getBody() != '' && !res.getBody().contains('{"error": "Path') && !res.getBody().contains('"is_deleted": true')) {
            Type wrapperType = Type.forName('DropboxSynchronization.metadata'); 
            metaObj = (DropboxSynchronization.metadata)JSON.deserialize(res.getBody(), wrapperType);
        }
      system.debug('output:'+metaObj); 
    }
    
    @isTest
    public static void testing() {
        Contact drop = [select id from Contact order by CreatedDate desc limit 1];
        DropboxSynchronization.init('salesforce.com/'  +drop.Id);
        DropboxSynchronization.makeCallDocument('');
        DropboxSynchronization.metadata meta = new DropboxSynchronization.metadata();
        DropboxSynchronization.content meta2 = new DropboxSynchronization.content();
    }
}