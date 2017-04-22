public with sharing class DropboxRevision {
    public String AlertMessage {get;set;}
    private static Http h = new Http();
    private static HttpRequest req = new HttpRequest();
    private static HttpResponse res = new HttpResponse();
    public list<DropboxPopup.metadata> Revisions {get;set;}
    private Dropbox__c dropbox;
    
    public DropboxRevision() {
        getRevision();
    }
    
    public void getRevision() {
        Revisions = new list<DropboxPopup.metadata>();
        String FileId = ApexPages.currentPage().getParameters().get('FileId');
        dropbox = [select URL__c from Dropbox__c where Id =: FileId];
        DropboxPopup DP = new DropboxPopup();
        String EndPoint = DP.URLGeneration(dropbox.URL__c, 'revisions', '&rev_limit=1000');
        req.setTimeout(60000);
        req.setMethod('GET');
        if(EndPoint!=null)
            req.setEndPoint(EndPoint);
        if(!test.isRunningTest())
            res = h.send(req);
        system.debug('resBody:' + res.getBody());
        DropboxPopup.metadataList metaObj = new DropboxPopup.metadataList();
        Type wrapperType = Type.forName('DropboxPopup.metadataList'); 
        try {
            metaObj = (DropboxPopup.metadataList)JSON.deserialize('{"metadata":' + res.getBody() + '}', wrapperType);
        }
        catch(exception e) {}
        system.debug('metaObj:' + metaObj);
        if(metaObj.metadata != null) {
            for(DropboxPopup.metadata meta:metaObj.metadata) {
                Revisions.add(meta);
            }
        }
        
        AlertMessage = '';
    }
    
    public PageReference getFile() {
        AlertMessage = '';
        DropboxPopup DP = new DropboxPopup();
        String Rev = ApexPages.currentPage().getParameters().get('theRevision');
        String URL =  DP.URLGeneration(dropbox.URL__c, 'files', '&rev=' + Rev);
        if(URL == null)
            return null;
        PageReference PR = new PageReference(URL);
        
        PR.setRedirect(true);  
        //system.debug('download url:' + PR.getURL());
        return PR;
    }
    
    public void RestoreVersion() {
        String Rev = ApexPages.currentPage().getParameters().get('theRevision');
        DropboxPopup DP = new DropboxPopup();
        String EndPoint = DP.URLGeneration(dropbox.URL__c, 'restore', '&rev=' + Rev);
        req.setTimeout(60000);
        req.setMethod('GET');
        if(EndPoint!=null)
            req.setEndPoint(EndPoint);
        if(!test.isRunningTest())
            res = h.send(req);
        system.debug('resBody:' + res.getBody());
        getRevision();
    }
    
    @isTest
    public static void testing() {
        Dropbox__c drop = [select URL__c from Dropbox__c order by CreatedDate desc limit 1];
        ApexPages.currentPage().getParameters().put('FileId', drop.Id);
        DropboxRevision DR = new DropboxRevision();
        DR.getFile();
        DR.RestoreVersion();
        
    }
}