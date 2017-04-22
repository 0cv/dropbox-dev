public class GetUser {
    @AuraEnabled
    public static User get() {
        
        return [Select FirstName, LanguageLocaleKey, MyNewField__c from User Where UserName = 'christophe.vidal@89demo.com' Limit 1].get(0);
    }
}