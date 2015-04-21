@isTest(seeAllData=true)
public with sharing class TEST_TrackOpportunityController 
{
    static Opportunity op{get;set;}
    static ApexPages.StandardController sc{get;set;}
    static TBN_TractOpportunityController contr{get;set;}
    public static testmethod void testFunctionality() 
    {       
        
        createData(); 
    } 
     
    public static void createData()
    {
        Id opId = Id.valueOf('00628000002UtJT');
        op = [SELECT id FROM Opportunity where id = : opId];
        
        sc = new ApexPages.StandardController(op);
        contr = new TBN_TractOpportunityController(sc);  
        PageReference pg = contr.saveAnswer();
        System.assertEquals(pg.getUrl(),sc.view().getUrl()); 
    }
}