// Creates this org's Curb Cut signing key, once.
//
//   sf apex run --file scripts/apex/generate-key.apex --target-org <alias>
//
// The key is 256 random bits from Crypto.generateAesKey, stored base64 on the
// org default of the protected custom setting Curb_Cut_Secret__c. CurbCutKeys
// uses it as the HMAC key for claim codes, return codes and delivery-log
// handles, so that an export of this org is no longer enough to work out
// anybody's code.
//
// Safe to run again. If the org already has a key, nothing changes. Replacing
// a key would stop every code issued under it from working, so this script
// never does that. If you truly mean to rotate, delete the org default by hand
// first, and accept that codes handed out since the key was set will stop.
// Codes handed out before any key was set keep working either way.
//
// The key is never printed and never logged. It is also never held in a
// variable, because a debug log at FINEST records every variable assignment,
// and the next person to turn logging up to chase some other bug would find
// it there. It goes straight from the generator into the insert.

Id org = UserInfo.getOrganizationId();
List<Curb_Cut_Secret__c> rows = [
    SELECT Id FROM Curb_Cut_Secret__c WHERE SetupOwnerId = :org LIMIT 1];
Integer keyed = [
    SELECT COUNT() FROM Curb_Cut_Secret__c WHERE SetupOwnerId = :org AND Key__c != null];

if (keyed > 0) {
    System.debug(LoggingLevel.INFO,
        'Curb Cut: this org already has a signing key. Nothing was changed.');
} else if (rows.isEmpty()) {
    insert new Curb_Cut_Secret__c(
        SetupOwnerId = org,
        Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256)));
    System.debug(LoggingLevel.INFO,
        'Curb Cut: a signing key was created for this org. It is not shown, on purpose.');
} else {
    update new Curb_Cut_Secret__c(
        Id = rows[0].Id,
        Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256)));
    System.debug(LoggingLevel.INFO,
        'Curb Cut: the empty org setting now holds a signing key. It is not shown, on purpose.');
}
