public with sharing class PanicButtonServerController {
	@AuraEnabled
    public static List<SoundClip__c> getMedia() {
        return [Select name, url__c from SoundClip__c];
    }

	
}