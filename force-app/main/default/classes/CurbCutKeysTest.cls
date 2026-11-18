/**
 * The key is the only thing standing between an org export and every code a
 * person is holding. These assert what must hold either side of the day it is
 * set: a fresh install still works, a code from before the key still works,
 * a code from after it is hashed in a form nobody outside the org can compute,
 * and the key itself is never handed back to anyone.
 *
 * Custom setting rows are not visible to tests, so every test starts with no
 * key, exactly like a fresh install, and sets one only when it means to.
 */
@IsTest
private class CurbCutKeysTest {

    private static final CurbCutKeys.Purpose CLAIM  = CurbCutKeys.Purpose.CLAIM_CODE;
    private static final CurbCutKeys.Purpose BACK   = CurbCutKeys.Purpose.RETURN_CODE;
    private static final CurbCutKeys.Purpose HANDLE = CurbCutKeys.Purpose.LOG_HANDLE;

    /** What generate-key.apex does, minus the care about logs. */
    private static String setKey() {
        String k = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        insert new Curb_Cut_Secret__c(SetupOwnerId = UserInfo.getOrganizationId(), Key__c = k);
        return k;
    }

    /**
     * The old form, recomputed here from the salts that shipped rather than
     * asked of CurbCutKeys, so a change to the legacy form cannot pass by
     * agreeing with itself. If this drifts, codes in people's pockets stop.
     */
    private static String shipped(String salt, String value, Integer len) {
        return EncodingUtil.convertToHex(Crypto.generateDigest(
            'SHA-256', Blob.valueOf(salt + value))).substring(0, len);
    }

