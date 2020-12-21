/**
 * @description       : 
 * @author            : Flistergod
 * @group             : 
 * @last modified on  : 12-15-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-25-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/

/**>
 * Queueable apex class always needs a constructor, cant have static methods
 * 
 */
public with sharing class cls_OCR_Space_Handler  implements Queueable, Database.AllowsCallouts, I_OCR_Handler {
    String url, recordId, parsed_text='';


     public cls_OCR_Space_Handler (String url_param, String recordId_param) {

        this.url=url_param;
        this.recordId=recordId_param;
     } 


     /*
      *
      * With the url defined in the constructor, we only have to prepare the httprequest
      * Prepare the api key, the header, the body (in form data)
      * if the reponseCode is 200, he handle the api response
      * to handle the response, we need to transform the data received from the api to a string
      * deserialize the json to a map, from map to a list, and in each index( an index is a page 
      * from the pdf file) we transform to a string, and remove uncessary text
      * after that, we save the text in a filed of the account, because we cant return the text directly~
      * (the api response might take a while, and we dont want to wait)
      * You could wait, but the text is to create  
      */
    public void execute(QueueableContext context) {
         //---------------------------------------OCR Space ------------------------------------------------
         String parsed_text='';
         
            
         String HEADER_API_KEY='apikey';
         String API_KEY='b9c88bd4a588957';
         String LANG='eng';
         String IS_OVERLAY_REQUIRED='false';
         String ENDPOINT='https://api.ocr.space/parse/image';
         String IS_CREATE_SEARCHABLE_PDF='false';
         String IS_CREATE_SEARCHABLE_PDF_HIDE_TEXT_LAYER='false';
         String IS_SCALE='true';

        String body=
              '------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"language\"\r\n\r\n'+LANG+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"isOverlayRequired\"\r\n\r\n'+IS_OVERLAY_REQUIRED+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"url\"\r\n\r\n'+url+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"iscreatesearchablepdf\"\r\n\r\n'+IS_CREATE_SEARCHABLE_PDF+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"issearchablepdfhidetextlayer\"\r\n\r\n'+ IS_CREATE_SEARCHABLE_PDF_HIDE_TEXT_LAYER+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"scale\"\r\n\r\n'+ IS_SCALE+
          '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--';
    
         Http http = new Http();
         HttpRequest request = new HttpRequest();
         request.setEndpoint(ENDPOINT);
         request.setHeader(HEADER_API_KEY, API_KEY);
         request.setHeader('Content-Type','application/json');
         request.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
         request.setMethod('POST');
         request.setHeader('Connection', 'keep-alive');
         request.setTimeout(100000);        
         request.setHeader('Accept', 'application/json');
         request.setHeader('Authorization',' ');
         request.setBody(body);

         try {
         
         HttpResponse response = http.send(request);
     
         System.debug(response.getStatusCode());
         
    
         if (response.getStatusCode() == 200) {
          // Deserialize the JSON string into collections of primitive data types.            

             Map<String,Object> results= (Map<String,Object>)  JSON.deserializeUntyped(response.getBody());
             List<Object> pages=(List<Object>)results.get('ParsedResults');
             
             //for now, lets just focus on 1 page... in the future we can use a for to loop the list pages
     
             parsed_text=pages[0].toString();
               parsed_text= parsed_text.remove('{ErrorDetails=, ErrorMessage=, FileParseExitCode=1, ParsedText=');
                parsed_text=parsed_text.remove(', TextOrientation=0, TextOverlay={HasOverlay=false, Lines=(),'+
                                            ' Message=Text overlay is not provided as it is not requested}}');
             parsed_text=parsed_text.trim();
             
             System.debug('parsed text: '+parsed_text);
             
             }else{System.debug('bad code response: '+response.getStatusCode()); parsed_text='bad responsecode';}
         } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            parsed_text=e.getMessage();
            
            System.debug('parsed text: '+parsed_text);
         }
            this.parsed_text=parsed_text;
         updateField();
    }

    public  void updateField(){

      Account a=[SELECT Id, ParsedText__c FROM Account WHERE Id=:this.recordId];
        a.ParsedText__c=this.parsed_text;
        update a;
    }
     }