public class DropboxEmail {
    public String EmailTo{get;set;}
    public String EmailCC{get;set;}
    public String EmailBCC{get;set;}
    public String Subject{get;set;}
    public String Body{get;set;}
    public Boolean hasSignature{get;set;}
    public Boolean addAutoBCC{get;set;}
    
    public list<String> Names {get;set;}
    public list<String> URLs {get;set;}
    public list<String> DropboxIds {get;set;}
    public string FileUploaded{get;set;}
    public string FinishFileUploaded{get;set;}
    public string ErrorIds{get;set;}
    public list<Files> FilesUploaded {get;set;}
    public list<ContentVersion> CVList {get;set;}
    public list<ContentVersion> TempCVList {get;set;}
    public String SessionId {get;set;}
    public string AlertSuccessErrorAfterSend{get;set;}
    public boolean hasMessage {get;set;}
    public Integer DeleteId {get;set;}
    public String PrefixOrg{get;set;}
    public String selectedTemplate{get;set;}
    
    private map<String, list<String>> roleMapEmailMapping = new map<String, list<String>>();
    private map<String, list<String>> profileMapEmailMapping = new map<String, list<String>>();
    private set<String> ContentVersionIdsRemoved = new set<String>();
    private map<String, map<String, String>> FieldSchema = new map<String, map<String, String>>();
    private map<String,String> keyPrefixMap = new Map<String,String>{};
    //private Type wrapperTypeAll = Type.forName('DropboxEmail.metadataAll'); 
//  private Type wrapperType = Type.forName('DropboxEmail.metadata'); 
    
    public list<SelectOption> getTemplates() {        
        List<SelectOption> options = new List<SelectOption>();
        selectedTemplate = null;
        options.add(new SelectOption('--None--', '--None--')); 
        for(EmailTemplate ET:[select id, Name from EmailTemplate]) {
            options.add(new SelectOption(ET.id, ET.Name)); 
        }
        return options;
    } 
    
    public String ReplacePlaceholder(String Placeholder) {
        Placeholder = Placeholder.trim();
        if(Placeholder.contains('.')) {
            String temp = Placeholder.substring(2, Placeholder.length() - 1).toLowerCase();
            String Obj = temp.split('\\.')[0];
            String Field = temp.split('\\.')[1];
            System.debug('Obj:' + Obj);
            System.debug('Field:' + Field);
            System.debug('containskey:' + FieldSchema.keySet());
            
            if(FieldSchema.containsKey(Obj) && FieldSchema.get(Obj).containsKey(Field))
                Placeholder = FieldSchema.get(Obj).get(Field);
        }
        return Placeholder;
    }
    
    public void rerenderTemplate() {
        Subject = '';
        Body = '';
        Integer j = 0;

        
        if(selectedTemplate  != '--None--') {
            EmailTemplate ET = [select Body, Subject from EmailTemplate where Id =:selectedTemplate];
            Subject = String.escapeSingleQuotes(ET.Subject);
            Body = String.escapeSingleQuotes(ET.Body!=null?ET.Body.replace('\n', '<br/>'):'');
        }
        for(Integer i = 0; i < Subject.length() -2 ; i++) {
            if(Subject.substring(i, i+2) == '{!') {
                //found {!, we are looking now for }
                if(Subject.indexOf('}', i+2) > i+2)
                    j = Subject.indexOf('}', i+2);
                String Placeholder = Subject.substring(i, j+1);
                
                system.debug('variable:' + Placeholder);
                Placeholder = ReplacePlaceholder(Placeholder);
                Subject = Subject.substring(0, i) + Placeholder + Subject.substring(j+1);
            }
                
        }
        
        for(Integer i = 0; i < Body.length() -2 ; i++) {
            if(Body.substring(i, i+2) == '{!') {
                //found {!, we are looking now for }
                if(Body.indexOf('}', i+2) > i+2)
                    j = Body.indexOf('}', i+2);
                String Placeholder = Body.substring(i, j+1);
                
                system.debug('variable:' + Placeholder);
                Placeholder = ReplacePlaceholder(Placeholder);
                Body = Body.substring(0, i) + Placeholder + Body.substring(j+1);
            }
                
        }
        system.debug('test3:' + Body);
    }
    
    public class Files {
        public ContentVersion Content {get; set;}
        public Integer counter {get;set;}
        //public String Name;
        public String Link {get; set;}
        public Files(ContentVersion CV) {
            this.Content = CV;
        }
    }
    
    public class metadataAll {
        public list<metadata> content;
    }
    
