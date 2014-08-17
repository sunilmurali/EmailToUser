public with sharing class MailMergeService {
	public MailMergeService() {
		
	}

	public static String process(Id template, Id record, Id userId){
		return mailMerge(template,record,userId);
	}

	private static String mailMerge(Id templateId, Id record, Id userId){
		//sm_managed__XOEmailerSettings__c emailSetting = getEmailSetting(emailSettingId);
		EmailTemplate template = getEmailTemplate(templateId);
		if(/*emailSetting == null || */template == null){
			return '';
		}
		else {
			/*if(emailSetting.sm_managed__Object_Name__c == null){
				//throw new Exception('No Object Name specified');
				return null;
			}*/

			//getMergetFields(template.Body);

			return parseMergeFields(template.Body, record);
		}


	}

	private static sm_managed__XOEmailerSettings__c getEmailSetting(Id emailSettingId){
		return [Select sm_managed__Email_Template__c,sm_managed__Object_Name__c,sm_managed__Sender_Display_Name__c from sm_managed__XOEmailerSettings__c where sm_managed__Active__c = true and id=:emailSettingId];
	}

	private static EmailTemplate getEmailTemplate(Id emailTemplateId){
		return [SELECT id, Subject, Body FROM EmailTemplate WHERE id = :emailTemplateId and TemplateType='text' and isActive=true limit 1];
	}

	private static Map<String,List<String>> getMergetFields(String str){
		Map<String,List<String>> tmpMap = new Map<String,List<String>>();
		String temp = str;
		Integer index = 0;
		List<String> allFields = new List<String>();
		if(temp!=null)
		for(index =0; index < temp.length(); index++){
			index = temp.indexOf('{!', index);

			if(index == -1) index = temp.length();
			else {
				String mergeField = temp.substring(index+2, temp.indexOf('}', index));
				allFields.add(mergeField);
				if(mergeField.contains('.')){
					if(tmpMap.containsKey(mergeField.substring(0,mergeField.indexOf('.')))){
						tmpMap.get(mergeField.substring(0,mergeField.indexOf('.'))).add(mergeField.substring(mergeField.indexOf('.')+1, mergeField.length()));
					}
					else {
						tmpMap.put(mergeField.substring(0,mergeField.indexOf('.')),new List<String> {mergeField.substring(mergeField.indexOf('.')+1, mergeField.length())});
					}
					
				}
			}


		}
		return tmpMap;
	}

	private static String parseMergeFields(String str, Id recordId){
		Map<String,List<String>> mapMergeFields = getMergetFields(str);
		Map<String,String> mapFieldValues = new Map<String, String> ();
		//Build query
		for(String key : mapMergeFields.keySet()){
			String query = 'Select id';	
			for(String field: mapMergeFields.get(key)){
				query += ','+field ;
			}
			query += ' from '+ key +' where id= \''+recordId+'\'';
			Sobject sobjResult = Database.query (query);
			for(String field: mapMergeFields.get(key)){
				String replaceStr ='\\{!'+key+'\\.'+field+'\\}';
				str = str.replaceAll(replaceStr,String.valueof(sobjResult.get(field)));
			}
		}
		return str;
	}
}