public with sharing class CreateEditExtensionController {

    public Opportunity Opportunity{get;set;}
    public Account Account{get;set;}
    
    private String sObjectType;
    private String sObjectRecordType;
    private String Title;
    private String Subtitle;
    private Set<String> allFields;
    private transient Component.Apex.Form Form;

    private Map<String, sObjectField> schemaFields;
    
    
    public CreateEditExtensionController(ApexPages.StandardController standardControllerRec) {
        Opportunity = new Opportunity(); 
        Account = new Account();

        allFields = new Set<String>();
        
        //Small bug with the "addFields" method of Salesforce and this is
        //the only way I found to find from where object the request comes from.
        sObjectType = ApexPages.currentPage().getUrl().toLowerCase().split('/apex/ac')[1].split('\\?')[0];

        //we describe the object and put all fields in this variable.
        schemaFields = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
        Set<String> FieldssObject = new Set<String>(schemaFields.keySet());
        
        //we add all available fields so that we don't get an error.
        //standardControllerRec.addFields(new list<String>(FieldssObject));
        //standardControllerRec.addFields(new list<String>{'RecordTypeId'});
        String myId = standardControllerRec.getId();

        sObject mySObject;
        if(myId!=null){
            mySObject = database.query('select '+ String.join(new list<String>(FieldssObject), ',') +' from ' + sObjectType + ' where Id=:myId');
        }

        sObjectRecordType = null;

        //in case we have the recordtype in the url.
        //happens when the user goes through the creation wizard (like for account)
        if(ApexPages.currentPage().getParameters().containsKey('RecordType')) {
            sObjectRecordType = ApexPages.currentPage().getParameters().get('RecordType');
        }
        else if(FieldssObject.contains('recordtypeid')){
            //if this wasn't successful, maybe we can get the recordtypeid for an existing record.
            sObjectRecordType = (String)mySObject.get('recordtypeid');
        }
        //last else: would be in case the record doesn't have any recordtype.

        //we have just one page for edition and creation. Therefore we need that the labels are a bit
        //dynamic.
        

        Title = Schema.getGlobalDescribe().get(sObjectType).getDescribe().getLabel() + ' edit';
            
        if(mySObject==null||mySObject.Id==null){
            //clicked on create
            Subtitle = 'New ' + Schema.getGlobalDescribe().get(sObjectType).getDescribe().getLabel();
        }
        else {
            //object edit
            Subtitle = (String)mySObject.get('name');
        }
        
        getForm();

        if(!Test.isRunningTest()){
            //internal server error, if the test goes here...
            standardControllerRec.addFields(new list<String>(allFields));
        }

        //workaround for setting correctly the recordtype if the user clicks on the link
        //"change recordtype" in the read-only layout mode.
        //We don't need to make that on other objects which don't have a recordtype
        if(sObjectType=='Opportunity'){
            Opportunity = (Opportunity)standardControllerRec.getRecord();
        }
        else if(sObjectType=='Account'){
            Account = (Account)standardControllerRec.getRecord();
        }

        if(ApexPages.currentPage().getParameters().containsKey('RecordType')) {
            //We may need to write the recordtype if it's present as url parameter
          }
                                        
    }

    public list<SelectOption> getSalutation() {
        list<SelectOption> items = new list<SelectOption>();
        
        for(Schema.PicklistEntry picklist:Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get('Salutation').getDescribe().getPickListValues()) {
            items.add(new SelectOption(picklist.getLabel(), picklist.getValue()));
        }
        
        return items;
    }

    public Component.Apex.Form getForm() {
        // we query the layout and rebuild it as it is in the standard interface. There shouldn't be any
        // difference between the standard layout and this layout.
        //The only method to achieve that is by using the Soap Resources.
        //For that we make a request on the Soap Partner endpoint.

        if(Form==null){
            Form = new Component.Apex.Form();
            Form.id = 'form';
            Set<String> rerenderFields = new Set<String>();
            Set<String> controllerFields = new Set<String>();
            Component.Apex.sectionHeader sectionHeader = new Component.Apex.sectionHeader();
            sectionHeader.subtitle = subtitle;
            sectionHeader.title = title;
            Form.childComponents.add(sectionHeader);

            Component.Apex.pageBlock pageBlock = new Component.Apex.pageBlock();
            pageBlock.id = 'pageBlock';
            pageBlock.mode = 'edit';
            pageBlock.title = title;
            
            Component.Apex.pageBlockSection pBS;
            Component.Apex.InputField inputField;
            Component.Apex.InputText inputText;
            Component.Apex.InputHidden inputHidden;
            Component.Apex.Selectlist selectlist;
            Component.Apex.SelectOptions selectOptions;

            sobjectPartnerSoapSforceCom.Soap handler = HandlerMetadataInit();

            if(!test.isRunningTest()) {
                //if running test, we can't make a callout, so this won't work.
                //sObjectRecordType is the recordtype of the sobject. If the sobject has no recordtype, then it's null and it's still fine.
                sobjectPartnerSoapSforceCom.DescribeLayoutResult LayoutResult = handler.describeLayout(sObjectType, new list<String>{sObjectRecordType});

                if(LayoutResult != null) {
                    //we take the first one because we queried only one recordtype.               
                    for(sobjectPartnerSoapSforceCom.DescribeLayoutSection LayoutSection:LayoutResult.Layouts.get(0).editLayoutSections) {
                        //the different sections.
                        pBS = new Component.Apex.pageBlockSection(
                            columns = LayoutSection.columns
                        );

                        if(LayoutSection.useHeading == true) {
                            pBS.title=LayoutSection.heading;
                        }

                        for(sobjectPartnerSoapSforceCom.DescribeLayoutRow layoutRow:LayoutSection.layoutRows) {
                            for(sobjectPartnerSoapSforceCom.DescribeLayoutItem layoutItem:layoutRow.layoutItems) {
                               if(layoutItem.layoutComponents!=null){
                                    //here the fields.
                                    for(sobjectPartnerSoapSforceCom.DescribeLayoutComponent layoutComponent:layoutItem.layoutComponents){
                                        if(layoutComponent.value=='OwnerId' || layoutComponent.value=='RecordTypeId' ){
                                            //The user shouldn't change the OwnerId/RecordType this way.
                                        }
                                        else if(sObjectType=='account' && (layoutComponent.value=='LastName' || layoutComponent.value=='FirstName' )) {
                                            inputText = new Component.Apex.InputText(
                                                id = layoutComponent.value
                                            );
                                            inputText.expressions.value = '{!'+sObjectType+'.' + layoutComponent.value + '}';
                                                
                                            pBS.childComponents.add(inputText);
                                            allFields.add(layoutComponent.value);
                                            rerenderFields.add(layoutComponent.value);
                                        }
                                        else if(sObjectType=='account' && layoutComponent.value=='Salutation'){
                                            selectlist = new Component.Apex.Selectlist(
                                                size = 1,
                                                multiselect = false
                                            );
                                            selectlist.expressions.value = '{!'+sObjectType+'.' + layoutComponent.value + '}';

                                            selectOptions = new Component.Apex.SelectOptions();
                                            selectOptions.expressions.value = '{!Salutation}';
                                            selectlist.childComponents.add(selectOptions);
                                            rerenderFields.add(layoutComponent.value);
                                            pBS.childComponents.add(selectlist);
                                        }
                                        else if(layoutComponent.value!=null ){
                                            inputField = new Component.Apex.InputField(
                                                required = layoutItem.required,
                                                id = layoutComponent.value
                                            );
                                            inputField.expressions.value = '{!'+sObjectType+'.' + layoutComponent.value + '}';
                                            pBS.childComponents.add(inputField);
                                            allFields.add(layoutComponent.value);

                                            //we store the controller fields, because we shouldn't rerender them - causing a bug...
                                            //rerendering a controlled fields makes the value disappear
                                            if(schemaFields.get(layoutComponent.value).getDescribe().isDependentPicklist()){
                                                controllerFields.add(schemaFields.get(layoutComponent.value).getDescribe().getController().getDescribe().getName() );
                                            }
                                        }
                                    }
                                }
                                else {
                                    //small workaround for adding empty fields when the layout require it
                                    //in order to reproduce to 100% the standard layout.
                                    pBS.childComponents.add(new Component.Apex.OutputText());
                                }
                               
                            }
                        }
                        pageBlock.childComponents.add(pBS);
                    }
                }
            }
            Component.Apex.pageBlockButtons pageBlockButtons = new Component.Apex.pageBlockButtons();

            Component.Apex.commandButton commandButton = new Component.Apex.commandButton();
            commandButton.expressions.action = '{!save}';
            commandButton.id='saveBtn';
            commandButton.expressions.value = '{!$label.site.save}';
            commandButton.onclick = 'fnSaveValuesAndCheck();';
            commandButton.oncomplete = 'fnLoadInputValues();';
            rerenderFields.add('pageMessage');

            //we remove the controller fields from the rerenderFields
            rerenderFields.removeAll(controllerFields);

            commandButton.rerender = rerenderFields;
            pageBlockButtons.childComponents.add(commandButton);

            commandButton = new Component.Apex.commandButton();
            commandButton.expressions.action = '{!cancel}';
            commandButton.id='cancelBtn';
            commandButton.expressions.value = '{!$label.site.cancel}';
            pageBlockButtons.childComponents.add(commandButton);

            pageBlock.childComponents.add(pageBlockButtons);

            Form.childComponents.add(pageBlock);
        }

        return Form;
    }

    public static sobjectPartnerSoapSforceCom.Soap handlerMetadataInit() {
        //here the authentication to the soap partner.
        //we build something quite dynamic which does not depend on any url (like cs17.salesforce.com)
        //therefore, should work for production like for sandbox, however the remote site settings
        //needs to be updated in Salesforce in Order to allow this outbound communication.

        sobjectPartnerSoapSforceCom.Soap handler = new sobjectPartnerSoapSforceCom.Soap();

        handler.endpoint_x = 'https://' + System.URL.getSalesforceBaseURL().getHost().split('\\.')[1]  + '-api.salesforce.com/services/Soap/u/27.0/' + UserInfo.getOrganizationId();
        
        sobjectPartnerSoapSforceCom.SessionHeader_element sessionHeader = new sobjectPartnerSoapSforceCom.SessionHeader_element();
        sessionHeader.sessionId = UserInfo.getSessionId();
        handler.SessionHeader = sessionHeader;
        return handler; 
    }

}