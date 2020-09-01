public with sharing class DropboxDocumentsController {
    public boolean isPublicElement{get;set;}
    public boolean isPrivateElement{get;set;}
    public String selectedPublicFolder{get;set;}
    public String selectedPrivateFolder{get;set;}
    public list<Dropbox__c> PublicDropboxes{get;set;}
    public list<Dropbox__c> PrivateDropboxes{get;set;}
    public list<Dropbox__c> PublicDropboxesFolders{get;set;}
    public list<Dropbox__c> PrivateDropboxesFolders{get;set;}
    public list<DropboxObject> PublicDropboxesPerFolder{get;set;}
    public list<DropboxObject> PrivateDropboxesPerFolder{get;set;}
    public String urlEndPoint{get;set;}
    public String PublicFileName{get;set;}
    public String PrivateFileName{get;set;}
    public boolean hasMessages{get;set;}
    public String AlertMessage{get;set;}
    public String UploadType{get;set;}
    public String Text2Copy{get;set;}
    public String Text2Display{get;set;}
    
    public class DropboxObject {
        public boolean isChecked{get;set;}
        public Dropbox__c dropbox{get;set;}
        public DropboxObject(Dropbox__c drop) {
            this.dropbox = drop;
            this.isChecked = false;
        }
    }
    
    public DropboxDocumentsController() {
        getPublicDropboxes();
        getPrivateDropboxes();
        getPublicDropboxesFolders();
        getPrivateDropboxesFolders();
        isPublicElement = false;
        isPrivateElement = false; 
        if(!PublicDropboxesFolders.isEmpty()) {
            isPublicElement = true;
            selectedPublicFolder = PublicDropboxesFolders[0].Folder__c;
        }
        if(!PrivateDropboxesFolders.isEmpty()) {
            isPrivateElement = true;
            selectedPrivateFolder = PrivateDropboxesFolders[0].Folder__c;
        }
        String test = ApexPages.currentPage().getParameters().get('selectedPrivateFolder');
        try {
            if(test != null && test != '') {
                Dropbox__c dropTest = [select id from Dropbox__c where Folder__c =: test AND UserPrivateFolder__c =: UserInfo.getUserId()];
                //still here? then the folder exists!
                selectedPrivateFolder = test;
            }
        }
        catch(exception e) {}
        test = ApexPages.currentPage().getParameters().get('selectedPublicFolder');
        try {
            if(test != null && test != '') {
                Dropbox__c dropTest = [select id from Dropbox__c where Folder__c =: test AND UserPrivateFolder__c = null];
                //still here? then the folder exists!
                selectedPublicFolder = test;
            }
        }
        catch(exception e) {}
        getPublicDropboxesPerFolder();
        getPrivateDropboxesPerFolder();
    }
    
    public list<SelectOption> getPublicOptions() {        
        List<SelectOption> options = new List<SelectOption>();   
        set<String> DoubleCheck = new set<String>();
        if(selectedPublicFolder != null && selectedPublicFolder != '') {      
            for(Dropbox__c dp:PublicDropboxesFolders)   {  
                if(!DoubleCheck.contains(dp.Folder__c)) {   
                    DoubleCheck.add(dp.Folder__c);
                    options.add(new SelectOption(dp.Folder__c, dp.Folder_Label__c==null?'':dp.Folder_Label__c));
                }
            }
        }                       
        return options;      
    } 
    
    public list<SelectOption> getPrivateOptions() {        
        List<SelectOption> options = new List<SelectOption>();   
        set<String> DoubleCheck = new set<String>();
        if(selectedPrivateFolder != null && selectedPrivateFolder != '') {      
            for(Dropbox__c dp:PrivateDropboxesFolders)   {  
                if(!DoubleCheck.contains(dp.Folder__c)) {   
                    DoubleCheck.add(dp.Folder__c);
                    options.add(new SelectOption(dp.Folder__c, dp.Folder_Label__c==null?'':dp.Folder_Label__c));
                }
            }
        }                       
        return options;      
    }
    
    public void getPublicDropboxesPerFolder() {        
        PublicDropboxesPerFolder = new list<DropboxObject>();   
        for(Dropbox__c dp:PublicDropboxes)   {  
            if(dp.DropboxDocument__r.Folder__c == selectedPublicFolder) {   
                PublicDropboxesPerFolder.add(new DropboxObject(dp));
            }
        }                    
    } 
    
    public void getPrivateDropboxesPerFolder() {        
        PrivateDropboxesPerFolder = new list<DropboxObject>();   
        for(Dropbox__c dp:PrivateDropboxes)   {  
            if(dp.DropboxDocument__r.Folder__c == selectedPrivateFolder) {   
                PrivateDropboxesPerFolder.add(new DropboxObject(dp));
            }
        }                    
    } 
    
    public void getPublicDropboxesFolders() {   
        PublicDropboxesFolders = new list<Dropbox__c>([select Download__c, Name__c, Folder__c, Folder_Label__c, URL__c from Dropbox__c where Folder__c != null AND Folder__c != '' AND UserPrivateFolder__c = null]);    
        if(PublicDropboxesFolders.isEmpty())
            isPublicElement = false;
        else
            isPublicElement = true;
    }
    
    public void getPrivateDropboxesFolders() {   
        PrivateDropboxesFolders = new list<Dropbox__c>([select Download__c, Name__c, Folder__c, Folder_Label__c, URL__c from Dropbox__c where Folder__c != null AND Folder__c != '' AND UserPrivateFolder__c =: UserInfo.getUserId()]);    
        if(PublicDropboxesFolders.isEmpty())
            isPrivateElement = false;
        else
            isPrivateElement = true;
    }
    
    public void getPublicDropboxes() {        
        PublicDropboxes = new list<Dropbox__c>([select Download__c, Name__c, URL__c, Revision__c, DropboxDocument__r.Folder__c, DropboxDocument__r.Folder_Label__c from Dropbox__c where DropboxDocument__c != null AND DropboxDocument__r.UserPrivateFolder__c = null]);
    } 
    
    public void getPrivateDropboxes() {        
        PrivateDropboxes = new list<Dropbox__c>([select Download__c, Name__c, URL__c, Revision__c, DropboxDocument__r.Folder__c , DropboxDocument__r.Folder_Label__c from Dropbox__c where DropboxDocument__c != null AND DropboxDocument__r.UserPrivateFolder__c =: UserInfo.getUserId()]);
    }  
    
    public void synchronizationPrivate() {
        String Folder = 'PrivateFolders/' + UserInfo.getUserId() + '/' + selectedPrivateFolder;
        DropboxSynchronization.metadata metaObj = DropboxSynchronization.makeCallDocument(Folder);
        system.debug('metaObjPriv:' + metaObj);
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>();  
        Id DropboxDocumentId;
        getPrivateDropboxes();
        for(Dropbox__c dp:PrivateDropboxes)   {  
            if(dp.DropboxDocument__r.Folder__c == selectedPrivateFolder) {   
                DropboxDocumentId = dp.DropboxDocument__c;
                Dropboxes.add(dp);
            }
        }
        delete Dropboxes;

        Dropboxes = new list<Dropbox__c>();
        Dropbox__c Dropbox;
        if(metaObj != null) {
            for(DropboxSynchronization.Content content:metaObj.contents) {
                system.debug('content:' + content); 
                if(content.is_dir == false) {
                    Dropbox = new Dropbox__c();
                    Dropbox.Name__c = content.path.substring(content.path.lastIndexOf('/')+1);
                    Dropbox.URL__c = 'https://www.dropbox.com/0/links/Apps/salesforce' + content.path;
                    Dropbox.DropboxDocument__c = DropboxDocumentId;
                    Dropboxes.add(Dropbox);
                }
            }
            if(Dropboxes != null && !Dropboxes.isEmpty()) {
                insert Dropboxes; 
            } 
                
        }
        rerenderPrivateList();
    }

    public void synchronizationPublic() {
        String Folder = 'PublicFolders/' + selectedPublicFolder;
        DropboxSynchronization.metadata metaObj = DropboxSynchronization.makeCallDocument(Folder);
        system.debug('metaObjPub:' + metaObj);
        
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>();  
        Id DropboxDocumentId;
        getPublicDropboxes();
        for(Dropbox__c dp:PublicDropboxes)   {  
            if(dp.DropboxDocument__r.Folder__c == selectedPublicFolder) {   
                DropboxDocumentId = dp.DropboxDocument__c;
                Dropboxes.add(dp);
            }
        }
        delete Dropboxes;

        Dropboxes = new list<Dropbox__c>();
        Dropbox__c Dropbox;
        if(metaObj != null) {
            for(DropboxSynchronization.Content content:metaObj.contents) {
                system.debug('content:' + content); 
                if(content.is_dir == false) {
                    Dropbox = new Dropbox__c();
                    Dropbox.Name__c = content.path.substring(content.path.lastIndexOf('/')+1);
                    Dropbox.URL__c = 'https://www.dropbox.com/0/links/Apps/salesforce' + content.path;
                    Dropbox.DropboxDocument__c = DropboxDocumentId;
                    Dropboxes.add(Dropbox);
                }
            }
            if(!Dropboxes.isEmpty())
                insert Dropboxes; 
        }
        rerenderPublicList();
    }
    
    public void getShareableFolderPublic() {
        AlertMessage = '';
        DropboxPopup dp = new DropboxPopup();
        String URL = '';
        for(Dropbox__c dphelp:PublicDropboxes)   {  
            if(dphelp.DropboxDocument__r.Folder__c == selectedPublicFolder) {   
                URL = dphelp.URL__c;
                break;
            }
        }
        if(URL == '')
          AlertMessage = 'Folder empty or not found';
        else {
            URL = URL.substring(0, URL.lastIndexOf('/'));
            dp.URLFromDoc = URL;
            dp.GetShareableLink();
            AlertMessage = dp.AlertMessage;
            Text2Display = dp.Text2Display;
            Text2Copy = dp.Text2Copy;
        }
    }
    
    public void PublicUploadIt() {
        UploadType = 'public';
        
        String myFolder = 'PublicFolders/' + UserInfo.getUserId() + '/' + selectedPublicFolder; 
        String FileName = PublicFileName;
        urlEndPoint = UploadIt(myFolder, FileName);
        system.debug('urlEndPoint:' + urlEndPoint);
    }
    
    public void PrivateUploadIt() {
        UploadType = 'private';

        String myFolder = 'PrivateFolders/' + UserInfo.getUserId() + '/' + selectedPrivateFolder; 
        String FileName = PrivateFileName;
        urlEndPoint = UploadIt(myFolder, FileName);
        system.debug('urlEndPoint:' + urlEndPoint);
    }
    
    public String UploadIt(String myFolder, String FileName) {
        String oauth_consumer_key = 'd6tt72sdnll62d4';
        String oauth_consumer_secret = 'mbhl3mxgy2rpu8o';
        String oauth_token = DropboxConfig__c.getOrgDefaults().oauth_token__c;
        String oauth_token_secret = DropboxConfig__c.getOrgDefaults().oauth_tokensecret__c;
        
        String BaseUrl = 'https://api-content.dropbox.com/1/files/sandbox/';
        String BaseUrlEnding = '';    
        String File = 'file=';    
        BaseUrlEnding+= '&oauth_consumer_key='+ oauth_consumer_key;
        BaseUrlEnding+= '&oauth_nonce='+ String.valueOf(system.currentTimeMillis());
        BaseUrlEnding+= '&oauth_signature_method='+ 'HMAC-SHA1';
        BaseUrlEnding+= '&oauth_timestamp='+ String.valueOf(system.currentTimeMillis()/1000);
        BaseUrlEnding+= '&oauth_token='+ oauth_token;
        BaseUrlEnding+= '&oauth_version='+ '1.0';
        BaseUrlEnding+= '&path='+ UserInfo.getOrganizationId() + '/' +  myFolder; 
        system.debug('baseUrlEnding:'+BaseUrlEnding);
        try {
            String Signature2Encode = 'POST&'+EncodingUtil.urlEncode(BaseUrl, 'UTF-8')+'&'+EncodingUtil.urlEncode(File, 'UTF-8') + ((EncodingUtil.urlEncode(FileName, 'UTF-8')).replaceAll('\\+', '%20').replaceAll('%7E', '~').replaceAll('%', '%25')) + EncodingUtil.urlEncode(BaseUrlEnding.replace('/', '%2F'), 'UTF-8');
            system.debug('Signature2Encode:'+Signature2Encode);
            String macUrl = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.generateMac('HMacSHA1', Blob.valueOf(Signature2Encode), Blob.valueOf(oauth_consumer_secret+'&'+oauth_token_secret))), 'UTF-8');
            BaseUrlEnding += '&oauth_signature='+ macUrl;
        }
        catch(exception e) {}
        return BaseUrl + '?' + File + (FileName!=null?(EncodingUtil.urlEncode(FileName, 'UTF-8')):'') + BaseUrlEnding;
    }   
    
    public void getShareableFolderPrivate() {
        AlertMessage = '';
        DropboxPopup dp = new DropboxPopup();
        String URL = '';
        for(Dropbox__c dphelp:PrivateDropboxes)   {  
            if(dphelp.DropboxDocument__r.Folder__c == selectedPrivateFolder ) {   
                URL = dphelp.URL__c;
                break;
            }
        }
        if(URL == '')
          AlertMessage = 'Folder empty or not found';
        else {
            
            URL = URL.substring(0, URL.lastIndexOf('/'));
            system.debug('URL:' + URL);
            dp.URLFromDoc = URL ;
            dp.GetShareableLink();
            AlertMessage = dp.AlertMessage;
            Text2Display = dp.Text2Display;
            Text2Copy = dp.Text2Copy;
        }
    }
    
    public void getShareableLink() {
        DropboxPopup dp = new DropboxPopup();
        dp.URLFromDoc = ApexPages.currentPage().getParameters().get('theURL');
        dp.GetShareableLink();
        AlertMessage = dp.AlertMessage;
        Text2Display = dp.Text2Display;
        Text2Copy = dp.Text2Copy;
    }
    
    public void deleteThem() { 
        String PublicPrivate = ApexPages.currentPage().getParameters().get('PublicPrivate');
        AlertMessage = '';
        system.debug('DropObj:' + PrivateDropboxesPerFolder);
        DropboxOverrideController DOC = new DropboxOverrideController(null);
        DOC.isDocument = true;
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>();
        if(PublicPrivate == 'public'){
            for(DropboxObject PDPF:PublicDropboxesPerFolder) {
                 if(PDPF.isChecked) {
                    Dropboxes.add(PDPF.dropbox);
                 }
            }
        }
        else if(PublicPrivate == 'private') {
            for(DropboxObject PDPF:PrivateDropboxesPerFolder) {
                 if(PDPF.isChecked) {
                    Dropboxes.add(PDPF.dropbox);
                 }
            } 
        }   
        if(Dropboxes.size() > 10) {
            AlertMessage = 'max 10 files!';
        }
        else if(Dropboxes.isEmpty()) {
            AlertMessage = 'Please select at least one file!';
        }
        else {
            for(Dropbox__c db:Dropboxes){
                String result = '';
                if(PublicPrivate == 'public')
                    result = DOC.doRequest(db.URL__c.substring(db.URL__c.lastIndexOf('/') + 1), UserInfo.getOrganizationId() + '/PublicFolders/' + selectedPublicFolder + '/');
                else if(PublicPrivate == 'private')
                    result = DOC.doRequest(db.URL__c.substring(db.URL__c.lastIndexOf('/') + 1), UserInfo.getOrganizationId() + '/PrivateFolders/' + UserInfo.getUserId() + '/'+ selectedPrivateFolder + '/');
                if(!result.contains('{"error":') || result.contains(' not found"}')) {              
                    delete db; 
                }
                else
                    AlertMessage = result;
            }
        }
        if(PublicPrivate == 'public')
            rerenderPublicList();
        else if(PublicPrivate == 'private')
            rerenderPrivateList();
    }
    
    public void deletePublicLayout() {
        DropboxOverrideController DOC = new DropboxOverrideController(null);
        DOC.isDocument = true;
        DOC.doRequest(null, UserInfo.getOrganizationId() + '/PublicFolders/' + selectedPublicFolder);
        Dropbox__c dp = [select id from Dropbox__c where Folder__c =: selectedPublicFolder AND UserPrivateFolder__c = null];
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>([select id from Dropbox__c where DropboxDocument__c =: dp.Id]);
        delete Dropboxes;
        delete dp;
        rerenderPublicList();
    }
    
    public void deletePrivateLayout() {
        DropboxOverrideController DOC = new DropboxOverrideController(null);
        DOC.isDocument = true;
        DOC.doRequest(null, UserInfo.getOrganizationId() + '/PrivateFolders/' + UserInfo.getUserId() + '/' + selectedPrivateFolder);
        Dropbox__c dp = [select id from Dropbox__c where Folder__c =: selectedPrivateFolder AND UserPrivateFolder__c =: UserInfo.getUserId()];
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>([select id from Dropbox__c where DropboxDocument__c =: dp.Id]);
        delete Dropboxes;
        delete dp;
        rerenderPrivateList();
    }
    

    
    public void DeleteIt() {
        AlertMessage = '';
        String theId = ApexPages.currentPage().getParameters().get('theId');
        ApexPages.StandardController controller =  new ApexPages.StandardController([select id from Dropbox__c where Id =: theId limit 1]);
        DropboxOverrideController OC = new DropboxOverrideController (controller);
        OC.isDocument = true;
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
        rerenderPublicList();
        rerenderPrivateList();
    }
    
    public PageReference AfterPublicUpload() {
        DropboxPopup DP = new DropboxPopup();
        String result = DP.CheckEmptyFolder(UserInfo.getOrganizationId() + '/' +  'PublicFolders/' + selectedPublicFolder + '/', PublicFileName);
        if(result != null && !result.contains('{"error":')) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your file has been uploaded'));
            Dropbox__c Dropbox = new Dropbox__c(Name__c = PublicFileName, URL__c = 'https://www.dropbox.com/0/links/Apps/salesforce/' + UserInfo.getOrganizationId() + '/' +  'PublicFolders/' + selectedPublicFolder + '/' + PublicFileName);
            Dropbox.DropboxDocument__c = [select id from Dropbox__c where Folder__c =: selectedPublicFolder AND UserPrivateFolder__c = null].Id;
            insert Dropbox;
            rerenderPublicList();
        }
        else {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'An error has happened'));
        }
        return null; 
    }
    
    public PageReference AfterPrivateUpload() {
        DropboxPopup DP = new DropboxPopup();
        String t = '';
        String result = DP.CheckEmptyFolder(UserInfo.getOrganizationId() + '/' +  'PrivateFolders/' + UserInfo.getUserId() + '/'+ selectedPrivateFolder + '/', PrivateFileName);
        system.debug('resultdebug:' + result);
        if(result != null && !result.contains('{"error":')) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your file has been uploaded'));
            Dropbox__c Dropbox = new Dropbox__c(Name__c = PrivateFileName, URL__c = 'https://www.dropbox.com/0/links/Apps/salesforce/' + UserInfo.getOrganizationId() + '/' +  'PrivateFolders/' + UserInfo.getUserId() + '/' + selectedPrivateFolder + '/' + PrivateFileName);
            Dropbox.DropboxDocument__c = [select id from Dropbox__c where Folder__c =: selectedPrivateFolder AND UserPrivateFolder__c =: UserInfo.getUserId()].Id;
            insert Dropbox;
            rerenderPrivateList();
        }
        else {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'An error has happened'));
        }
        return null; 
    }
    public PageReference rerenderPublicList() {
        getPublicDropboxes();
        getPublicDropboxesFolders();
        getPublicOptions();
        getPublicDropboxesPerFolder();
        system.debug('selectedFolder:' + selectedPublicFolder);
        return null;
    }
    
    public PageReference rerenderPrivateList() {
        getPrivateDropboxes();
        getPrivateDropboxesFolders();
        getPrivateOptions();
        getPrivateDropboxesPerFolder();
        system.debug('selectedFolder:' + selectedPrivateFolder);
        return null;
    }
    
 
   
}