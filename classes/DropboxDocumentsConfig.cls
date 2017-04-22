public with sharing class DropboxDocumentsConfig {
	public Dropbox__c Dropbox{get;set;}
	public String AlertMessage{get;set;}
	public String Type{get;set;}
	public String Subtitle{get;set;}
	public String PublicPrivate{get;set;}
	
	public DropboxDocumentsConfig() {
		PublicPrivate = ApexPages.currentPage().getParameters().get('publicprivate');
		AlertMessage = '';
		Type = ApexPages.currentPage().getParameters().get('type');
		String Folder = '';
		Subtitle = 'new Folder';
		if(Type == 'edit') {
			Folder = ApexPages.currentPage().getParameters().get('folder');
			try {
				if(PublicPrivate == 'private')
					Dropbox = [select Folder__c, Folder_Label__c from Dropbox__c where Folder__c =: Folder AND UserPrivateFolder__c =: UserInfo.getUserId() limit 1];
				else
					Dropbox = [select Folder__c, Folder_Label__c from Dropbox__c where Folder__c =: Folder AND UserPrivateFolder__c = null limit 1];
				Subtitle = Dropbox.Folder__c;
			}
			catch(exception e) {
				AlertMessage = 'Folder was not found';
			}
		}
		else if(Type == 'new') {
			Dropbox = new Dropbox__c();
		}	
	}
	
	public void save() {
		list<Dropbox__c> Dropboxes;
		if(PublicPrivate == 'private') {
			try{
				Dropboxes = new list<Dropbox__c>([select id from Dropbox__c where Folder__c =: dropbox.Folder__c AND Id !=: dropbox.Id AND UserPrivateFolder__c =: UserInfo.getUserId()]);
			}catch(Exception e){}
		}
		else
			Dropboxes = new list<Dropbox__c>([select id from Dropbox__c where Folder__c =: dropbox.Folder__c AND Id !=: dropbox.Id AND UserPrivateFolder__c = null]);
		if(Dropboxes!= null && !Dropboxes.isEmpty()) {
			AlertMessage = 'This folder exists already!';
		}
		else {
			if(PublicPrivate == 'private') {
				try{
					dropbox.UserPrivateFolder__c = UserInfo.getUserId();
				}catch(Exception e){}	
			}
			try{
				upsert dropbox;
			}catch(Exception e){}
		}
	}
	
	@isTest
	public static void testing() {
		User u = [select id from User where isActive = true limit 1];
		system.runAs(u) {
			ApexPages.currentPage().getParameters().put('type', 'edit');
			DropboxDocumentsConfig DDC = new DropboxDocumentsConfig();
			DDC.save();
			
			ApexPages.currentPage().getParameters().put('publicprivate', 'private');
			DropboxDocumentsConfig DDC2 = new DropboxDocumentsConfig();
			DDC2.save();
			
			ApexPages.currentPage().getParameters().put('type', 'new');
			DropboxDocumentsConfig DDC3 = new DropboxDocumentsConfig();
		}
	}
	
}