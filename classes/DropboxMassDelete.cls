global class DropboxMassDelete {
    webservice static String init(String DropboxId) {
        String AlertSuccessErrorAfterSend = 'ok' ;
        system.debug('test:' + DropboxId);
        if(DropboxId != null && DropboxId!= '') {
                list<Dropbox__c> Dropboxes = new list<Dropbox__c>([select URL__c from Dropbox__c where Id =: DropboxId]);
                for(Dropbox__c drop:Dropboxes) {
                    DropboxOverrideController OC = new DropboxOverrideController(new ApexPages.StandardController(Drop));
                    AlertSuccessErrorAfterSend = OC.doJob(); 
                }
        }
        else {
            AlertSuccessErrorAfterSend = 'Please select at least one File!';
        }
        
        return AlertSuccessErrorAfterSend;
    }
    
    @isTest
    public static void testing() {
        DropboxMassDelete.init(null);
        Dropbox__c drop = [select URL__c from Dropbox__c order by createdDate desc limit 1];
        DropboxMassDelete.init(drop.Id);
    }
}