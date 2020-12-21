({  
    showToast : function() {
		let toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
            "title": "Success!",
            "type":"success",
            "message": "The file has been uploaded successfully"
            
		});
		toastEvent.fire();
	}
})