    public class metadata {
        public String id;
        public list<String> errors;
        public Boolean success;
        public metadata() {
            this.id = null;
            this.errors = null;
            this.success = false;
        }
    }
    
    public void fillFieldSchema(Map<String, SObjectField> Schema, String Obj, String Condition) {
        String query = 'select ';
        for(String s:Schema.keySet()) {
            query += s + ',';
        }
        query = query.substring(0, query.length()-1);
        query += ' from '+Obj+ Condition + ' limit 1';
        FieldSchema.put(Obj, new map<String, String>());
        sObject u = database.query(query);
        for(String s:Schema.keySet()) {
            FieldSchema.get(Obj).put(s, String.valueOf(u.get(s)));
        } 
        system.debug('FieldSchema:' + FieldSchema);
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
    
    public DropboxEmail() {
        keyFieldMapping();  
        String CurrentObject = '';
        Id FieldId;     
        if(ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().get('url') != null) {
            try {
                FieldId = ApexPages.currentPage().getParameters().get('url').split('force.com/')[1].substring(0,15);
                CurrentObject = keyPrefixMap.get(String.valueOf(FieldId).substring(0,3)).toLowerCase();
                
            }
            catch(exception e){}
        }
        PrefixOrg =  ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');
        CVList = new list<ContentVersion>();
        TempCVList = new list<ContentVersion>();
                SessionId = UserInfo.getSessionId();
        FilesUploaded = new list<Files>();
        Map<String, SObjectField> UserSchema = Schema.sObjectType.User.fields.getMap();
        Map<String, SObjectField> OrganizationSchema = Schema.sObjectType.Organization.fields.getMap();
        if(CurrentObject != '') {
            Map<String, SObjectField> CurrentObjectSchema =  Schema.getGlobalDescribe().get(CurrentObject).getDescribe().fields.getMap();
            fillFieldSchema(CurrentObjectSchema, CurrentObject, ' where Id = \'' + FieldId + '\'');
        }
        fillFieldSchema(UserSchema, 'user', ' where Id = \'' + UserInfo.getUserId() + '\'');
        fillFieldSchema(OrganizationSchema, 'organization', '');
        
        Names = new list<String>();
        URLs = new list<String>();
        String DropboxId = ApexPages.currentPage().getParameters().get('Records');

        if(DropboxId != null && DropboxId != '') {
            DropboxIds = new list<String>();
            DropboxIds = DropboxId.split(',');
            if(DropboxIds.size() > 10) {
                AlertSuccessErrorAfterSend = 'You cannot select more than 10 Files.';
            }
            else {
                list<Dropbox__c> Dropboxes = new list<Dropbox__c>([select URL__c from Dropbox__c where Id IN: DropboxIds]);
                DropboxPopup Drop = new DropboxPopup();
    
                map<Integer, list<String>> Values = Drop.getFile4Email(Dropboxes);
                DropboxIds = new list<String>();
                for(list<String> val:Values.values()){
                    Names.add(val.get(0));
                    URLs.add(val.get(1));
                    DropboxIds.add(val.get(2));
                }
            }
        }
        else {
            AlertSuccessErrorAfterSend = 'Please select at least one File!';
        }
        selectedTemplate = '--None--';
    }
    
    public void removeFile() {
        if(DeleteId != null ) {
            Integer i = 0;
            Integer j = 0;
            for(Files f:FilesUploaded) {
                if(f.counter == DeleteId)
                    break;
                i++;
            }
            
            for(ContentVersion CV:CVList) {
                if(CV.Id == FilesUploaded.get(i).Content.Id)
                    break;
                j++;
            }
            if(!FilesUploaded.isEmpty())
                ContentVersionIdsRemoved.add(FilesUploaded.get(i).Content.Id);
            if(!CVList.isEmpty())
                CVList.remove(j);
            ContentVersion CV;
            if(!FilesUploaded.isEmpty())
                try{
                   CV = [select ContentDocumentId from ContentVersion where Id =: FilesUploaded.get(i).Content.Id]; 
                }
                catch(exception e){}
            if(CV != null)
                database.delete(CV.ContentDocumentId);
            if(!FilesUploaded.isEmpty())
                FilesUploaded.remove(i);
        }
    }
    
    
    
    public void Object2Email(String[] toAddresses, String[] ccAddresses, String[] bccAddresses ) {
        list<String> profileEmailMapping = new list<String>();
        list<String> roleEmailMapping = new list<String>();
        system.debug('to addresses:' + toAddresses);
        if(toAddresses != null) {
            for(String s:toAddresses) {
                system.debug('s part:' + s);
                if(s.contains('\',\'')) {
                    s = s.substring(s.indexOf('{')+2, s.lastIndexOf('}')-1);
                    system.debug('s part inside:' + s);
                    if(s.split('\',\'')[0].toLowerCase() == 'profile') {
                        system.debug('s part inside2:' + s.split('\',\'')[0]);
                        profileEmailMapping.add(s.split('\',\'')[1]);
                    }
                    else if(s.split('\',\'')[0].toLowerCase() == 'role')
                        roleEmailMapping.add( s.split('\',\'')[1]);
                }
            }
        }
        if(ccAddresses != null) {
            for(String s:ccAddresses) {
                if(s.contains('\',\'')) {
                    s = s.substring(s.indexOf('{')+2, s.lastIndexOf('}')-1);
                    if(s.split('\',\'')[0].toLowerCase() == 'profile')
                        profileEmailMapping.add(s.split('\',\'')[1]);
                    else if(s.split('\',\'')[0].toLowerCase() == 'role')
                        roleEmailMapping.add( s.split('\',\'')[1]);
                }
            }
        }
        if(bccAddresses != null) {
            for(String s:bccAddresses) {
                if(s.contains('\',\'')) {
                    s = s.substring(s.indexOf('{')+2, s.lastIndexOf('}')-1);
                    if(s.split('\',\'')[0].toLowerCase() == 'profile')
                        profileEmailMapping.add(s.split('\',\'')[1]);
                    else if(s.split('\',\'')[0].toLowerCase() == 'role')
                        roleEmailMapping.add( s.split('\',\'')[1]);
                }
            }
        }
        if(!profileEmailMapping.isEmpty()) {
            for(User u:[select profile.Name, email from User where profile.Name IN: profileEmailMapping]) {
                if(!profileMapEmailMapping.containsKey(u.profile.Name))
                    profileMapEmailMapping.put(u.profile.Name, new list<String>());
                profileMapEmailMapping.get(u.profile.Name).add(u.email);
            }
        }
        if(!roleEmailMapping.isEmpty()) {
            for(User u:[select UserRole.Name, email from User where UserRole.Name IN: roleEmailMapping]) {
                if(!roleMapEmailMapping.containsKey(u.UserRole.Name))
                    roleMapEmailMapping.put(u.UserRole.Name, new list<String>());
                roleMapEmailMapping.get(u.UserRole.Name).add(u.email);
            }
        }
        system.debug('profiles:' + profileMapEmailMapping);
    }
    
    public list<String> CleaningAddresses(list<String> Addresses) {
        list<String> FinalAddresses = new list<String>();
        list<String> Addresses2workOn = new list<String>();
        for(String s:Addresses) {
            if(!s.contains('\',\''))
                FinalAddresses.add(s);
            else
                Addresses2workOn.add(s);
        }
        for(String s:Addresses2workOn) {
            s = s.substring(2, s.length() - 2);
            if(s.split('\',\'')[0] == 'role') {
                if(roleMapEmailMapping.containsKey(s.split('\',\'')[1]))
                    FinalAddresses.addAll(roleMapEmailMapping.get(s.split('\',\'')[1]));
            }
            else {
                if(profileMapEmailMapping.containsKey(s.split('\',\'')[1]))
                    FinalAddresses.addAll(profileMapEmailMapping.get(s.split('\',\'')[1]));
            }
        }
        system.debug('final Addresses:' + FinalAddresses);
        return FinalAddresses;
    }
    
    public void SendEmail() {
        if(EmailTo != null && EmailTo != '') {
            // First, reserve email capacity for the current Apex transaction to ensure   
            // that we won't exceed our daily email limits when sending email after the current transaction is committed. 
            Messaging.reserveSingleEmailCapacity(2);
            
            // Processes and actions involved in the Apex transaction occur next, which conclude with sending a single email.   
            // Now create a new single email message object that will send out a single email to the addresses in the To, CC & BCC list.   
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Strings to hold the email addresses to which you are sending the email. 
            String[] toAddresses = EmailTo.split(';');
            String[] ccAddresses = (EmailCC==null||EmailCC=='')?null:EmailCC.split(';') ; 
            String[] bccAddresses = (EmailBCC==null||EmailBCC=='')?null:EmailBCC.split(';') ; 
            
            Object2Email(toAddresses, ccAddresses, bccAddresses );
            if(toAddresses != null)
                toAddresses = CleaningAddresses(toAddresses);
            if(ccAddresses != null)
                ccAddresses = CleaningAddresses(ccAddresses);
            if(bccAddresses != null)
                bccAddresses = CleaningAddresses(bccAddresses);
            
            // Assign the addresses for the To and CC lists to the mail object.     
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setBCcAddresses(bccAddresses);
            // Specify the address used when the recipients reply to the email.
            User u = [select id, email from User where Id =: UserInfo.getUserId()];
            mail.setReplyTo(u.email);
            
            // Specify the name used as the display name.    
            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
            
            // Specify the subject line for your email address. 
            mail.setSubject(Subject);
            
            // Set to True if you want to BCC yourself on the email.  
            mail.setBccSender(addAutoBCC);
            
            // Optionally append the salesforce.com email signature to the email. 
            // The email address of the user executing the Apex Code will be used. 
            mail.setUseSignature(hasSignature);
            
            // Specify the text content of the email.   
            mail.setHtmlBody(Body);
            
            // Send the email you have created. 
            //
            list<Messaging.EmailFileAttachment> EFAList = new list<Messaging.EmailFileAttachment>();
            list<Id> CVIds = new list<Id>();
            for(ContentVersion CV:CVList) {
                CVIds.add(CV.Id);
            }
            Messaging.EmailFileAttachment EFA;
            list<Id> Content2Delete = new list<Id>();
            for(ContentVersion CV:[select VersionData, PathOnClient, ContentDocumentId from ContentVersion where Id IN: CVIds ]) {
                Content2Delete.add(CV.ContentDocumentId);
                EFA = new Messaging.EmailFileAttachment();
                EFA.setFileName(CV.PathOnClient);
                EFA.setBody(CV.VersionData);
                EFA.setInline(false);
                EFAList.add(EFA);
            }
            
            mail.setFileAttachments(EFAList);
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                AlertSuccessErrorAfterSend = 'Your message has been sent';
            }
            catch(exception e) {
                AlertSuccessErrorAfterSend = e.getMessage();
            }
            database.delete(Content2Delete);
        }
    }
    
