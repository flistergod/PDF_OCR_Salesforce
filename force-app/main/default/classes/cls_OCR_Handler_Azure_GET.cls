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
public with sharing class cls_OCR_Handler_Azure_GET implements Queueable, Database.AllowsCallouts, I_OCR_Handler {
    String recordId, operationId;
    String parsed_text='';
    String HEADER_API_KEY='Ocp-Apim-Subscription-Key';
    String API_KEY='43c8b414ad7240dc9d61fa09d209804c';
    String ENDPOINT_GET='https://flistergodocr.cognitiveservices.azure.com/vision/v3.2-preview.1/read/analyzeResults/';
                        

     public cls_OCR_Handler_Azure_GET(String operationId_param, String recordId_param) {

        this.recordId=recordId_param;
        this.operationId=operationId_param;
     } 


     /*
      *
      * With the operationId and recordId defined in the constructor, we only have to prepare the httprequest
      * Prepare the api key, the headers and endpoint. (the endpoint needs the operationId)
      * if the reponseCode is 200, handle the api response
      * to handle the response, we need to transform the data received from the api to a string
      * deserialize the json into a map, get the map from the key value "analyzeResult", 
      * get the list from the key value "readResults", get the map from index 0, get list from key value "lines".
      * Transform each object from list into a map and get each line from pdf by getting the key value "text".
      * after that, we save the text in a field (ParsedText__c) of the account

      * On queuable jobs, we cant check errors with system.debug, so i save the errors on the field of the acc
        - ParsedText__c (if there are no errors, it only shows the text of the pdf, otherwise, it only shows
        the errors)
      *       */

    public void execute(QueueableContext context) {

      
        getReadResults(this.operationId);
        updateField();
    
    }

    /**
     * prepare endpoint, apikey and headers
     * If responsecode==200, prepare the structures (mpas, lists) to retrieve the pdf data
     */
    private  void getReadResults(String operationId){
     

         Http http = new Http();
         HttpRequest request = new HttpRequest();

         request.setEndpoint(this.ENDPOINT_GET+operationId);
         request.setHeader(this.HEADER_API_KEY, this.API_KEY);
         request.setHeader('Content-Type','text/plain');
         request.setMethod('GET');
         request.setHeader('Connection', 'keep-alive');
         request.setTimeout(100000);        
         request.setHeader('Accept', '*/*');
         request.setHeader('Authorization',' ');
         request.setHeader('Accept-Encoding','gzip, deflate, br');
       

      try {
      
         HttpResponse response = http.send(request);

      if (response.getStatusCode() == 200) {

         response = http.send(request);
          Map<String,Object> results= (Map<String,Object>)  JSON.deserializeUntyped(response.getBody());
          Map<String,Object> analyzedText= (Map<String,Object>)  results.get('analyzeResult');
          List<Object> textResults= (List<Object>)  analyzedText.get('readResults');
          Map<String,Object> textLines= (Map<String,Object>)  textResults[0];
          List<Object> lines= (List<Object>)  textLines.get('lines');
   

          for(Integer i=0;i<lines.size();i++){
              
                Map<String,Object> line= (Map<String,Object>)lines[i];
                this.parsed_text+='\n'+line.get('text');
          }

          }
         
          else{

             System.debug('bad code response on get: '+response.getStatusCode());  
             this.parsed_text+='bad responsecode on get';
         }
         
      } catch (Exception e) {

         this.parsed_text=e.getMessage()+' on get';
         System.debug('parsed text: '+ this.parsed_text);

      }

    }

    /**
     * update the acc field ParsedText__c
     */
    public  void updateField(){

      Account a=[SELECT Id, ParsedText__c FROM Account WHERE Id=:this.recordId];
        a.ParsedText__c= this.parsed_text;
        update a;
    }
     }