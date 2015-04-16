public with sharing class TBN_TractOpportunityController
{
	public List<OpportunityInner> lstInnerOpportunity{get;set;}
	public Map<Id,List<InnerQuestionAnswer>> mapProductToQuestionAnswer{get;set;} 
	//public Map<Id,Product2> mapProduct{get;set;} 
	
	public TBN_TractOpportunityController(ApexPages.StandardController sc) 
	{
		/* Initialize variable */
		lstInnerOpportunity = new List<OpportunityInner>();
		mapProductToQuestionAnswer = new Map<Id,List<InnerQuestionAnswer>>();
		/*
		initialize list inner question answer value of this map
		*/
		
		Set<Id> setProductId = new Set<Id>();
		
		
		Opportunity op = (Opportunity)sc.getRecord();		
		for(OpportunityLineItem o : [SELECT id,PricebookEntry.Product2Id,OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: op.id])
		{
			setProductId.add(o.PricebookEntry.Product2Id);
			for(Id prodId : setProductId)
			{
				System.debug('---->>> Id value of prod : '+prodId+'\n\n');
			}
		}
		
		for(Product2 p : [SELECT id,name,Product_Group__c FROM Product2 WHERE id in:setProductId])
		{
			
			List<InnerQuestionAnswer> lstQuesAns = new List<InnerQuestionAnswer>();
			prepareMapProductToQuestionAnswer(p,op);
			lstQuesAns = mapProductToQuestionAnswer.get(p.id);
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
													/*get
													{
														lstSelectedValues = new List<String>{'Russia'};
	    												//lstSelectedValues = String.valueOf(ans.answer__c).split('\n');  
	    												return lstSelectedValues;   
													}
													set;*/
											  } 
		public Question__c quiz{get;set;} 
		public Answer__c ans{get;set;}
		public String recType{get;set;} 
		/*
		RecordType RecType = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Business'];
		
		*/
		//			SELECT RecordType.Name FROM Question__c where id =: quiz.id
		
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
	   	//{!qaObj.multipicklistValues}
	   	
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
	    
	    /*
	    public List<String> getLstSelectedValues()
	    {
	    	lstSelectedValues = new List<String>();
	    	lstSelectedValues = String.valueOf(ans.answer__c).split('\n'); 
	    	return lstSelectedValues;
	    }
		*/
		
		public InnerQuestionAnswer(Id quizId,Answer__c ans)
		{
			quiz = [SELECT id,Question__c,RecordType.name,Picklist_value_for_question__c,Multiselect_picklist_values__c FROM Question__c where id =: quizId];  
			recType = quiz.RecordType.name;
			this.ans = ans;
			
			/*			
			RecordType RecType = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Business'];
		
			Schema.DescribeSObjectResult R = Question__c.SObjectType.getDescribe();
			List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
			
			for(Schema.RecordTypeInfo rti : RT)
			{
			    System.debug('----->>>> :'+rti.getName()+'*****\n\n');
			}*/
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
		}
		
		
		for(Answer__c ans : [SELECT id,Answer__c,Question__c,Product__c from Answer__c where Question__c in:setQuizId and Opportunity__c =:op.id and Product__c =:p.id])
		{			
					
			if(!mapProductToQuestionAnswer.containsKey(ans.Product__c)) 
			{
				mapProductToQuestionAnswer.put(ans.Product__c,new List<InnerQuestionAnswer>());
			}
			mapProductToQuestionAnswer.get(ans.Product__c).add(new InnerQuestionAnswer(ans.Question__c,ans));	
			
			// Checking values----
			for(List<InnerQuestionAnswer> lstObj :mapProductToQuestionAnswer.values())
			{
				System.debug('-------- showing for :'+p.id);
				for(InnerQuestionAnswer x : lstObj)
				{
					System.debug(' see this added question ---->>> for '+p.id+'  :'+x.quiz.question__c+'\n\n');  
				}
				
			}			
		}
		
		/* Check values */
		for(InnerQuestionAnswer innerObj :mapProductToQuestionAnswer.get(Id.valueOf('01t28000000AkbPAAS'))) 
			{				
				System.debug('-----++++,,,,++++------ question added for this product '+''+innerObj.quiz.id);  
				
			} 
		
		// put those questions for which no answer has been posted
		/*
		for(Id quizId : setQuizId)
		{
			Integer i = -1;
			System.debug('-------->>> inside set');
			for(InnerQuestionAnswer innerObj : mapProductToQuestionAnswer.get(p.id)) 
			{
				i++;
				System.debug('****>>>>****Value Of innerObjId '+innerObj.quiz.id);	 		
				System.debug('--------->>>>> check this boolean condition and product id : '+(innerObj.quiz.id==quizId)+','+innerObj.quiz.id+'--- product id : '+p.id);	  
				if(innerObj.quiz.id==quizId)
				{
					System.debug('---->>> inside break,,,,,,');
					break;
				}
			}
			if(i == mapProductToQuestionAnswer.get(p.id).size()-1)
			{
				if(String.valueOf(p.id)=='01t28000000AkbPAAS')
				{
					System.debug('----,,,,,,---.....->>> inside desired if ------->>>> ');
					System.debug('***,,,,,..........********* quiz id which is not found : '+quizId+'\n ');
				}
				
				if(!mapProductToQuestionAnswer.containsKey(p.id))
				{
					mapProductToQuestionAnswer.put(p.id,new List<InnerQuestionAnswer>()); 
					mapProductToQuestionAnswer.get(p.id).add(new InnerQuestionAnswer(quizId,new Answer__c())); 
					
				}
				else
				{ 
					mapProductToQuestionAnswer.get(p.id).add(new InnerQuestionAnswer(quizId,new Answer__c()));   
					
				}			
				
			}
			
			System.debug('---->> outside set ');
		}*/
	}
	
	public PageReference saveAnswer()
	{
		//public List<OpportunityInner> lstInnerOpportunity{get;set;}
		/*
			public Product2 prod{get;set;}
			public List<InnerQuestionAnswer> lstQuesAns{get;set;}
		*/
		
		/*for(lstInnerOpportunity)
		{
			
		}*/
		return null;
	
		
	}
}