    public void getFilesUploaded() {
        FilesUploaded = new list<Files>();
        for(ContentVersion cv:CVList) {
            FilesUploaded.add(new Files(cv));
        }
    }
    
    //this method is called during the upload if something goes wrong. we have to save all the uploaded files (TempCVList) and to run the applet
    // again where all the errors happened.
    public PageReference CallOnErrorController() {
        system.debug('in the error method.');
        system.debug('result:' + FinishFileUploaded);
        list<String> DropboxErrorIds = new list<String>(ErrorIds.split(','));
        if(FinishFileUploaded != null) {
            metadataAll metaObj = new metadataAll();
            //old
            //metaObj = (DropboxEmail.metadataAll)JSON.deserialize(FinishFileUploaded, DropboxEmail.metadataAll.class);
            Type wrapperTypeAll = Type.forName('DropboxEmail.metadataAll'); 
            metaObj = (DropboxEmail.metadataAll)JSON.deserialize(FinishFileUploaded, wrapperTypeAll);
            
            
            list<Id> CVIds = new list<Id>();
            for(metadata md:metaObj.content) {
                CVIds.add(md.Id);
            }
            CVList = new list<ContentVersion>();
            FilesUploaded = new list<Files>();
            for(ContentVersion cv:[select id, PathOnClient from ContentVersion where Id IN: CVIds]){
                CVList.add(cv);
                TempCVList.add(cv);
                FilesUploaded.add(new Files(cv));
            }
            system.debug('FilesUploaded:'+FilesUploaded);
        }
        
        list<Dropbox__c> Dropboxes = new list<Dropbox__c>([select URL__c from Dropbox__c where Id IN: DropboxErrorIds]);
        DropboxPopup Drop = new DropboxPopup();

        map<Integer, list<String>> Values = Drop.getFile4Email(Dropboxes);
        Names = new list<String>();
        URLs = new list<String>();
        DropboxIds = new list<String>();
        for(list<String> val:Values.values()){
            Names.add(val.get(0));
            URLs.add(val.get(1));
            DropboxIds.add(val.get(2));
        }
        
        return null;
    } 
    
