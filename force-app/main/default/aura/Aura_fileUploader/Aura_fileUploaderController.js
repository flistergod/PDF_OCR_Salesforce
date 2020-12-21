({
    //methods name in js and apex, must be different, or lwc wont differ them
  
    doInit: function (cmp, event, helper) {
      //handler to load initial stuff on aura component
      //like array of outputs
    },
  
    afterScriptsLoaded: function (component, event, helper) {
      //to check if 3rd librarys are loaded
      console.log("PDF and JQuery js loaded");
    },
  
    openfileUpload: function (cmp, event, helper) {
      /**
       * gets file from event
       * gets base64 and name and saves it in aura cmp
       * (cant initialize vars in controller, only in helper, but its a bad practice
       * use vars in helper only if they have static value)
       * With the values save, we will create a cmp:
       * We have a var - pdfcontaniner that is an array of components,
       * we will create a cmp programmaticlly
       * and save that cmp on the array
       * We say the custom cmp, its data (pdfdata), and push it in the array
       * If its not the first time, uploading a file, we dont need to create
       * we just replace the cmp created before
       * we check this condition with var count on aura
       */
      const file = event.getSource().get("v.files")[0];
      console.log(file.name);
      let reader = new FileReader();
  
      reader.onload = () => {
        let base64 = reader.result.split(",")[1];
        cmp.set("v.base64", base64);
        let pdfData = base64;
        cmp.set("v.fileData", file.name);
  
        if (cmp.get("v.count") == "0") {
          $A.createComponent(
            "c:pdfViewer",
            {
              pdfData: pdfData
            },
            function (pdfViewer, status, errorMessage) {
              if (status === "SUCCESS") {
                let pdfContainer = cmp.get("v.pdfContainer");
                pdfContainer.push(pdfViewer);
                cmp.set("v.pdfContainer", pdfContainer);
              } else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.");
              } else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
              }
            }
          );
          cmp.set("v.count", "1");
        } else {
          let pdfContainer = cmp.get("v.pdfContainer");
          console.log(JSON.stringify(pdfContainer));
  
          $A.createComponent(
            "c:pdfViewer",
            {
              pdfData: pdfData
            },
            function (pdfViewer, status, errorMessage) {
              if (status === "SUCCESS") {
                let pdfContainer = cmp.get("v.pdfContainer");
                pdfContainer[0] = pdfViewer;
                cmp.set("v.pdfContainer", pdfContainer);
              } else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.");
              } else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
              }
            }
          );
        }
      };
      reader.readAsDataURL(file);
    },
  
    /**
     * to call an apex method, we usethe  controller on the aura cmp and make a remote call
     * (let action = cmp.get("c.uploadFileApex");)
     * we set the params of the method  - action.setParams
     *  finally we handle the response with state var
     * show a toast in the end*/
    handleClick: function (cmp, event, helper) {
      console.log("clicked submit");
      let base64 = cmp.get("v.base64");
      let filename = cmp.get("v.fileData");
      let recordId = cmp.get("v.recordId");
      let action = cmp.get("c.uploadFileApex");
  
      action.setParams({
        base64: base64,
        filename: filename,
        recordId: recordId
      });
  
      action.setCallback(this, function (response) {
        let state = response.getState();
  
        if (state === "SUCCESS") {
          let url_pdf = response.getReturnValue();
          console.log("u did it: " + url_pdf);
        } else {
          console.log("error: " + state);
        }
      });
  
      $A.enqueueAction(action);
      helper.showToast();
    }
  });