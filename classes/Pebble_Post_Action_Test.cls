@isTest
public class Pebble_Post_Action_Test {

    static testMethod void Pebble_Post_Action() {
        
        
		//Create the APP
        Pebble_App__c pa = new Pebble_App__c();
        pa.Name = 'Test App';
        pa.AppTitle__c = 'App Title';
        insert pa;
 
        system.debug('<<<<<<<<<< Now test the new CHATTER function >>>>>>>>>>>>>>>');
        
        //Now add two rows to the App
        //The first row is for the string to be posted
        Pebble_Row__c pr1 = new Pebble_Row__c();
        pr1.Pebble_App__c = pa.Id;
        pr1.Row__c = 1;
        pr1.Priority__c = 1;
        pr1.Custom_Detail__c = 'IsTest Chatter Post';
        pr1.Custom_Note__c = 'Chat Note';
        insert pr1;
        //Now get the system generated feild 'Name' from the new record
        pr1 = [SELECT Name, Custom_Note__c FROM Pebble_Row__c WHERE Id = :pr1.Id];

        //The second row is for the UUID to attach the pst
        Pebble_Row__c pr2 = new Pebble_Row__c();
        pr2.Pebble_App__c = pa.Id;
        pr2.Row__c = 2;
        pr2.Priority__c = 1;
        //The Custom Note is the UUID of where the post is going to be attached
        //You can use record so make it easy and just attach to the Pebble App record
        pr2.Custom_Note__c = pa.Id;
        insert pr2;
        //Now get the system generated feild 'Name' from the new record
        pr2 = [SELECT Name, Custom_Note__c FROM Pebble_Row__c WHERE Id = :pr2.Id];

        //Now build the Post
        Pebble_Post__c pp = new Pebble_Post__c();
        pp.Pebble_App__c = pa.Id;
        pp.Initiating_Row__c = pr2.Id;
        system.debug('CaseTest-' + pr2.Name + '-' + pr1.Name);
        pp.Row_Codes__c = 'ChatTest-' + pr2.Name + '-' + pr1.Name ;
        pp.Action__c = 'Chatter';

		//This insert will initate the Pebble_Post_Chatter trigger        
        insert pp;

        
        //Now build the Post that will fail to test the TRY/Catch code
        Pebble_Post__c pf = new Pebble_Post__c();
        pf.Pebble_App__c = pa.Id;
        pf.Initiating_Row__c = pr2.Id;
        pf.Action__c = 'Chatter';

		//This insert will initate the Pebble_Post_Chatter trigger        
        insert pf;      
        
        system.debug('<<<<<<<<<< Now test the new CASE function >>>>>>>>>>>>>>>');
		// Verify that the initial state is as expected.
		Integer a = [SELECT Count() FROM Case];
        system.debug('Found ' + a + ' records and expected none.');
		System.assertEquals(0, a);
        //First create a CONTACT for this test
		Contact ct = new Contact();
        ct.firstName = 'Dan';
        ct.lastName = 'Harrison';
        insert ct;
        
        //Now add two rows to the App
        //The first row is for the Priority
        Pebble_Row__c cr1 = new Pebble_Row__c();
        cr1.Pebble_App__c = pa.Id;
        cr1.Row__c = 1;
        cr1.Priority__c = 1;
        cr1.Custom_Note__c = 'Low';
        insert cr1;
        //Now get the system generated feild 'Name' from the new record
        cr1 = [SELECT Name, Custom_Note__c FROM Pebble_Row__c WHERE Id = :cr1.Id];
        
		system.debug('cr1 Name:'+cr1.Name + cr1.Id);

        //The second row is for the Contact
        Pebble_Row__c cr2 = new Pebble_Row__c();
        cr2.Pebble_App__c = pa.Id;
        cr2.Row__c = 2;
        cr2.Priority__c = 1;
		//The contact for the test will be BLANK
        system.debug('DEBUG: Got a Contact ID:'+ ct.Id);
        String id15 = ct.Id;
        id15 = id15.substring(0,15);
		cr2.Custom_Note__c = id15;
        insert cr2;
        //Now get the system generated feild 'Name' from the new record
        cr2 = [SELECT Name, Custom_Note__c FROM Pebble_Row__c WHERE Id = :cr2.Id];

        //The third row is for the Type
        Pebble_Row__c cr3 = new Pebble_Row__c();
        cr3.Pebble_App__c = pa.Id;
        cr3.Row__c = 3;
        cr3.Priority__c = 1;
        cr3.Custom_Note__c = 'Test Type';
        cr3.Custom_Detail__c = 'Test line for subject';
        insert cr3;
        //Now get the system generated feild 'Name' from the new record
        cr3 = [SELECT Name, Custom_Note__c FROM Pebble_Row__c WHERE Id = :cr3.Id];

        //Now build the Post
        Pebble_Post__c pp2 = new Pebble_Post__c();
        pp2.Pebble_App__c = pa.Id;
        pp2.Initiating_Row__c = cr2.Id;
        pp2.Short_Code__c = 'test-aa-bb';
        system.debug('CaseTest-' + cr1.Name + '-' + cr2.Name + '-' + cr3.Name);
        pp2.Row_Codes__c = 'CaseTest-' + cr1.Name + '-' + cr2.Name + '-' + cr3.Name;
        pp2.Action__c = 'Case';

		//This insert will initate the Pebble_Post_Chatter trigger        
        insert pp2;
        a = [SELECT Count() FROM Case];
        system.debug('Found ' + a + ' records and expected one.');

        system.debug('DEBUG: Insert Completed record for Test Class.');

        
        //Now build the Post that will fail to test the TRY/Catch code
        Pebble_Post__c pf2 = new Pebble_Post__c();
        pf2.Pebble_App__c = pa.Id;
        pf2.Initiating_Row__c = cr2.Id;
        pf2.Short_Code__c = 'test-aa-bb';
        system.debug('CaseTest-' + cr1.Name + '-' + cr2.Name + '-' + cr3.Name);
        pf2.Row_Codes__c = 'Fail';
        pf2.Action__c = 'Case';

        insert pf2;
        a = [SELECT Count() FROM Case];  //still only should have one record
		System.assertEquals(1, a);

        system.debug('DEBUG: Insert Incomplete record for Test Class.');
        
    }
}