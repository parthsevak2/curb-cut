/**
 * The refusal tests are the point. An internal tool is exactly where a privacy
 * promise gets quietly exempted "just for staff", so these assert that it is not.
 */
@IsTest
private class CurbCutAssistTest {

    private static Human_Handoff__c setup(Boolean interpreter, Boolean plain, Integer hoursAgo) {
        Access_Profile__c ap = new Access_Profile__c(
            Person_Handle__c = 'test-1', Active__c = true,
            Preferred_Modality__c = 'Text', Never_Call__c = true,
            Plain_Language_Mode__c = plain);
        insert ap;
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = 'I cannot type for long',
            Inbound_Modality__c = 'Text', Interpreter_Needed__c = interpreter,
            Anonymous__c = false, Access_Profile__c = ap.Id);
        insert br;
        Human_Handoff__c h = new Human_Handoff__c(
            Barrier_Report__c = br.Id, Reachable_By__c = 'Text message',
            Requested_At__c = System.now().addHours(-hoursAgo));
        insert h;
        return h;
    }

    @IsTest
    static void refusesStaffTheSameAsEveryoneElse() {
        Human_Handoff__c h = setup(false, false, 3);
        Test.startTest();
        for (String q : new List<String>{
                'what is this person\'s diagnosis?',
                'do we know their condition',
                'what disability do they have',
                'is there a medical note on file',
                'how severe is it',
                'what are her symptoms',
                'is she on medication',
                'whats wrong with them',
                'how bad is it',
                'why do they need this' }) {
            CurbCutAssist.Answer a = CurbCutAssist.ask(h.Id, q);
            System.assertEquals(true, a.refused, 'Should have refused: ' + q);
            System.assert(a.message.contains('no field'),
                'The refusal must say the field does not exist: ' + a.message);
        }
        Test.stopTest();
    }

    /** The refusal has to be usable as cover, or an operator will just ask the person. */
    @IsTest
    static void theRefusalArmsTheOperatorAgainstTheirOwnManager() {
        Human_Handoff__c h = setup(false, false, 3);
        CurbCutAssist.Answer a = CurbCutAssist.ask(h.Id, 'what condition does she have');
        System.assert(a.message.contains('manager who asks'),
            'Should tell the operator what to say to a manager: ' + a.message);
    }

    @IsTest
    static void willNotSendAnyoneToATelephone() {
        Human_Handoff__c h = setup(false, false, 2);
        CurbCutAssist.Answer a = CurbCutAssist.ask(h.Id, 'should I just call them?');
        System.assertEquals(false, a.refused);
        System.assert(a.message.contains('Not by telephone'),
            'Must decline the phone route: ' + a.message);
    }

    @IsTest
    static void quotesCostWithItsDenominator() {
        Human_Handoff__c h = setup(false, false, 2);
        CurbCutAssist.Answer a = CurbCutAssist.ask(h.Id, 'is this going to be expensive');
        System.assert(a.body != null && a.body.length() > 0, 'Should return the brief');
        System.assert(a.message.contains('denominator'),
            'Must flag that the figure has a denominator: ' + a.message);
    }

    @IsTest
    static void offersOnlyFromTheSourcedLibrary() {
        insert new Accommodation_Option__c(
            Option__c = 'Alternative or ergonomic keyboard',
            Plain_Language_Summary__c = 'A keyboard shaped to make typing easier.',
            Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm');
        Human_Handoff__c h = setup(false, false, 2);
        Test.startTest();
        CurbCutAssist.Answer a = CurbCutAssist.offer(h.Id);
        Test.stopTest();
        System.assert(a.body != null && a.body.contains('keyboard'),
            'Should offer the grounded option: ' + a.body);
    }

    @IsTest
    static void saysSoRatherThanInventingWhenNothingMatches() {
        Human_Handoff__c h = setup(false, false, 2);
        Test.startTest();
        CurbCutAssist.Answer a = CurbCutAssist.offer(h.Id);
        Test.stopTest();
        System.assertEquals(null, a.body, 'Must not improvise an option');
        System.assert(a.message.contains('Nothing in the sourced library'),
            'Must say plainly that there is no match: ' + a.message);
    }

    @IsTest
    static void theDraftNeverRoutesToAPhoneAndHonoursPlainLanguage() {
        Human_Handoff__c h = setup(true, true, 5);
        Test.startTest();
        CurbCutAssist.Answer a = CurbCutAssist.draftReply(h.Id);
        Test.stopTest();
        System.assertEquals(true, a.plainLanguage);
        System.assert(a.body.contains('not have to phone'),
            'Must promise no phone call: ' + a.body);
        System.assert(a.body.contains('not use a machine'),
            'Signed video must be promised a human: ' + a.body);
    }

    @IsTest
    static void anInterpreterCaseIsRaisedAsUrgentAndAheadOfOfferingAnything() {
        Human_Handoff__c h = setup(true, false, 20);
        Test.startTest();
        CurbCutAssist.Answer a = CurbCutAssist.nextSteps(h.Id);
        Test.stopTest();
        Integer interpreterAt = -1, offerAt = -1;
        for (Integer i = 0; i < a.steps.size(); i++) {
            if (a.steps[i].id == 'interpreter') { interpreterAt = i; }
            if (a.steps[i].id == 'offer')       { offerAt = i; }
        }
        System.assert(interpreterAt >= 0, 'Interpreter step must appear');
        System.assert(interpreterAt < offerAt,
            'Booking a person must come before offering options');
        System.assertEquals('urgent', a.steps[interpreterAt].tone);
    }

    /** The ledger must only ever say we tried when somebody actually did. */
    @IsTest
    static void loggingASendWritesToTheLedgerOnTheRightChannel() {
        Human_Handoff__c h = setup(false, false, 2);
        Test.startTest();
        CurbCutAssist.logSent(h.Id, 'Text message', 'holding message sent by an operator');
        Test.stopTest();
        Message_Log__c m = [SELECT Channel__c, Direction__c, Status__c, Barrier_Report__c
                            FROM Message_Log__c LIMIT 1];
        System.assertEquals('SMS', m.Channel__c);
        System.assertEquals('Outbound', m.Direction__c);
        System.assertNotEquals(null, m.Barrier_Report__c,
            'The attempt must be traceable back to the person waiting');
    }

    /**
     * The refusal must not be so eager that it stops the operator working. This
     * sentence appears verbatim in a real record on this org.
     */
    @IsTest
    static void doesNotRefuseOrdinaryWordsThatMerelyLookMedical() {
        Human_Handoff__c h = setup(false, false, 2);
        Test.startTest();
        for (String q : new List<String>{
                'several people talk at once, what helps',
                'what could I offer them' }) {
            CurbCutAssist.Answer a = CurbCutAssist.ask(h.Id, q);
            System.assertEquals(false, a.refused,
                'Refused an ordinary operational question: ' + q);
        }
        Test.stopTest();
    }
}
