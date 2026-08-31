/**
 * The counts drive what a person on duty looks at first, so a wrong count is
 * not a cosmetic bug: it is somebody being left in a queue nobody is reading.
 */
@IsTest
private class CurbCutConsoleTest {

    private static Human_Handoff__c waiting(Integer hoursAgo) {
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = 'I cannot type for long', Anonymous__c = true,
            Inbound_Modality__c = 'Text');
        insert br;
        Human_Handoff__c h = new Human_Handoff__c(
            Barrier_Report__c = br.Id, Reachable_By__c = 'Text message',
            Requested_At__c = System.now().addHours(-hoursAgo));
        insert h;
        return h;
    }

    @IsTest
    static void countsWhatIsActuallyWaiting() {
        waiting(30); waiting(2);
        Test.startTest();
        CurbCutConsole.Triage t = CurbCutConsole.triage();
        Test.stopTest();
        System.assertEquals(2, t.waiting, 'Both unpicked handoffs must be counted');
        System.assert(t.longestWaitHours >= 29,
            'The longest wait drives the order of work: ' + t.longestWaitHours);
    }

    @IsTest
    static void aPickedUpHandoffIsNoLongerWaiting() {
        Human_Handoff__c h = waiting(4);
        CurbCutConsole.pickUp(h.Id, 'Dana Osei');
        Test.startTest();
        CurbCutConsole.Triage t = CurbCutConsole.triage();
        Test.stopTest();
        System.assertEquals(0, t.waiting, 'A handoff someone has taken is not waiting');
        System.assertEquals('Dana Osei',
            [SELECT Handler_Name__c FROM Human_Handoff__c WHERE Id = :h.Id].Handler_Name__c);
    }

    /** The brief exists so nobody has to click through to the words. */
    @IsTest
    static void theBriefCarriesTheirOwnWords() {
        Human_Handoff__c h = waiting(3);
        Test.startTest();
        CurbCutConsole.Brief b = CurbCutConsole.brief(h.Id);
        Test.stopTest();
        System.assertEquals('I cannot type for long', b.theirWords);
        System.assertEquals('Text message', b.reachBy);
        System.assertEquals(false, b.pickedUp);
        System.assert(b.waitedHours >= 2, 'Wait should be counted: ' + b.waitedHours);
    }

    /** Overdue is the number that should make somebody move. */
    @IsTest
    static void overdueIsCountedSeparatelyFromUndecided() {
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = 'The open office is unbearable', Anonymous__c = true);
        insert br;
        insert new List<Accommodation_Request__c>{
            new Accommodation_Request__c(Barrier_Report__c = br.Id, Person_Approved__c = true,
                Approved_At__c = System.now(), Manager_Response__c = 'Pending',
                Interactive_Process_Due__c = Date.today().addDays(-1)),
            new Accommodation_Request__c(Barrier_Report__c = br.Id, Person_Approved__c = true,
                Approved_At__c = System.now(), Manager_Response__c = 'Pending',
                Interactive_Process_Due__c = Date.today().addDays(5))
        };
        Test.startTest();
        CurbCutConsole.Triage t = CurbCutConsole.triage();
        Test.stopTest();
        System.assertEquals(2, t.undecided);
        System.assertEquals(1, t.overdue, 'Only the one past its date is overdue');
    }

    /** Anything not Accepted is a person who heard nothing back. */
    @IsTest
    static void unreachedCountsEveryNonAcceptedReply() {
        insert new List<Message_Log__c>{
            new Message_Log__c(Channel__c='Email', Direction__c='Outbound',
                Status__c='Escalated', Attempted_At__c=System.now()),
            new Message_Log__c(Channel__c='SMS', Direction__c='Outbound',
                Status__c='Rejected', Attempted_At__c=System.now()),
            new Message_Log__c(Channel__c='Web', Direction__c='Outbound',
                Status__c='Accepted', Attempted_At__c=System.now())
        };
        Test.startTest();
        CurbCutConsole.Triage t = CurbCutConsole.triage();
        Test.stopTest();
        System.assertEquals(2, t.unreached,
            'Accepted means a platform took it, not that a person got it');
    }
}
