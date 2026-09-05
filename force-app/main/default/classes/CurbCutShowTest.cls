/**
 * A preference that travels ahead of a person is a disclosure made in their
 * absence. These tests hold the two promises that make that bearable: it is
 * shown only to who they chose, and every showing is written down where they
 * can read it back with WHO.
 */
@IsTest
private class CurbCutShowTest {

    private class Setup {
        Access_Profile__c profile;
        Barrier_Report__c report;
        Human_Handoff__c handoff;
    }

    private static Setup person() {
        Setup s = new Setup();
        s.profile = new Access_Profile__c(
            Person_Handle__c = 'show-test-1', Active__c = true,
            Preferred_Modality__c = 'Text', Never_Call__c = true);
        insert s.profile;
        s.report = new Barrier_Report__c(
            Functional_Description__c = 'The room is too loud to think in',
            Inbound_Modality__c = 'Text', Anonymous__c = false,
            Access_Profile__c = s.profile.Id);
        insert s.report;
        s.handoff = new Human_Handoff__c(
            Barrier_Report__c = s.report.Id, Reachable_By__c = 'Text message',
            Requested_At__c = System.now().addHours(-2));
        insert s.handoff;
        return s;
    }

    private static Access_Preference__c preference(Id profileId, String sharedWith,
                                                   Boolean autoApply) {
        Access_Preference__c p = new Access_Preference__c(
            Access_Profile__c = profileId,
            Statement__c      = 'Please send me the agenda the day before, in writing',
            Scope__c          = 'Always',
            Shared_With__c    = sharedWith,
            Auto_Apply__c     = autoApply);
        insert p;
        return p;
    }

    private static Integer ledgerCount() {
        return [SELECT COUNT() FROM Disclosure_Event__c];
    }

    @IsTest
    static void showingOnceRecordsExactlyOnce() {
        Setup s = person();
        Access_Preference__c p = preference(s.profile.Id, 'Manager only', true);
        System.assertEquals(0, ledgerCount(), 'nothing has been shown yet');

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(s.handoff.Id, 'Manager only');
        Test.stopTest();

        System.assertEquals(1, shown.size(), 'one active preference, one thing shown');
        System.assertEquals(p.Statement__c, shown[0].statement,
            'the words must come back exactly as the person typed them');
        System.assertEquals(UserInfo.getName(), shown[0].shownTo);

        List<Disclosure_Event__c> ledger = [
            SELECT Access_Preference__c, Shown_To__c, Shown_At__c, Context__c
              FROM Disclosure_Event__c];
        System.assertEquals(1, ledger.size(), 'exactly one ledger row per showing');
        System.assertEquals(p.Id, ledger[0].Access_Preference__c);
        System.assertEquals(UserInfo.getName(), ledger[0].Shown_To__c,
            'the ledger names the real viewer, not a role');
        System.assertNotEquals(null, ledger[0].Shown_At__c);
        System.assert(ledger[0].Context__c.contains('read as Manager only'),
            'the ledger records what the viewer said they were: ' + ledger[0].Context__c);
        System.assert(ledger[0].Context__c.startsWith('Handoff HH-'),
            'the ledger says which record it was read from: ' + ledger[0].Context__c);
    }

    @IsTest
    static void aRevokedPreferenceIsNotShownAndNotRecorded() {
        Setup s = person();
        Access_Preference__c p = preference(s.profile.Id, 'Manager only', true);
        p.Revoked_On__c = System.now().addMinutes(-1);
        update p;

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(s.handoff.Id, 'Manager only');
        Test.stopTest();

        System.assertEquals(0, shown.size(), 'turned off means off');
        System.assertEquals(0, ledgerCount(), 'nothing shown, so nothing to record');
    }

    @IsTest
    static void onlyTheAudienceThePersonChoseIsShown() {
        Setup s = person();
        preference(s.profile.Id, 'Manager only', true);

        Test.startTest();
        List<CurbCutShow.Shown> team  = CurbCutShow.forRecord(s.handoff.Id, 'My team');
        List<CurbCutShow.Shown> hosts = CurbCutShow.forRecord(s.handoff.Id, 'Meeting hosts');
        Test.stopTest();

        System.assertEquals(0, team.size(), 'a manager-only preference is not for the team');
        System.assertEquals(0, hosts.size(), 'nor for meeting hosts');
        System.assertEquals(0, ledgerCount(), 'a refusal is not a disclosure');
    }

