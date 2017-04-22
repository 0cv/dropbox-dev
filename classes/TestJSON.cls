global class TestJSON{

    global class limeSurveyWebserviceObject{
        Integer survey;
        String status;
        String message;
        String token;
        String contact;
        Boolean success;
        DateTime timestamp;
    }

    public static void test() {
        string JSONString = '{"SURVEY":32483,"STATUS":"Success","MESSAGE":"Token already created, but is still valid","TOKEN":"UUA3W6Y27MYAMGY","SUCCESS":true,"CONTACT":"0034000000l68v3AAA", "Timestamp":"2014-02-12T15:12:12+02:00"}';
        limeSurveyWebserviceObject limeObject = (limeSurveyWebserviceObject) JSON.deserialize(JSONString, limeSurveyWebserviceObject.class);  
        insert new Account(Name='test', timestamp__c=limeObject.timestamp);
    }
}