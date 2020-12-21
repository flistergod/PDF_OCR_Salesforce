/**
 * @description       : 
 * @author            : Flistergod
 * @group             : 
 * @last modified on  : 12-15-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   12-14-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger OCR_GetResultsTrigger  on Account (after update) {

    /**
     * Trigger activated on  an account after updating a field
     * 
     * We only want to activate this trigger if the field operationId__c changes
     * If it changes, we want to make a queueable job
     * for that we need the Id and operationId (new) of the acc
     * we make a while for a delay of 1 sec, so that the api call that we are about to make with
     * the queueable job, returns a json with the status==succeeded
     */
   

   List<Account> newAccs =  Trigger.new;
   List<Account> oldAccs =  Trigger.old;

   if(newAccs[0].operationId__c != oldAccs[0].operationId__c){

    String recordId_param=newAccs[0].Id;
    String operationId_param=newAccs[0].operationId__c;

  datetime start =System.Now();
  while(System.Now()<start.addseconds(2)){}

 
   

    I_OCR_Handler ocrGet=new cls_OCR_Handler_Azure_GET(operationId_param, recordId_param);
    System.enqueueJob(ocrGet);

    

}


            

}