    @IsTest
    static void aPreferenceNotAskedToTravelStaysPut() {
        Setup s = person();
        preference(s.profile.Id, 'Manager only', false);

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(s.handoff.Id, 'Manager only');
        Test.stopTest();

        System.assertEquals(0, shown.size(),
            'Auto Apply off means the person did not ask for this to go ahead of them');
        System.assertEquals(0, ledgerCount());
    }

    @IsTest
    static void anAnonymousHandoffHasNothingBehindIt() {
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = 'I cannot type for long', Anonymous__c = true,
            Inbound_Modality__c = 'Text');
        insert br;
        Human_Handoff__c h = new Human_Handoff__c(
            Barrier_Report__c = br.Id, Reachable_By__c = 'Text message',
            Requested_At__c = System.now());
        insert h;

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(h.Id, 'Manager only');
        Test.stopTest();

        System.assertEquals(0, shown.size(), 'anonymous is a complete way to use this');
        System.assertEquals(0, ledgerCount());
    }

    @IsTest
    static void anUnknownAudienceIsRefusedBeforeAnythingIsRead() {
        Setup s = person();
        preference(s.profile.Id, 'Manager only', true);

        Boolean refused = false;
        Test.startTest();
        try {
            CurbCutShow.forRecord(s.handoff.Id, 'Everyone');
        } catch (AuraHandledException e) {
            refused = true;
        }
        Test.stopTest();

        System.assert(refused, 'an audience the person never chose must be refused');
        System.assertEquals(0, ledgerCount(), 'a refusal writes nothing');
    }

    @IsTest
    static void aRequestLeadsBackToTheSamePerson() {
        Setup s = person();
        preference(s.profile.Id, 'Meeting hosts', true);
        Accommodation_Request__c ar = new Accommodation_Request__c(
            Barrier_Report__c = s.report.Id, Person_Approved__c = true,
            Approved_At__c = System.now(), Manager_Response__c = 'Pending');
        insert ar;

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(ar.Id, 'Meeting hosts');
        Test.stopTest();

        System.assertEquals(1, shown.size());
        Disclosure_Event__c d = [SELECT Context__c FROM Disclosure_Event__c LIMIT 1];
        System.assert(d.Context__c.startsWith('Request AR-'),
            'the ledger names the request it was read from: ' + d.Context__c);
    }

    /**
     * The whole point. Before this class, WHO could only ever say that nobody
     * had been shown it. After one showing it must name a person and a date.
     */
    @IsTest
    static void whoNamesTheViewerAfterwards() {
        Setup s = person();
        // Saved the way a person saves it, so we hold the code they would hold.
        CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
            'Please send me the agenda the day before, in writing',
            'Always', 'Manager only', true);
        System.assert(saved.created, 'the preference must save: ' + saved.message);
        // The save path does not yet attach the person. We attach them here
        // the way an identified channel would.
        update new Access_Preference__c(Id = saved.preferenceId,
                                        Access_Profile__c = s.profile.Id);

        CurbCutStanding.Result before = CurbCutStanding.byCode('who', saved.claimCode);
        System.assert(before.message.contains('Nobody has been shown it yet'),
            'before any showing, WHO says so: ' + before.message);

        Test.startTest();
        List<CurbCutShow.Shown> shown = CurbCutShow.forRecord(s.handoff.Id, 'Manager only');
        CurbCutStanding.Result after = CurbCutStanding.byCode('who', saved.claimCode);
        Test.stopTest();

        System.assertEquals(1, shown.size());
        System.assert(after.message.contains(UserInfo.getName()),
            'WHO must name the person who saw it: ' + after.message);
        System.assert(after.message.contains(System.now().format('d MMMM yyyy')),
            'WHO must say when: ' + after.message);
        System.assert(!after.message.contains('Nobody has been shown it yet'),
            'after a showing, WHO can no longer say nobody has seen it');
    }
}
