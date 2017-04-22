global class oneMinuteSchedule implements Schedulable {
    global void execute(SchedulableContext SC)  {     

        //we cancel the previous schedule. 
        if(SC!=null) {
            abort(SC.getTriggerId());
        }
        system.debug('testing ... : ' + UserInfo.getSessionId());
        //business logic
        call();
        //end of business logic
        
        //we create our new schedule.
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        
        if(Datetime.now().minute() + 1 > 59) {
            min='0';
            hour = String.valueOf(Datetime.now().hour()+1); 
        }
                
        if(Integer.valueOf(hour) > 23) {
            hour = '0'; 
        }
        
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        oneMinuteSchedule s = new oneMinuteSchedule();

        //we execute it here. it's a one minute schedule according to the previous definition.
        System.schedule('Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
    } 
    
    private static void abort(String Id){ 
        try{
            //cancel method.
            System.abortjob(Id);
        }
        catch(exception e) {
        }
    }   

    @future(callout=true) 
    public static void call() {
    	ReportExportController rec = new ReportExportController();
        rec.format = 'xls';
        rec.reportId = '00Od0000003FL9N';

        String myContent = rec.getOutput();
        system.debug('myContent: ' + myContent);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		// Strings to hold the email addresses to which you are sending the email.
		String[] toAddresses = new String[] {'krisallyde@gmail.com'}; 
		mail.setToAddresses(toAddresses);

		// Specify the subject line for your email address.
		mail.setSubject('New Report');

		// Specify the text content of the email.
		mail.setPlainTextBody(myContent);

		mail.setHtmlBody(myContent);

		// Send the email you have created.
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }  
}