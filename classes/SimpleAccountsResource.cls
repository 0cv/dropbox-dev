@RestResource(urlMapping='/simpleAccounts/*')
global with sharing class SimpleAccountsResource {
    @HttpGet global static SimpleAccountsList doGet() {
        String namePattern = 
            RestContext.request.params.get('namePattern');
        List<SimpleAccount> records = new List<SimpleAccount>();
        for (SObject sobj : Database.query(
            'select Id, Name from Account where Name like \'' + namePattern + '\'')) {  
                 Account acc = (Account) sobj;
                   records.add(new SimpleAccount(acc.Id, acc.Name));
        }
        return new SimpleAccountsList(records.size(), records);
    }
    
    global class SimpleAccountsList {
        global Integer totalSize;
        global List<SimpleAccount> records;
        
        global SimpleAccountsList(Integer totalSize, 
            List<SimpleAccount> records) {
                this.totalSize = totalSize;
                this.records = records;
        }
    }
    
    global class SimpleAccount {
        global String accountId;
        global String accountName;
        
        global SimpleAccount(String accountId, String accountName) 
        {
            this.accountId = accountId;
            this.accountName = accountName;
        }
    }
}