    private static CurbCutWeb.Reply savePreference() {
        CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
            'I need captions on every call', 'Always', 'Manager only', false);
        System.assert(saved.created, 'setup: the preference must save: ' + saved.message);
        return saved;
    }

    // ---- no key: a fresh install -------------------------------------------

    @IsTest
    static void withoutAKeyEverythingIsHashedTheOldWay() {
        System.assertEquals(false, CurbCutKeys.isConfigured(), 'A fresh org has no key');
        System.assertEquals(shipped('curb-cut-log-salt-v1', '+15551234567', 32),
            CurbCutLog.handleFor('+15551234567'), 'log handles, as before');
        System.assertEquals(shipped('curb-cut-claim-salt-v1', '4KQ7MT', 64),
            CurbCutKeys.digest(CLAIM, '4KQ7MT'), 'claim codes, as before');
        System.assertEquals(shipped('curb-cut-return-salt-v1', '4KQ7MT', 64),
            CurbCutKeys.digest(BACK, '4KQ7MT'), 'return codes, as before');
        System.assertEquals(1, CurbCutKeys.candidates(CLAIM, '4KQ7MT').size(),
            'With no key there is only one form to look for');
        System.assert(CurbCutKeys.describe().contains('generate-key.apex'),
            'The setup check must say how to fix it: ' + CurbCutKeys.describe());
    }

    @IsTest
    static void withoutAKeyAPreferenceStillSavesAndTurnsOff() {
        CurbCutWeb.Reply saved = savePreference();
        Access_Preference__c p = [SELECT Claim_Code_Hash__c FROM Access_Preference__c
                                  WHERE Id = :saved.preferenceId];
        System.assertEquals(shipped('curb-cut-claim-salt-v1', saved.claimCode, 64),
            p.Claim_Code_Hash__c, 'No key yet, so the old form is what gets stored');

        Test.startTest();
        CurbCutStanding.Result off = CurbCutStanding.byCode('revoke', saved.claimCode);
        Test.stopTest();
        System.assertEquals(true, off.ok, 'A fresh install must work before anybody sets a key');
    }

    /** A key that is not a key is treated as no key, and the check says so. */
    @IsTest
    static void aKeyThatIsTooShortCountsAsNone() {
        insert new Curb_Cut_Secret__c(SetupOwnerId = UserInfo.getOrganizationId(),
            Key__c = EncodingUtil.base64Encode(Blob.valueOf('too short')));
        System.assertEquals(false, CurbCutKeys.isConfigured(), 'nine bytes is not a 256-bit key');
        System.assertEquals(CurbCutKeys.legacy(CLAIM, '4KQ7MT'), CurbCutKeys.digest(CLAIM, '4KQ7MT'));
    }

    /**
     * Only the org default counts. A key on one user would give that user
     * different hashes from everyone else, and their code would work for them
     * and nobody else.
     */
    @IsTest
    static void aKeyOnOneUserIsNotTheOrgsKey() {
        insert new Curb_Cut_Secret__c(SetupOwnerId = UserInfo.getUserId(),
            Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256)));
        System.assertEquals(false, CurbCutKeys.isConfigured());
    }

    // ---- with a key ----------------------------------------------------------

    @IsTest
    static void withAKeyNewHashesAreNotTheOldOnes() {
        setKey();
        System.assertEquals(true, CurbCutKeys.isConfigured());
        System.assert(CurbCutKeys.describe().contains('own signing key'), CurbCutKeys.describe());
        for (CurbCutKeys.Purpose p : CurbCutKeys.Purpose.values()) {
            String keyed = CurbCutKeys.digest(p, '4KQ7MT');
            String old   = CurbCutKeys.legacy(p, '4KQ7MT');
            System.assertNotEquals(old, keyed, p.name() + ': the keyed hash must not be the public one');
            System.assertEquals(old.length(), keyed.length(),
                p.name() + ': the same length as before, so no field had to change');
            System.assert(Pattern.matches('[0-9a-f]+', keyed), p.name() + ': hex, as before: ' + keyed);
            System.assertEquals(keyed, CurbCutKeys.digest(p, '4KQ7MT'),
                p.name() + ': the same code must hash the same way every time');
            Set<String> both = CurbCutKeys.candidates(p, '4KQ7MT');
            System.assertEquals(2, both.size(), p.name() + ': a lookup accepts exactly two forms');
            System.assert(both.contains(keyed) && both.contains(old),
                p.name() + ': a lookup must accept the new form and the old one');
        }
    }

    /** A return code must never open a preference, and neither may a handle. */
    @IsTest
    static void eachUseGetsItsOwnHash() {
        setKey();
        String asClaim  = CurbCutKeys.digest(CLAIM, '4KQ7MT');
        String asReturn = CurbCutKeys.digest(BACK, '4KQ7MT');
        String asHandle = CurbCutKeys.digest(HANDLE, '4KQ7MT');
        System.assertNotEquals(asClaim, asReturn, 'claim and return codes share a hash');
        System.assertNotEquals(asClaim.left(32), asHandle, 'a handle is a prefix of a claim hash');
        System.assertNotEquals(asReturn.left(32), asHandle, 'a handle is a prefix of a return hash');
    }

    /** A hash that does not change with the key is not keyed by it. */
    @IsTest
    static void theHashFollowsTheKey() {
        Curb_Cut_Secret__c s = new Curb_Cut_Secret__c(SetupOwnerId = UserInfo.getOrganizationId(),
            Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256)));
        insert s;
        String first = CurbCutKeys.digest(CLAIM, '4KQ7MT');
        s.Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        update s;
        System.assertNotEquals(first, CurbCutKeys.digest(CLAIM, '4KQ7MT'),
            'Two orgs with two keys must not produce the same hash');
    }

    // ---- claim codes, either side of the key ---------------------------------

    /** The case that matters most: a code somebody was given last month. */
    @IsTest
    static void aClaimCodeFromBeforeTheKeyStillWorks() {
        CurbCutWeb.Reply saved = savePreference();
        setKey();

        Test.startTest();
        CurbCutStanding.Result who = CurbCutStanding.byCode('who', saved.claimCode);
        CurbCutStanding.Result off = CurbCutStanding.byCode('revoke', saved.claimCode.toLowerCase());
        Test.stopTest();

        System.assertEquals(true, who.ok, 'WHO with a code from before the key: ' + who.message);
        System.assertEquals(saved.preferenceId, who.preferenceId, 'It must find their preference');
        System.assertEquals(true, off.ok, 'OFF with a code from before the key: ' + off.message);
        System.assertNotEquals(null,
            [SELECT Revoked_On__c FROM Access_Preference__c WHERE Id = :saved.preferenceId].Revoked_On__c,
            'Setting a key must never be the day somebody loses the way to turn this off');
    }

    @IsTest
    static void aClaimCodeFromAfterTheKeyIsStoredKeyedAndWorks() {
        setKey();
        CurbCutWeb.Reply saved = savePreference();
        Access_Preference__c p = [SELECT Claim_Code_Hash__c FROM Access_Preference__c
                                  WHERE Id = :saved.preferenceId];
        System.assertEquals(CurbCutKeys.digest(CLAIM, saved.claimCode), p.Claim_Code_Hash__c,
            'New rows store the keyed form');
        System.assertNotEquals(shipped('curb-cut-claim-salt-v1', saved.claimCode, 64),
            p.Claim_Code_Hash__c, 'A new row must not hold a hash anyone with the source can compute');

        Test.startTest();
        CurbCutWeb.Reply who = CurbCutWeb.whoSaw(saved.claimCode);
        CurbCutWeb.Reply off = CurbCutWeb.revokeStanding(saved.claimCode);
        Test.stopTest();
        System.assertEquals(0, who.shownCount, 'WHO must find it: ' + who.message);
        System.assertEquals(true, off.created, 'OFF must find it: ' + off.message);
    }

    /** Accepting two forms must not turn a wrong code into a right one. */
    @IsTest
    static void aWrongCodeIsStillWrongWithAKey() {
        setKey();
        savePreference();
        CurbCutStanding.Result wrong = CurbCutStanding.byCode('revoke', 'ZZZZZZ');
        System.assertEquals(false, wrong.ok);
        System.assertEquals(0, [SELECT COUNT() FROM Access_Preference__c WHERE Revoked_On__c != null]);
    }

    // ---- return codes and handles, either side of the key ---------------------

    @IsTest
    static void aReturnCodeFromEitherSideOfTheKeyFindsItsHandoff() {
        CurbCutWeb.Reply before = CurbCutWeb.human('', null);
        System.assert(before.created, 'setup: the first handoff must be created');
        setKey();
        CurbCutWeb.Reply after = CurbCutWeb.human('', null);
        System.assert(after.created, 'setup: the second handoff must be created');

        Set<String> oldForms = CurbCutCreateHandoff.returnCodeHashes(before.claimCode);
        Set<String> newForms = CurbCutCreateHandoff.returnCodeHashes(' ' + after.claimCode.toLowerCase());
        List<Human_Handoff__c> oldOne = [SELECT Id, Return_Code_Hash__c FROM Human_Handoff__c
                                         WHERE Return_Code_Hash__c IN :oldForms];
        List<Human_Handoff__c> newOne = [SELECT Id, Return_Code_Hash__c FROM Human_Handoff__c
                                         WHERE Return_Code_Hash__c IN :newForms];

        System.assertEquals(1, oldOne.size(), 'A code given before the key must still lead back');
        System.assertEquals(1, newOne.size(), 'A code given after the key must lead back');
        System.assertNotEquals(oldOne[0].Id, newOne[0].Id, 'Each code leads to its own handoff');
        System.assertEquals(shipped('curb-cut-return-salt-v1', before.claimCode, 64),
            oldOne[0].Return_Code_Hash__c, 'The old row is untouched');
        System.assertNotEquals(shipped('curb-cut-return-salt-v1', after.claimCode, 64),
            newOne[0].Return_Code_Hash__c, 'The new row holds the keyed form');
        System.assertEquals(0, CurbCutCreateHandoff.returnCodeHashes('').size(),
            'No code, nothing to look for');
    }

    /** One person's ledger must not split in two on the day the key is set. */
    @IsTest
    static void aPersonsLedgerRowsStillJoinAcrossTheKey() {
        CurbCutLog.record('SMS', 'Outbound', 'Accepted', 'relay-handle-1', 'before the key', null);
        setKey();
        CurbCutLog.record('SMS', 'Outbound', 'Accepted', 'relay-handle-1', 'after the key', null);
        CurbCutLog.record('SMS', 'Outbound', 'Accepted', 'relay-handle-2', 'someone else', null);

        Set<String> handles = CurbCutLog.handlesFor('relay-handle-1');
        List<Message_Log__c> rows = [SELECT Recipient_Hash__c FROM Message_Log__c
                                     WHERE Recipient_Hash__c IN :handles];
        System.assertEquals(2, rows.size(), 'Both of their rows, and nobody else\'s');
        System.assertNotEquals(rows[0].Recipient_Hash__c, rows[1].Recipient_Hash__c,
            'The row written after the key holds the keyed form');
        for (Message_Log__c m : rows) {
            System.assertEquals(32, m.Recipient_Hash__c.length(), 'Same length as before');
            System.assert(!m.Recipient_Hash__c.contains('relay-handle'), 'Never the handle itself');
        }
        System.assertEquals(0, CurbCutLog.handlesFor('').size());
    }

    // ---- the key itself ------------------------------------------------------

    /**
     * Every surface a person or an operator can read, with a key set: the
     * setup check's sentence, every hash, every reply on every door, and every
     * ledger row. The key, in either encoding, must be in none of them.
     */
    @IsTest
    static void theKeyIsNeverHandedBack() {
        String k = setKey();
        String kHex = EncodingUtil.convertToHex(EncodingUtil.base64Decode(k));

        List<String> said = new List<String>{
            CurbCutKeys.describe(), String.valueOf(CurbCutKeys.isConfigured())
        };
        for (CurbCutKeys.Purpose p : CurbCutKeys.Purpose.values()) {
            said.add(CurbCutKeys.digest(p, '4KQ7MT'));
            said.add(String.valueOf(CurbCutKeys.candidates(p, '4KQ7MT')));
        }
        CurbCutWeb.Reply saved = savePreference();
        said.add(JSON.serialize(saved));
        said.add(JSON.serialize(CurbCutStanding.byCode('who', saved.claimCode)));
        said.add(JSON.serialize(CurbCutStanding.byCode('who', 'ZZZZZZ')));
        said.add(JSON.serialize(CurbCutWeb.human('', null)));
        said.add(JSON.serialize(CurbCutChannelApi.handle('SMS', 'OFF ' + saved.claimCode,
                                                         'relay-handle-3', null)));
        for (Message_Log__c m : [SELECT Detail__c, Recipient_Hash__c FROM Message_Log__c]) {
            said.add(m.Detail__c + ' ' + m.Recipient_Hash__c);
        }

        String all = String.join(said, '\n');
        System.assert(!all.contains(k), 'The key, base64, appeared in something handed back');
        System.assert(!all.containsIgnoreCase(kHex), 'The key, as hex, appeared in something handed back');
        System.assert(!all.contains(k.left(16)), 'Part of the key appeared in something handed back');
    }

    /**
     * The guest user holds no permission on the setting, by design. Apex must
     * still hash with the key on its behalf, or every web visitor's code would
     * quietly be stored in the public form.
     */
    @IsTest
    static void aVisitorWithNoGrantStillGetsTheKeyedForm() {
        setKey();
        String expected = CurbCutKeys.digest(CLAIM, '4KQ7MT');
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
            u = new User(
                FirstName = 'Curb', LastName = 'Visitor',
                Alias = 'ccvis', Email = 'curbcut.visitor@example.invalid',
                Username = 'curbcut.keys.' + DateTime.now().getTime() + '@example.invalid',
                ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US');
            insert u;
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId =
                [SELECT Id FROM PermissionSet WHERE Name = 'Curb_Cut_Guest' LIMIT 1].Id);
        }
        System.runAs(u) {
            System.assertEquals(true, CurbCutKeys.isConfigured(),
                'A visitor must be hashed with the key without being granted it');
            System.assertEquals(expected, CurbCutKeys.digest(CLAIM, '4KQ7MT'));
        }
    }
}
