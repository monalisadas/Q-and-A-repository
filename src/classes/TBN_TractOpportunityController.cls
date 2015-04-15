public with sharing class TBN_TractOpportunityController
{
	public List<OpportunityInner> OpportunityInner{get;set;}
	public TBN_TractOpportunityController(ApexPages.StandardController sc) 
	{
		OpportunityInner = new List<OpportunityInner>();
		Set<Id> setProductId = new Set<Id>();
		Opportunity op = (Opportunity)sc.getRecord();
		
		for(OpportunityLineItem o : [SELECT id,PricebookEntry.Product2Id,OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: op.id])
		{
			setProductId.add(o.PricebookEntry.Product2Id);
		}
			
		
		// Prepare Map
		for(Product2 p : [SELECT id,name FROM Product2 WHERE id in:setProductId])
		{
			
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
		public String quiz{get;set;}
		public String ans{get;set;}
		
		public InnerQuestionAnswer()
		{
			this.quiz = quiz;
			this.ans = ans;
		}
	}
	
	public void saveAnswer()
	{
		
	}
}