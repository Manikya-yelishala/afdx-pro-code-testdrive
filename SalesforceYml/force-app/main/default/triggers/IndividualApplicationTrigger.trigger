trigger IndividualApplicationTrigger on IndividualApplication (after update) {
    
    // Two parallel lists to keep track of which Check belongs to which Application
    List<Crime_History_Check__c> checksToInsert = new List<Crime_History_Check__c>();
    List<IndividualApplication> appsToUpdate = new List<IndividualApplication>();
    
    for (IndividualApplication app : Trigger.new) {
        IndividualApplication oldApp = Trigger.oldMap.get(app.Id);
        
        // Check if the Application Status changed to 'Application Accepted'
        if (app.Status == 'Application Accepted' && oldApp.Status != 'Application Accepted') {
            
            // 1. Create the new Check record
            Crime_History_Check__c newCheck = new Crime_History_Check__c();
            newCheck.Category__c = app.Category;
            newCheck.Application_Type__c = app.ApplicationType;
            
            checksToInsert.add(newCheck);
            
            // 2. Create an in-memory Application record with the Id to update later
            IndividualApplication appToLink = new IndividualApplication();
            appToLink.Id = app.Id;
            
            appsToUpdate.add(appToLink);
        }
    }
    
    if (!checksToInsert.isEmpty()) {
        try {
            // 3. Insert the checks first so Salesforce generates their Ids
            insert checksToInsert;
            
            // 4. Loop through both lists using their index (0, 1, 2, etc.)
            // Since we added them at the same time, checksToInsert[0] belongs to appsToUpdate[0]
            for (Integer i = 0; i < checksToInsert.size(); i++) {
                appsToUpdate[i].Criminal_History_Check__c = checksToInsert[i].Id;
            }
            
            // 5. Update the Individual Applications with the newly generated Check Ids
            update appsToUpdate;
            
        } catch (DmlException e) {
            System.debug('Error processing Crime History Checks: ' + e.getMessage());
        }
    }
}