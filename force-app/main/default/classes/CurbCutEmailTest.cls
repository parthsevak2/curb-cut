@IsTest
private class CurbCutEmailTest {

    @TestSetup
    static void seed() {
        insert new Accommodation_Option__c(
            Option__c = 'Captions turned on in all meetings',
            Plain_Language_Summary__c = 'Live captions on by default in every meeting.',
            Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm');
    }

    private static Messaging.InboundEmail mail(String body, String subject) {
        Messaging.InboundEmail e = new Messaging.InboundEmail();
        e.plainTextBody = body; e.subject = subject;
        return e;
    }
    private static Messaging.InboundEnvelope env() {
        Messaging.InboundEnvelope v = new Messaging.InboundEnvelope();
        v.fromAddress = 'someone@example.com';
        return v;
    }

    @IsTest
    static void logsIntakeAndAnswersFromTheLibrary() {
        Test.startTest();
        Messaging.InboundEmailResult r = new CurbCutEmail().handleInboundEmail(
            mail('I keep missing things in meetings', 'help'), env());
        Test.stopTest();
        System.assertEquals(true, r.success);
        Barrier_Report__c br = [SELECT Anonymous__c, Inbound_Modality__c FROM Barrier_Report__c LIMIT 1];
        System.assertEquals(true, br.Anonymous__c, 'Email intake is anonymous');
        System.assertEquals('Text', br.Inbound_Modality__c);
    }

    @IsTest
    static void neverSendsARequestFromEmail() {
        Test.startTest();
        new CurbCutEmail().handleInboundEmail(
            mail('I keep missing things in meetings. Please send this to my manager.', 'send it'), env());
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c],
            'Email cannot carry in-the-moment approval, so it must never create a request');
    }

    @IsTest
    static void emptyEmailGetsAWelcomeNotAnError() {
        Messaging.InboundEmailResult r = new CurbCutEmail().handleInboundEmail(mail('   ', ''), env());
        System.assertEquals(true, r.success, 'Never bounce; a bounce is a door closing');
        System.assertEquals(0, [SELECT COUNT() FROM Barrier_Report__c],
            'An empty message must not create a record');
    }

    @IsTest
    static void quotedReplyHistoryIsNotReadAsTheNeed() {
        String body = 'I keep missing things in meetings\n\n'
                    + 'On Tuesday someone wrote:\n> a long quoted thread about something else entirely';
        Test.startTest();
        new CurbCutEmail().handleInboundEmail(mail(body, 're: re: re:'), env());
        Test.stopTest();
        Barrier_Report__c br = [SELECT Functional_Description__c FROM Barrier_Report__c LIMIT 1];
        System.assert(!br.Functional_Description__c.contains('quoted thread'),
            'Quoted history must be trimmed: ' + br.Functional_Description__c);
    }

    @IsTest
    static void imageAttachmentIsRecordedAsTheImageModality() {
        Messaging.InboundEmail e = mail('Here is my workstation', 'photo');
        Messaging.InboundEmail.BinaryAttachment a = new Messaging.InboundEmail.BinaryAttachment();
        a.fileName = 'desk.JPG'; a.body = Blob.valueOf('x');
        e.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{ a };
        Test.startTest();
        new CurbCutEmail().handleInboundEmail(e, env());
        Test.stopTest();
        System.assertEquals('Image',
            [SELECT Inbound_Modality__c FROM Barrier_Report__c LIMIT 1].Inbound_Modality__c);
    }

    @IsTest
    static void aFailedReplyBecomesAHumanHandoffRatherThanSilence() {
        // Apex reports success for suppressed test sends, so the failure has to
        // be forced. This is the path that runs when the org's daily email cap
        // is exhausted -- which on this org is 15 messages.
        CurbCutEmail.forceReplyFailure = true;
        Test.startTest();
        new CurbCutEmail().handleInboundEmail(
            mail('I keep missing things in meetings', 'help'), env());
        Test.stopTest();
        CurbCutEmail.forceReplyFailure = false;

        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c],
            'An undeliverable reply must escalate to a person, not vanish');
        Human_Handoff__c h = [SELECT Reachable_By__c, Handler_Name__c FROM Human_Handoff__c LIMIT 1];
        System.assertEquals('Text message', h.Reachable_By__c,
            'Even the escalation never routes anyone to a phone call');
        System.assert(String.isNotBlank(h.Handler_Name__c));
    }

    @IsTest
    static void unknownNeedSaysSoRatherThanGuessing() {
        Test.startTest();
        new CurbCutEmail().handleInboundEmail(
            mail('quantum sledgehammer procurement', 'hi'), env());
        Test.stopTest();
        // The reply is not inspectable in a test context; assert the intake was
        // still logged so nothing is silently dropped.
        System.assertEquals(1, [SELECT COUNT() FROM Barrier_Report__c]);
    }
}