    //this method will be called when everything has run fine and everything is saved on salesforce
    public PageReference FinishUpdateFile() {
        system.debug('result:' + FinishFileUploaded);
        if(FinishFileUploaded != null) {
            metadataAll metaObj = new metadataAll();
            try {
                //metaObj = (DropboxEmail.metadataAll)JSON.deserialize(FinishFileUploaded, DropboxEmail.metadataAll.class);
                Type wrapperTypeAll = Type.forName('DropboxEmail.metadataAll'); 
                metaObj = (DropboxEmail.metadataAll)JSON.deserialize(FinishFileUploaded, wrapperTypeAll);
            }
            catch(exception e) {
                system.debug('hey:' + e.getMessage());
            }
            list<Id> CVIds = new list<Id>();
            for(metadata md:metaObj.content) {
                CVIds.add(md.Id);
            }
            CVList = new list<ContentVersion>();
            FilesUploaded = new list<Files>();
            for(ContentVersion cv:[select id, PathOnClient from ContentVersion where Id IN: CVIds order by Id asc]){
                if(!ContentVersionIdsRemoved.contains(String.valueOf(cv.Id))) {
                    CVList.add(cv);
                    FilesUploaded.add(new Files(cv));
                }
            }
            //if something goes wrong duringh the upload, we have to add all the "old" files which were uploaded during a previously batch.
            if(!TempCVList.isEmpty()) {
                for(ContentVersion cv:TempCVList){
                    if(!ContentVersionIdsRemoved.contains(String.valueOf(cv.Id))) {
                        CVList.add(cv);
                        FilesUploaded.add(new Files(cv));
                    }
                }
            }
            Integer i = 0;
            for(Files f:FilesUploaded) {
                f.counter = i;
                i++;
            }
            system.debug('FilesUploaded:'+FilesUploaded);
        }
        return null;
    } 
    
