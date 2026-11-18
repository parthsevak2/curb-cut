/**
 * What somebody said was hard reaches the person picking them up, on every
 * door, and never with a condition in it.
 */
@IsTest
private class CurbCutHandoffContextTest {

    @IsTest
    static void theirWordsReachTheHandler() {
        CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
        hr.context = 'Typing hurts after a while';
        hr.reachableBy = 'Web chat';
        Test.startTest();
        CurbCutCreateHandoff.Result res = CurbCutCreateHandoff.create(
            new List<CurbCutCreateHandoff.Request>{ hr })[0];
        Test.stopTest();
        System.assert(res.created, 'the handoff is made');
        Human_Handoff__c hh = [SELECT Barrier_Report__c FROM Human_Handoff__c WHERE Id = :res.handoffId];
        System.assertNotEquals(null, hh.Barrier_Report__c, 'the handler can open what was hard');
        Barrier_Report__c br = [SELECT Functional_Description__c FROM Barrier_Report__c WHERE Id = :hh.Barrier_Report__c];
        System.assert(br.Functional_Description__c.containsIgnoreCase('typing'), 'their own words, kept');
    }

    @IsTest
    static void aConditionNeverRidesAlong() {
        CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
        hr.context = 'I have multiple sclerosis and some days I cannot type for long';
        Test.startTest();
        CurbCutCreateHandoff.Result res = CurbCutCreateHandoff.create(
            new List<CurbCutCreateHandoff.Request>{ hr })[0];
        Test.stopTest();
        Human_Handoff__c hh = [SELECT Barrier_Report__c FROM Human_Handoff__c WHERE Id = :res.handoffId];
        Barrier_Report__c br = [SELECT Functional_Description__c FROM Barrier_Report__c WHERE Id = :hh.Barrier_Report__c];
        System.assert(!br.Functional_Description__c.containsIgnoreCase('sclerosis'), 'the condition is taken out');
    }

    @IsTest
    static void anAssistantHandingOverPassesTheirWords() {
        CurbCutChannelApi.handoffContext = 'Reading long documents is hard';
        Test.startTest();
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle('External', 'human', null, null);
        Test.stopTest();
        System.assertEquals(true, a.handedOff, 'a person is picking it up');
        Human_Handoff__c hh = [SELECT Barrier_Report__c FROM Human_Handoff__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertNotEquals(null, hh.Barrier_Report__c, 'the words travelled with the handoff');
    }

    @IsTest
    static void noWordsMeansNoEmptyReport() {
        Integer before = [SELECT COUNT() FROM Barrier_Report__c];
        CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
        Test.startTest();
        CurbCutCreateHandoff.create(new List<CurbCutCreateHandoff.Request>{ hr });
        Test.stopTest();
        System.assertEquals(before, [SELECT COUNT() FROM Barrier_Report__c], 'nothing invented when nothing was said');
    }
}
