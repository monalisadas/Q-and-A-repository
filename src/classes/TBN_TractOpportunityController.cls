/**
* ClassName : TBN_TractOpportunityController  
* CreatedOn : Monalisa Das,15/04/2015 
* ModifiedBy :Monalisa Das,17/04/2015
* Description : Class that retrieves questions and answers on various products  
*/ 

public with sharing class TBN_TractOpportunityController  
{
    public List<OpportunityInner> lstInnerOpportunity{get;set;}
    public Map<Id,List<InnerQuestionAnswer>> mapProductToQuestionAnswer{get;set;}  
    public Boolean boolOppHasProducts{get;set;} 
    public Boolean boolProductsAreRelatedToGroup{get;set;} 
    public Boolean boolProductGroupHaveQuestion{get;set;} 
    public Integer intTotalAnswered{get;set;}
    public Integer intTotalUnAnswered{get;set;}
    Integer intTotalQuestion{get;set;}
    
    Map<Id,set<Id>> mapGroupIdToSetQuestionId{get;set;}
    ApexPages.StandardController sc{get;set;}
    
    /* Start Constructor */
    public TBN_TractOpportunityController(ApexPages.StandardController sc) 
    {
        lstInnerOpportunity = new List<OpportunityInner>();
        mapProductToQuestionAnswer = new Map<Id,List<InnerQuestionAnswer>>();
        mapGroupIdToSetQuestionId = new Map<Id,Set<Id>>();
        boolOppHasProducts = false; 
        boolProductsAreRelatedToGroup = false; 
        boolProductGroupHaveQuestion = false;
        intTotalAnswered = 0;   
        intTotalUnAnswered = 0;
        intTotalQuestion = 0; 
        this.sc = sc;
        Opportunity op = (Opportunity)sc.getRecord();  
        Set<Id> setProductId = new Set<Id>();        
              
        for(OpportunityLineItem o : [SELECT id,PricebookEntry.Product2Id,OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: op.id])
        {
            setProductId.add(o.PricebookEntry.Product2Id);        
        }
        
        for(Product2 p : [SELECT id,name,Product_Group__c,Product_Group__r.id FROM Product2 WHERE id in:setProductId])
        {
            boolOppHasProducts = true;
            List<InnerQuestionAnswer> lstQuesAns;
            if(p.Product_Group__c != null)
            {
            	boolProductsAreRelatedToGroup = true;
                prepareMapProductToQuestionAnswer(p,op); 
            }          
            
            //check all values added or not
            lstQuesAns = mapProductToQuestionAnswer.get(p.id);          
            if(lstQuesAns== null && p.Product_Group__r.id!=null)
            {
                lstQuesAns = new List<InnerQuestionAnswer>();               
            }
            
            List<InnerQuestionAnswer> lstTempQa = new List<InnerQuestionAnswer>();
            if(p.product_group__c != null) 
            {
            	if(mapGroupIdToSetQuestionId.containsKey(p.Product_Group__r.id))
            	{
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
            	}             	 
            }            
            if(!lstTempQa.isEmpty())
            {
                for(InnerQuestionAnswer innerQa : lstTempQa)
                {
                    lstQuesAns.add(innerQa);
                }
            }             
            if(lstQuesAns != null && !(lstQuesAns.isEmpty()))     
            {
            	boolProductGroupHaveQuestion = true;
                OpportunityInner opInner = new OpportunityInner(p,lstQuesAns);              
                lstInnerOpportunity.add(opInner); 
            }           
        }
        intTotalUnAnswered = intTotalQuestion - intTotalAnswered;         
    }
    /* End Constructor */
    
    /**
		* ClassName   : OpportunityInner  		
		* Description : Inner class that stores product and its related question answer
	*/
    public class OpportunityInner 
    {
        public Product2 prod{get;set;}
        public List<InnerQuestionAnswer> lstQuesAns{get;set;}
        
        /* Start constructor */
        OpportunityInner(Product2 prod,List<InnerQuestionAnswer> lstQuesAns)
        {
            this.prod = prod;
            this.lstQuesAns = lstQuesAns;                       
        }
        /* End constructor */
    }
    
    /**
		* ClassName   : InnerQuestionAnswer  		
		* Description : Inner class that stores question and its corresponding answer
	*/
    public class InnerQuestionAnswer
    {
        public Question__c quiz{get;set;} 
        public Answer__c ans{get;set;}
        public String recType{get;set;}    
        
         /* Start Constructor */        
        public InnerQuestionAnswer(Id quizId,Answer__c ans)
        {
            quiz = [SELECT id,Question__c,RecordType.name,Picklist_value_for_question__c,Multiselect_picklist_values__c FROM Question__c where id =: quizId];  
            recType = quiz.RecordType.name;
            this.ans = ans;    
        }  
        /* End Constructor */ 
        
        /*
	        @Method Name    : 	getPicklistValues
	        @Parameters     : 	none
	        @Description    : 	This method returns the list of available picklist values defined for a question with 
	        					"picklist type answer" record type 
    	*/
        public List<SelectOption> getPicklistValues()
        {
            List<SelectOption> options = new List<SelectOption>();
            List<String>lstListOptions = new List<String>();
            lstListOptions = String.valueOf(quiz.Picklist_value_for_question__c).split('\n');//
            
            for(String selectVal : lstListOptions)
            {
                options.add(new SelectOption(selectVal.trim(),selectVal.trim()));  
            }          
            return options; 
        }   
       
    }
    
    /*
        @Method Name    : prepareMapProductToQuestionAnswer
        @Parameters     : Product2,Opportunity
        @Description    : This method associate products with list of question answers
    */  
    public void prepareMapProductToQuestionAnswer(Product2 p,Opportunity op)  
    {
        Set<Id> setQuizId = new Set<Id>();
        Product_Group__c pGroup = [SELECT id,Name from Product_Group__c where id = : p.Product_Group__c];
        List<Question__c> lstQuestion = [   SELECT 
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
            intTotalQuestion++;
        }
        
        
        for(Answer__c ans : [SELECT id,Answer__c,Question__c,Product__c,opportunity__c from Answer__c where Question__c in:setQuizId and Opportunity__c =:op.id and Product__c =:p.id])
        {           
                    
            if(!mapProductToQuestionAnswer.containsKey(ans.Product__c)) 
            {
                mapProductToQuestionAnswer.put(ans.Product__c,new List<InnerQuestionAnswer>());
            }
            mapProductToQuestionAnswer.get(ans.Product__c).add(new InnerQuestionAnswer(ans.Question__c,ans)); 
            intTotalAnswered++;                     
        }
    }   
    
    /*
        @Method Name    : saveAnswer
        @Parameters     : none
        @Description    : This method saves the answer
    */ 
    public PageReference saveAnswer()
    {
        List<Answer__c> lstAns = new List<Answer__c>();
        if(!lstInnerOpportunity.isEmpty())
        {
            for(OpportunityInner opInner : lstInnerOpportunity)
            {             
                for(InnerQuestionAnswer inObj : opInner.lstQuesAns)
                {
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