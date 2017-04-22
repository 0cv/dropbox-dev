global class DropboxScheduleCleaning implements Schedulable {
    global void execute(SchedulableContext SC)  {  
    	if(SC != null)             
	    	abort(SC.getTriggerId());
	    	
        DropboxPeriodicCheck.AssignCurrentFolder();
        DropboxPeriodicCheck.RemoveUnusedContentVersion();
        String stc = '';
	    String nextFireTime = '0' + ' ' + '0' + ' ' + '1' + ' * * ?';  
	    DropboxScheduleCleaning s = new DropboxScheduleCleaning();
	    Id ScheduleId =  System.schedule('DropboxPeriodicCleaning Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
	  	DropboxConfig__c DC = DropboxConfig__c.getOrgDefaults();
	  	DC.ContentVersionAndCurrentFolderScheduleId__c = ScheduleId;
	  	update DC;
    }  

   private static void abort(String Id){ 
	  try{
	      	System.abortjob(Id);
	  }
	  catch(exception e) {
	  }
   } 
   
   @isTest
   public static void testing() {
       DropboxScheduleCleaning DSC = new DropboxScheduleCleaning();
       DSC.execute(null);
   }
}