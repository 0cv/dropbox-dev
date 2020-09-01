global class DropboxScheduleDeleteDropbox implements Schedulable {
    global void execute(SchedulableContext SC)  {
        if(SC != null)            
            abort(SC.getTriggerId());
        
         //The line of code below would contain the required business logic    
        DropboxPeriodicCheck.RemoveEmptyDropboxes();
    
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 10);
        String ss = String.valueOf(Datetime.now().second()); 
        
        if(Datetime.now().minute() + 10 > 59) {
            min='0'; 
            hour = String.valueOf(Datetime.now().hour()+1);
        }
        
        if(Datetime.now().hour() + 1 > 23) {
            hour = '0'; 
        }
        
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        DropboxScheduleDeleteDropbox s = new DropboxScheduleDeleteDropbox();
        Id ScheduleId =  System.schedule('DropboxPeriodicCheck Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
        DropboxConfig__c DC = DropboxConfig__c.getOrgDefaults();
        DC.RemoveScheduleId__c = ScheduleId;
        update DC;
   } 

   private static void abort(String Id){ 
      try{
            System.abortjob(Id);
      }
      catch(exception e) {
      }
   } 
   

}