    //this method is called for every feedback from the applet to update the status of the uploaded file
    public PageReference UpdateFile() {
        system.debug('result:' + FileUploaded);
        if(FileUploaded != null) {
            metadata metaObj = new metadata();
            try {
                Type wrapperType = Type.forName('DropboxEmail.metadata'); 
                metaObj = (DropboxEmail.metadata)JSON.deserialize(FileUploaded, wrapperType);
            }
            catch(exception e) {
                system.debug('hey:' + e.getMessage());
            }
            ContentVersion cv = [select id, PathOnClient from ContentVersion where Id =: metaObj.Id];
            CVList.add(cv);
            FilesUploaded.add(new Files(cv));
            Integer i = 0;
            for(Files f:FilesUploaded) {
                f.counter = i;
                i++;
            }
            system.debug('FilesUploaded:'+FilesUploaded);
        }
        return null;
    } 
    
    @isTest
    public static void testing() {
        Dropbox__c drop = [select id from Dropbox__c order by createdDate desc limit 1];
        String ProfileName = [select name from Profile limit 1].Name;
        String RoleName = [select name from UserRole limit 1].Name;
        
        ApexPages.currentPage().getParameters().put('Records', drop.Id);
        DropboxEmail DE = new DropboxEmail();
        DE.DeleteId = 0;
        DE.removeFile();
        DropboxEmail.Files Files = new DropboxEmail.Files(null);
        DropboxEmail.metadataAll metadataAll = new DropboxEmail.metadataAll();
        DropboxEmail.metadata metadata = new DropboxEmail.metadata();
        DE.Object2Email(new list<String>{'{\'profile\',\''+ProfileName+'\'}'}, new list<String>{'{\'profile\',\''+ProfileName+'\'}'}, new list<String>{'{\'profile\',\''+ProfileName+'\'}'});
        DE.Object2Email(new list<String>{'{\'role\',\''+RoleName+'\'}'}, new list<String>{'{\'role\',\''+RoleName+'\'}'}, new list<String>{'{\'role\',\''+RoleName+'\'}'});
        
        DE.CleaningAddresses(new list<String>{'{\'profile\',\''+ProfileName+'\'}'});
        DE.CleaningAddresses(new list<String>{'{\'role\',\''+RoleName+'\'}'});
        DE.EmailTo = 'qwdqwd@qwd.com';
        DE.addAutoBCC = true;
        DE.hasSignature = false;
        DE.SendEmail();
        ContentVersion cv = new  ContentVersion(Title = 'test', ContentUrl = 'http://www.google.de');
        insert cv; 
      //  ContentVersion cv = [select id from ContentVersion limit 1];
        DE.FileUploaded = '{"id":"'+cv.Id+'"}';
        DE.UpdateFile();
        DE.FinishFileUploaded = '{"content":[{"id":"'+cv.Id+'"}]}';
        DE.FinishUpdateFile();
        DE.ErrorIds = 'test,test';
        
        DE.FinishFileUploaded = '{"content":[{"id":"'+cv.Id+'"}]}';
        DE.CallOnErrorController();
        DE.getFilesUploaded();
    }

}