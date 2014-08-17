public with sharing class EmailService {
	private sm_managed__XOEmailerSettings__c emailSetting {get;private set;}
	private Messaging.EmailFileAttachment[] emailAttachment {get; set;}
	private String emailSubject {get; set;}
	private String emailBody {get; set;}
	private List<String> userList {get;set;}
	private Id emailWhatId {get;set;}
	private Id emailTemplateId {get; set;}
	private String parsedEmailBody {get; set;}
	private String parsedEmailSubject {get; set;}

	public EmailService(String objectAPIName) {
		emailSetting = getEmailSetting(objectAPIName);
		emailTemplateId = emailSetting.Id;
	}

	/* Returns the List of templates 
	 * @param id EmailTemplate id
	 * Returns the EmailTemplate Object with Subject, Body
	 */
	private EmailTemplate getEmailTemplates(Id id){
		return [SELECT id, Subject, Body FROM EmailTemplate WHERE id = :id and TemplateType='text' and isActive=true limit 1];
	}

	private sm_managed__XOEmailerSettings__c getEmailSetting(String objectAPIName){
		system.debug(Database.query('Select sm_managed__Email_Template__c,sm_managed__Object_Name__c,sm_managed__Sender_Display_Name__c from sm_managed__XOEmailerSettings__c where sm_managed__Active__c = true and sm_managed__Object_Name__c=:objectAPIName limit 1'));
		return Database.query('Select sm_managed__Email_Template__c,sm_managed__Object_Name__c,sm_managed__Sender_Display_Name__c from sm_managed__XOEmailerSettings__c where sm_managed__Active__c = true and sm_managed__Object_Name__c=:objectAPIName limit 1');
	}

	public void setFileAttachment(Messaging.EmailFileAttachment[] attachment){
		system.debug(this);
		emailAttachment = attachment;
	}
	
	public void setWhatId(Id id){
		emailWhatId = id;
	}

	public void setPlainTextBody(String body){
		emailBody = body;
	}
	public void setToAddresses(String[] toAddresses){
		if(toAddresses.isEmpty()) return;
			//throw new Exception('At least one user needs to receive the email');
		userList = toAddresses;
	}
	public Boolean sendEmail (){
		try { 
			//string baseURL = String.valueof(System.URL.getSalesforceBaseUrl());
			String nullStr = null;

			if(emailWhatId != null && emailSetting!= null && emailSetting.sm_managed__Email_Template__c!=null){
				parsedEmailBody = sm_managed.MailMergeService.process( emailSetting.sm_managed__Email_Template__c, emailWhatId ,emailTemplateId);
				//parsedEmailSubject = sm_managed.MailMergeService.process(emailSetting.sm_managed__Email_Template__c, emailWhatId );
				emailSubject = 'AUTOMAILER';
			}
			else {
				parsedEmailBody = emailBody;
				emailSubject = 'AUTOMAILER';
			}
			
			system.debug(parsedEmailBody);
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = userList;
			toAddresses = userList;
			mail.setToAddresses(toAddresses);
			mail.setSubject(emailSubject);
		  	mail.setHTMLBody(parsedEmailBody);
		  	if(emailAttachment!=null && emailAttachment.isEmpty() == false )
		  		mail.setFileAttachments(emailAttachment);
		  	String emailSenderName = (emailSetting.sm_managed__Sender_Display_Name__c == null) ? 'AUTOMAILER' : emailSetting.sm_managed__Sender_Display_Name__c;
	      	mail.setSenderDisplayName(emailSenderName);
	      	system.debug(mail);
	      	//Send Email
	      	//Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			return true;
	    }
	    catch(Exception e){
	    	//TODO: Error Handling
	    	system.debug('Error sending email!'+e.getMessage());
	    	system.debug('Error sending email!'+e.getStackTraceString());
	    	return false;
	    }
	}
}