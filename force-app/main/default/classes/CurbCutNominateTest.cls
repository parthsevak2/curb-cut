/**
 * The nomination door. The promise on every channel is "they will never be
 * told who asked"; these tests hold the smaller promises that make that one
 * true: the payload keeps the person's casing, the record holds the workplace
 * and the door and nothing else, and the acting class is never handed the
 * sender at all.
 */
@IsTest
private class CurbCutNominateTest {

    @IsTest
    static void bareNominateGetsTheHowToAndWritesNothing() {
        CurbCutKeyword.Match m = CurbCutKeyword.route('nominate');
        System.assertEquals('NOMINATE', m.intent);
        System.assertEquals(null, m.payload);
        System.assert(m.message.contains('NOMINATE'), 'the how-to names the word');
        String said = CurbCutNominate.act(m.payload, 'SMS');
        System.assert(said.contains('NOMINATE'), 'a blank payload gets the how-to');
        System.assertEquals(0, [SELECT COUNT() FROM Nomination__c]);
    }

    @IsTest
    static void namingNobodyGetsTheHowTo() {
        for (String said : new List<String>{
                'nominate my workplace', 'Nominate my employer', 'NOMINATE us' }) {
            CurbCutKeyword.Match m = CurbCutKeyword.route(said);
            System.assertEquals('NOMINATE', m.intent, said);
            System.assertEquals(null, m.payload, 'no workplace was named: ' + said);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Nomination__c]);
    }

    @IsTest
    static void theWorkplaceKeepsTheirCasing() {
        CurbCutKeyword.Match m = CurbCutKeyword.route('NOMINATE Tim Hortons, Welland');
        System.assertEquals('NOMINATE', m.intent);
        System.assertEquals('Tim Hortons, Welland', m.payload);
    }

    @IsTest
    static void actWritesTheWorkplaceTheDoorAndNothingElse() {
        String said = CurbCutNominate.act('Acme Foods in Welland', 'SMS');
        Nomination__c n = [SELECT Workplace__c, Channel__c, Status__c FROM Nomination__c];
        System.assertEquals('Acme Foods in Welland', n.Workplace__c);
        System.assertEquals('SMS', n.Channel__c);
        System.assertEquals('New', n.Status__c);
        System.assert(said.contains('never be told who asked'), said);
    }

    @IsTest
    static void everythingBelowTheFirstLineIsDiscardedUnread() {
        CurbCutNominate.act('Acme Foods\nJohn Smith\n555 555 1234', 'Email');
        Nomination__c n = [SELECT Workplace__c FROM Nomination__c];
        System.assertEquals('Acme Foods', n.Workplace__c,
            'a signature below the name must never be stored');
    }

    @IsTest
    static void aLongNominationIsCutAtTheNameField() {
        String longName = 'The Very Long Workplace '.repeat(15);
        CurbCutNominate.act(longName, 'Email');
        Nomination__c n = [SELECT Workplace__c FROM Nomination__c];
        System.assertEquals(255, n.Workplace__c.length());
    }

    @IsTest
    static void anUnknownDoorArrivesAsExternal() {
        CurbCutNominate.act('Somewhere Real', 'Carrier pigeon');
        System.assertEquals('External', [SELECT Channel__c FROM Nomination__c].Channel__c);
    }

    @IsTest
    static void theSharedDoorRoutesIt() {
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle(
            'SMS', 'nominate Acme Foods', 'a'.repeat(32), null);
        System.assertEquals('NOMINATE', a.intent);
        System.assert(a.message.contains('Acme Foods'), a.message);
        System.assertEquals(1, [SELECT COUNT() FROM Nomination__c]);
    }

    @IsTest
    static void theWebDoorRoutesIt() {
        CurbCutWeb.Reply r = CurbCutWeb.consult('NOMINATE Niagara Widgets');
        System.assert(r.message.contains('Niagara Widgets'), r.message);
        System.assertEquals(1, [SELECT COUNT() FROM Nomination__c]);
    }

    @IsTest
    static void aBareWordAboveASignatureGetsTheHowTo() {
        CurbCutKeyword.Match m = CurbCutKeyword.route(
            'NOMINATE\n\nJohn Smith\nCommunity Advocate\n555 555 1234');
        System.assertEquals('NOMINATE', m.intent);
        System.assertEquals(null, m.payload,
            'nothing below the first line may ever become a workplace');
    }

    @IsTest
    static void theLedgerHoldsNoHashForANomination() {
        String h = 'b'.repeat(32);
        CurbCutChannelApi.handle('SMS', 'nominate Acme Foods', h, null);
        System.assertEquals(0,
            [SELECT COUNT() FROM Message_Log__c WHERE Recipient_Hash__c = :h],
            'a nomination must not be joinable to a person, not even by the ledger');
        System.assertEquals(1, [SELECT COUNT() FROM Nomination__c]);
    }

    @IsTest
    static void theVoiceDoorKeepsItsName() {
        CurbCutChannelApi.handle('External', 'nominate Acme Foods', null, null, 'Voice');
        System.assertEquals('Voice', [SELECT Channel__c FROM Nomination__c].Channel__c,
            'the record holds the door it really came through');
    }

    @IsTest
    static void aConditionBesideTheNameIsTakenOut() {
        String said = CurbCutNominate.act(
            'Acme Foods, I was diagnosed with epilepsy there', 'SMS');
        Nomination__c n = [SELECT Workplace__c FROM Nomination__c];
        System.assert(!n.Workplace__c.containsIgnoreCase('epilepsy'), n.Workplace__c);
        System.assert(!said.contains('epilepsy'), said);
    }
}
