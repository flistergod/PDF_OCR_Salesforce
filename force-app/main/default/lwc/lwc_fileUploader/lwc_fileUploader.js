import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import uploadFileApex from "@salesforce/apex/cls_FileUploader.uploadFileApex";

/* To import 3rd library
import { loadScript} from 'lightning/platformResourceLoader';
import jqueryMinJS from '@salesforce/resourceUrl/jqueryminjsv1';
import pdfjs3 from '@salesforce/resourceUrl/pdfjs3';
import pdfjsworker3 from '@salesforce/resourceUrl/pdfjsworker3';
*/

//How to set global vars before js loads
//let pdfjsLib, divpdfContainer;
//let canvas, ctx;
let pdfjsLib;

//methods name in js and apex, must be different, or lwc wont differ them

export default class FileUploader extends LightningElement {
  @api recordId;
  //global var after js loaded
  parsedText = "Upload a cv please";
  fileData;
  file;
  base64;
  preview =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/480px-No_image_available.svg.png";
  show;

  constructor() {
    super();
  }

  //retrieve canvase and context, load this part of js after page loaded
  //retrieve canvase and context
  renderedCallback() {
    //  canvas = this.template.querySelector('canvas');
    // ctx = canvas.getContext("2d");
    // divpdfContainer=this.template.querySelector('div.pdfContainer')
  }

  // to load scripts while page is loading
  connectedCallback() {
    Promise.all([
      loadScript(this, jqueryMinJS),
      loadScript(this, pdfjs3),
      loadScript(this, pdfjsworker3)
    ])
      .then(() => {
        console.log("PDF JS loaded");
        pdfjsLib = window["pdfjs-dist/build/pdf"];
        pdfjsLib.GlobalWorkerOptions.workerSrc = pdfjsworker3;
      })
      .catch((error) => {
        console.log(" Error loading scripts " + error);
        console.log("PDF JS not loaded");
      });
  }

  /*
 Reads pdf on input, gets base64 data and name
 Changes visibility of pdf preview - "preview1" on
 */
  openfileUpload(event) {
    const file = event.target.files[0];
    let base64;
    let reader = new FileReader();
    reader.onload = () => {
      base64 = reader.result.split(",")[1];
      this.base64 = base64;

      this.fileData = {
        filename: file.name,
        base64: base64,
        recordId: this.recordId
      };
      console.log(this.fileData);
      this.file = file;
      this.base64 = base64;
      this.preview1 = "show";

      /*

            let pdfData = atob(base64);

              // Using DocumentInitParameters object to load binary data.
              let loadingTask = pdfjsLib.getDocument({data: pdfData});
              loadingTask.promise.then(function(pdf) {
                console.log('PDF loaded');
                
                // Fetch the first page
                let pageNumber = 1;
                pdf.getPage(pageNumber).then(function(page) {
                  console.log('Page loaded');
                  console.log(JSON.stringify(page));
                  
                  let scale = 1.5;
                  let viewport = page.getViewport({scale: scale});
              
                  // Prepare canvas using PDF page dimensions
                  let canvas = document.createElement('canvas');
                  let att = document.createAttribute("lwc:dom");      
                    att.value = "manual";
                    canvas.setAttributeNode(att);
                
                  divpdfContainer.appendChild(canvas);
                  let ctx = canvas.getContext('2d');
                 
                  // Render PDF page into canvas context
                   let renderContext = {
                    canvasContext: ctx,
                    viewport: viewport
                  };
           
                  //falha aqui
                  //não deixa dar render ou confunde com o render do salesforce
                  console.log('Page rendered2');
                  let renderTask = page.renderl(renderContext);
                  console.log('Page rendered3');
                
            renderTask.promise.then(function () {
              console.log('Page rendered');
            });
                 
                });
              }, function (reason) {
                // PDF loading error
                console.error(reason);
              });    
              */
    };
    reader.readAsDataURL(file);
  }

  loadPDF() {
    /*
        After the visibility of the preview is on, the iframe will load.
        After load, we will send the base64 of the pdf to the pdf.viewer
        the pdf.viewer path is on the src of the iframe
        */
    var pdfjsframe = this.template.querySelector("iframe");
    pdfjsframe.contentWindow.postMessage(this.base64, "*");
  }

  /*
    Handles click on submit button:
    sends file's name and his base64 and also account id to the 
    method uploadFileApex imported from Apex Class NA_FileUploaderClass
    If it saves corrctly, it will show a successfully toast message */
  handleClick() {
    const { base64, filename, recordId } = this.fileData;

    uploadFileApex({ base64, filename, recordId }).then((result) => {
      console.log("result: " + result);
      this.fileData = null;
      this.toast(`${filename} uploaded successfully!`);
    });
  }

  toast(title) {
    const toastEvent = new ShowToastEvent({
      title,
      variant: "success"
    });
    this.dispatchEvent(toastEvent);
  }
}