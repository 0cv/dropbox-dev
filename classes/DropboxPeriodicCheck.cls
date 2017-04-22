public class DropboxPeriodicCheck  {
	
	//@future(callout=true)
	public static void AssignCurrentFolder() {
		DropboxConfig__c DC = DropboxConfig__c.getOrgDefaults();
		DropboxPopup DP = new DropboxPopup();
		String result = DP.CheckEmptyFolder(UserInfo.getOrganizationId() + '/' + DC.CurrentFolderNumber__c, null );
		//Document d = new Document(Body = Blob.valueOf(result), Name = 'test.txt', FolderId = '00lU0000000darA');
		//insert d; 
		//system.debug('result:' + result); 
		DropboxPopup.metadataFolderList metaObj = new DropboxPopup.metadataFolderList();
		Type wrapperType = Type.forName('DropboxPopup.metadataFolderList'); 
		try {
			metaObj = (DropboxPopup.metadataFolderList)JSON.deserialize(result, wrapperType);
			system.debug('FolderSize:' + metaObj.contents.size());
			if(metaObj.contents.size() > 9000) 
				DC.CurrentFolderNumber__c = String.valueOf(Integer.valueOf(DC.CurrentFolderNumber__c) + 1);
			update DC;
		}
		catch(exception e){
			system.debug('result:' + result); 
		}
	} 
	    
    public static void RemoveUnusedContentVersion() {
    	list<ContentVersion> CVList = new list<ContentVersion>([select CreatedDate, ContentDocumentId from ContentVersion where Description = 'ContentToDeleteUploadedByTheAppSalesforce2Dropbox' limit 9900]);   
        list<Id> ContentDocumentIds = new list<Id>();
        for(ContentVersion CV:CVList) {
            if(CV.CreatedDate.addHours(1) < system.now())
                ContentDocumentIds.add(CV.ContentDocumentId);
        }
        database.delete(ContentDocumentIds);
    }  
     
	public static void RemoveEmptyDropboxes() {
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Dropbox__c').getDescribe().fields.getMap();   
		String query = 'select id, ParentId__c from Dropbox__c where Folder__c = null AND DropboxDocument__c = null AND '; 
        for(String field:objectFields.keySet()) {
        	if(objectFields.get(field).getDescribe().getType() == Schema.DisplayType.Reference && field != 'ownerid' && field != 'createdbyid' && field != 'lastmodifiedbyid')
        		query += field + ' = null AND ';
        }          
		if(query.endsWith('AND '))
			query = query.substring(0, query.length() - 4); 
		list<Dropbox__c> Dropboxes = new list<Dropbox__c>((list<Dropbox__c>)Database.query(query));
		if(!Dropboxes.isEmpty()) {
			set<Id> ParentIds = new set<Id>();
			for(Dropbox__c DP:Dropboxes) {
				try {
					Id test = DP.ParentId__c;
				} 
				catch(exception e) {
					delete DP;
					break;
				}
				if(!ParentIds.contains(DP.ParentId__c))
					ParentIds.add(DP.ParentId__c);
				if(ParentIds.size() >= 10)
					break;
			}
			String result = '';
			list<Id> DropboxIds2Delete = new list<Id>();
			DropboxOverrideController OC = new DropboxOverrideController(null);
			list<ErrorLog__c> Logs = new list<ErrorLog__c>();
			ErrorLog__c Log = new ErrorLog__c();
			if(ParentIds != null) {
				for(Id PI:ParentIds) {
					result = OC.doRequest(null, PI); 
					if(result != null ) {
			            if(!result.contains('{"error":') || result.contains(' not found"}')) {	            
				            DropboxIds2Delete.add(PI);
				        }
				        else {
				        	Log = new ErrorLog__c();
				        	Log.ErrorId__c = PI;
				        	Log.ErrorClass__c = 'DropboxPeriodicCheck.RemoveEmptyDropboxes';
				        	Log.ErrorMessage__c = result;
				        	Logs.add(Log);
				        }
		            }  
				}
			}
			if(!Logs.isEmpty()) 
				insert Logs;
			
			list<Dropbox__c> Dropboxes2Delete = new list<Dropbox__c>([select id from Dropbox__c where ParentId__c IN: DropboxIds2Delete]);
			delete Dropboxes2Delete;
		}
	}
	
	@isTest
	public static void testing() {
		User u = [select id from user where isActive = true and Profile.Name LIKE '%admin%'  limit 1];
		system.runAs(u) {
			DropboxOverrideController doc = new DropboxOverrideController(null);
			doc.isDocument = false;
			Dropbox__c drop = new Dropbox__c();
	        insert drop;
			DropboxPeriodicCheck.RemoveEmptyDropboxes();

			DropboxPeriodicCheck.AssignCurrentFolder();
		}
	}
	
	@isTest
	public static void testing2() {
        User u = [select id from user where isActive = true and Profile.Name LIKE '%admin%' limit 1];
        system.runAs(u) {
            Dropbox__c drop = new Dropbox__c();
            insert drop;    
            DropboxPeriodicCheck.RemoveUnusedContentVersion();
        }
    }
    
    @isTest
    public static void testing3() {
        DropboxPeriodicCheck.AssignCurrentFolder();
    }
}