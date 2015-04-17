public with sharing class TBN_TractOpportunityController 
{
	public List<OpportunityInner> lstInnerOpportunity{get;set;}
	public Map<Id,List<InnerQuestionAnswer>> mapProductToQuestionAnswer{get;set;} 
	Map<Id,set<Id>> mapGroupIdToSetQuestionId{get;set;}
	ApexPages.StandardController sc{get;set;}
	
	public TBN_TractOpportunityController(ApexPages.StandardController sc) 
	{
		/* Initialize variable */
		lstInnerOpportunity = new List<OpportunityInner>();
		mapProductToQuestionAnswer = new Map<Id,List<InnerQuestionAnswer>>();
		mapGroupIdToSetQuestionId = new Map<Id,Set<Id>>();
		/*
		initialize list inner question answer value of this map
		*/
		
		Set<Id> setProductId = new Set<Id>();
		
		this.sc = sc;
		Opportunity op = (Opportunity)sc.getRecord();		
		for(OpportunityLineItem o : [SELECT id,PricebookEntry.Product2Id,OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: op.id])
		{
			setProductId.add(o.PricebookEntry.Product2Id);
		
		}
		
		for(Product2 p : [SELECT id,name,Product_Group__c,Product_Group__r.id FROM Product2 WHERE id in:setProductId])
		{
			
			List<InnerQuestionAnswer> lstQuesAns;
			prepareMapProductToQuestionAnswer(p,op);
			
			//check all values added or not
			lstQuesAns = mapProductToQuestionAnswer.get(p.id);			
			if(lstQuesAns== null)
			{
				lstQuesAns = new List<InnerQuestionAnswer>();				
			}
			
			List<InnerQuestionAnswer> lstTempQa = new List<InnerQuestionAnswer>();
			 for(Id qid : mapGroupIdToSetQuestionId.get(p.Product_Group__r.id))   
		    {
		    	Integer i = -1;
		    	if(!lstQuesAns.isEmpty())
		    	{
		    		for(InnerQuestionAnswer inObj : lstQuesAns) 
			    	{
			    		i++;
			    		if(inObj.quiz.id == qid)
			    		{
			    			break;
			    		}
			    		if(i == lstQuesAns.size()-1)
			    		{
			    			lstTempQa.add(new InnerQuestionAnswer(qid,new Answer__c(Opportunity__c=op.id, Product__c=p.id, Question__c= qid)));
			    			
			    		} 
			    	}
		    	}
		    	else
		    	{
		    		
		    		lstQuesAns.add(new InnerQuestionAnswer(qid,new Answer__c(Opportunity__c=op.id, Product__c=p.id, Question__c= qid))); 
		    	}
		    	
		    }	
		    
		    if(!lstTempQa.isEmpty())
		    {
		    	for(InnerQuestionAnswer innerQa : lstTempQa)
		    	{
		    		lstQuesAns.add(innerQa);
		    	}
		    } 	
			
			OpportunityInner opInner = new OpportunityInner(p,lstQuesAns);  
			
			lstInnerOpportunity.add(opInner); 
		}
		 
	}
	
	public class OpportunityInner 
	{
		public Product2 prod{get;set;}
		public List<InnerQuestionAnswer> lstQuesAns{get;set;}
		
		OpportunityInner(Product2 prod,List<InnerQuestionAnswer> lstQuesAns)
		{
			this.prod = prod;
			this.lstQuesAns = lstQuesAns;						
		}
	}
	
	public class InnerQuestionAnswer
	{
		public List<String> lstSelectedValues {
													get;set;
													
											  } 
		public Question__c quiz{get;set;} 
		public Answer__c ans{get;set;}
		public String recType{get;set;} 
		
		
		public List<SelectOption> getPicklistValues()
	    {
	    	List<SelectOption> options = new List<SelectOption>();
	    	List<String>lstListOptions = new List<String>();
	    	lstListOptions = String.valueOf(quiz.Picklist_value_for_question__c).split('\n');//
	    	
	    	for(String selectVal : lstListOptions)
	    	{
	    		options.add(new SelectOption(selectVal,selectVal));
	    	}	       
	        return options; 
	   	}
	   	
	   	public List<SelectOption> getMultipicklistValues()
	    {
	    	List<SelectOption> options = new List<SelectOption>();
	    	List<String>lstListOptions = new List<String>();
	    	lstListOptions = String.valueOf(quiz.Multiselect_picklist_values__c).split('\n');//
	    	
	    	for(String selectVal : lstListOptions)
	    	{
	    		options.add(new SelectOption(selectVal,selectVal));
	    	}	       
	        return options;  
	    }
	    

		
		public InnerQuestionAnswer(Id quizId,Answer__c ans)
		{
			quiz = [SELECT id,Question__c,RecordType.name,Picklist_value_for_question__c,Multiselect_picklist_values__c FROM Question__c where id =: quizId];  
			recType = quiz.RecordType.name;
			this.ans = ans;
			
		}
		
	
		
	  
	}
	public void prepareMapProductToQuestionAnswer(Product2 p,Opportunity op)  
	{
		Set<Id> setQuizId = new Set<Id>();
		Product_Group__c pGroup = [SELECT id,Name from Product_Group__c where id = : p.Product_Group__c];
		List<Question__c> lstQuestion = [	SELECT 
											id,Question__c,Multiselect_picklist_values__c,
											Picklist_value_for_question__c,Product_group__c,
											recordType.name 
											FROM Question__c 
											WHERE Product_group__c =: pGroup.id 
										];
		for(Question__c quiz : lstQuestion)
		{
			setQuizId.add(quiz.id);
			if(!mapGroupIdToSetQuestionId.containsKey(quiz.Product_group__c))
			{
				mapGroupIdToSetQuestionId.put(quiz.Product_group__c,new Set<Id>());				
			}
			mapGroupIdToSetQuestionId.get(quiz.Product_group__c).add(quiz.id); 
		}
		
		
		for(Answer__c ans : [SELECT id,Answer__c,Question__c,Product__c,opportunity__c from Answer__c where Question__c in:setQuizId and Opportunity__c =:op.id and Product__c =:p.id])
		{			
					
			if(!mapProductToQuestionAnswer.containsKey(ans.Product__c)) 
			{
				mapProductToQuestionAnswer.put(ans.Product__c,new List<InnerQuestionAnswer>());
			}
			mapProductToQuestionAnswer.get(ans.Product__c).add(new InnerQuestionAnswer(ans.Question__c,ans));	 		
				
		}

	}
	
	public PageReference saveAnswer()
	{
		//		public List<InnerQuestionAnswer> lstQuesAns{get;set;}
		
		List<Answer__c> lstAns = new List<Answer__c>();
		if(!lstInnerOpportunity.isEmpty())
		{
			for(OpportunityInner opInner : lstInnerOpportunity)
			{
				for(InnerQuestionAnswer inObj : opInner.lstQuesAns)
				{
					System.debug('------->>>> Inner Answer :'+inObj.ans);
					//
					/*if(inObj.ans.answer__c!=null && inObj.ans.opportunity__c!=null  && inObj.ans.product__c!=null) 
					{
						lstAns.add(inObj.ans);						
					}*/
					//isNotBlank
					if(String.isNotBlank(inObj.ans.answer__c) && String.isNotBlank(inObj.ans.opportunity__c ) && String.isNotBlank(inObj.ans.product__c)) 
					{
						lstAns.add(inObj.ans);						
					}
					
				}					
			
			}
		}
	
		if(!lstAns.isEmpty())  
			upsert lstAns; 
		
		return sc.view();
	
		
	}
}