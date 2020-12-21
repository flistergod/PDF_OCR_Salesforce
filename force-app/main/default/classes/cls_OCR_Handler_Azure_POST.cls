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
public with sharing class cls_OCR_Handler_Azure_POST implements Queueable, Database.AllowsCallouts, I_OCR_Handler {
    
    String url, recordId, operationId;
    String parsed_text='';
    String HEADER_API_KEY='Ocp-Apim-Subscription-Key';
    String API_KEY='43c8b414ad7240dc9d61fa09d209804c';
    String ENDPOINT='https://flistergodocr.cognitiveservices.azure.com/vision/v3.2-preview.1/read/analyze?language=en&pages=1';


    public cls_OCR_Handler_Azure_POST(String url_param, String recordId_param) {

        this.url=url_param;
        this.recordId=recordId_param;
      
     } 

        /*
      *
      * With the url defined in the constructor, we only have to prepare the httprequest
      * Prepare the api key, the header.
      * if the reponseCode is 202, he handle the api response
      * to handle the response, we only want the operationId
      * The operationId is on the headers, so we get it with - "response.getHeader('apim-request-id')"
      * and save it on the account wih recordId
      * This will activate the OCR_GetResultsTrigger

      * On queuable jobs, we cant check errors with system.debug, so i save the errors on the field of the acc
     - ParsedText__c
      *       */

    public void execute(QueueableContext context) {

        postOCR();
       updateField();
   
   }

   /**
    * Post ocr makes a httprequest call
    * We prepare the body, the endpoint, api key and the multiple headers
    * we send the request, check if the response is 202 (success)
    * and save the header (operationId) on the account (field - operationId__c)
    */
   private String postOCR(){

        String operationId='';
        String body='{"url":"'+this.url+'"}';
        this.parsed_text+='\nbody: '+body;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(this.ENDPOINT);
        this.parsed_text+='\nendpoint: '+this.ENDPOINT;
        request.setHeader(this.HEADER_API_KEY, this.API_KEY);
        this.parsed_text+=this.HEADER_API_KEY+' : '+this.API_KEY;
        request.setHeader('Content-Type','application/json');
        request.setMethod('POST');
        request.setHeader('Connection', 'keep-alive');
        request.setTimeout(100000);        
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization',' ');
        request.setBody(body);

        try {
        
        HttpResponse response = http.send(request);
    
        if (response.getStatusCode() == 202) {

           operationId=response.getHeader('apim-request-id');
           this.operationId=response.getHeader('apim-request-id');
           this.parsed_text+='\nstatuscodeOnPost: '+response.getStatusCode()+'\nOpId: '+operationId;
    
            }
            else{

               System.debug('bad code response on post: '+response.getStatusCode()); 
               this.parsed_text+='bad responsecode on post';

              }

        } catch (Exception e) {
           this.parsed_text+=e.getMessage()+' on post';
        }

     return operationId;
   }

  

   /**Update the acc field operationId__c */
   public  void updateField(){

     Account a=[SELECT Id, operationId__c , ParsedText__c FROM Account WHERE Id=:this.recordId];
       a.operationId__c= this.operationId;
    
       update a;
   }
}