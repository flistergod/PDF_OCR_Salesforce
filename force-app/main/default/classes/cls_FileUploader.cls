/**
 * @description       : 
 * @author            : Flistergod
 * @group             : 
 * @last modified on  : 12-15-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   12-04-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/


/*
 * @class cls_FileUploader
 * @descripton -  This class lets you upload a file, in this case, a pdf file in salesforce, as long as
 * you give the file in 64string, his name and the id of the record (temporary)
 *
 * @example:
 *   cls_FileUploader.uploadFile(myBase64String, 'Invoice.pdf', '906F0000000kG2UIAU')
 */

public with sharing class cls_FileUploader {
    /*
   * @method uploadFile() 
   * @desc Creates a content version from a given base64 and name
   * 
   * @param {String} base64 - base64 string that represents the file
   * @param {String} filename - full file name with extension (extension already comes in the name) - 'cv.pdf'
   * @param {String} recordId - Id of the record you want to attach this file to - temporary
   * 
   * @return {ContentVersion} - returns the created ContentDocumentLink Id if the
   *   upload was successful, otherwise returns null
   * 
   * Try to return the public link of the pdf to use in ocr API
   */
 
      @AuraEnabled
    public static String uploadFileApex(String base64, String filename, String recordId) {
      
      String url='';
      Id jobId;
      ContentVersion cv = createContentVersionApex(base64, filename);
      ContentDocumentLink cdl = createContentLinkApex(cv.Id, recordId);
      ContentDistribution cd=createContentDistributionApex(filename, cv.Id);

      if (cv == null || cdl == null || cd==null) {return null;}
   
  
      try {

        /**
         * we will get the url from the pdf saved in salesforce
         * Then, we make an api call to the ocr, to get the parsed text by calling
         * the apex class cls_OCR_Handler
         * This class is a Queueable class, so we need to do a enqueue job
         * 
         * We have 2 options, use ocr space or azure ocr, they both work
         */

         //ocr space
        url=[SELECT ContentDownloadUrl FROM ContentDistribution WHERE Id=:cd.Id Limit 1].ContentDownloadUrl;
          I_OCR_Handler ocr= new cls_OCR_Space_Handler(url, recordId);
         jobId= System.enqueueJob(ocr);

         //azure ocr
         /**
          * How does azure ocr work?
          Azure ocr works with 2 api calls (a post and a get)
          Post - cls_OCR_Handler_Azure_POST
          Get - cls_OCR_Handler_Azure
          
          The pdf data comes on the get call, but we need an Id (operationId) to put on the get call
          That id can be found on the  post call
          So, first we do the post call, get the id, and then we do the get call
          We need to do 2 queueable jobs, and to avoid the scenario that the get call finishes first than the 
          post call, we need a trigger (OCR_GetResultsTrigger) on the post call and  a sleep threah on the get call
          We do the post call, save the operation Id on a field of the account (operationId__c)
          The trigger gets activated, runs the sleep  threah (while of 1 sec delay of the cpu of the salesforce)
          and runs the api call of the get

          The thing is, the get call always returns a json with a status field, that can be "succeded", failed" or
          "running", meaning that if  it isn't succeeded, we need to send the request again and again....
          We dont want that, so we put a delay, so that the Azure finishes reading the pdf data, and when we
          send a request, they already finished reading and the status of the json will be completed and
          with that, we can access the data with maps and lists.
         
         //calling post call
         I_OCR_HandlerAzure ocrPost= new cls_OCR_Handler_Azure_POST(url, recordId);
         System.enqueueJob(ocrPost);
          */
      
      } catch(Exception e) {
        System.debug(e.getMessage());
      }
    
        return 'https://customer-java-64752-dev-ed--c.documentforce.com/sfc/servlet.shepherd/version/download/'+cv.Id;        
    }
    
     /*
   * @method createContentVersion() [private]
   * @desc Creates a content version from a given file's base64 and name
   * 
   * @param {String} base64 - base64 string that represents the file
   * @param {String} filename - full file name with extension
   * 
   * @return {ContentVersion} - returns the newly created ContentVersion, or null
   *   if there was an error inserting the record
   */
    
    private static ContentVersion createContentVersionApex(String base64, String filename) {
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
   	    cv.Title = filename;
    	cv.PathOnClient = filename;
        
        try{
            insert cv;
             return cv;
        }catch(DMLException e){
            System.debug(e);
      return null;
        }
    
    }
    
       
  /*
   * @method createContentLink() [private]
   * @desc Creates a content link for a given ContentVersion and record
   * 
   * @param {String} contentVersionId - Id of the ContentVersion of the file
   * @param {String} recordId - Id of the record you want to attach this file to
   * 
   * @return {ContentDocumentLink} - returns the newly created ContentDocumentLink, 
   *   or null if there was an error inserting the record
   */
  private static ContentDocumentLink createContentLinkApex(String contentVersionId, String recordId) {
            
    if (contentVersionId == null || recordId == null) { return null; }
    
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion 
                            WHERE Id =: contentVersionId].ContentDocumentId;
    
    cdl.LinkedEntityId = recordId;
    // ShareType is either 'V', 'C', or 'I'
    // V = Viewer, C = Collaborator, I = Inferred
    cdl.ShareType = 'V';
    cdl.Visibility='AllUsers';


    try {

      insert cdl;
      return cdl;

    } catch(DMLException e) {
      System.debug(e);
      return null;
    }
  }
  
      /*
   * @method ContentDistribution() [private]
   * @desc Creates a content Distribution for a given filename and ContentVersion Id
   * 
   * @param {String} contentVersionId - Id of the ContentVersion of the file
   * @param {String} fileName - Name of the file
   * 
   * @return {ContentDistribution} - returns the newly created ContentDistribution, 
   *   or null if there was an error inserting the record
   */
  private static ContentDistribution createContentDistributionApex(String fileName, String contentVersionId) {
  
    if (fileName == null || contentVersionId == null) { return null; }

    ContentDistribution cd = new ContentDistribution();
    cd.Name = fileName;
    cd.ContentVersionId = contentVersionId;
    cd.PreferencesAllowViewInBrowser= true;
    cd.PreferencesLinkLatestVersion=true;
    cd.PreferencesNotifyOnVisit=false;
    cd.PreferencesPasswordRequired=false;
    cd.PreferencesAllowOriginalDownload= true;

try {
 
  insert cd;
  return cd;

} catch(DMLException e) {
System.debug(e);
return null;
}
}
    
}