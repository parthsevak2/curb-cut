/**
 * CurbCutKeys — the one place a code or a handle becomes a hash.
 *
 * Three salts used to live in three classes, in a public repository. A salt
 * anybody can read is not a secret, and a six-letter code hashed with a public
 * salt is still a six-letter code: anyone holding an export of this org could
 * try every one of them in an afternoon, then turn off somebody else's
 * preference or read who has been shown it.
 *
 * So the hash is now an HMAC, keyed by a secret that exists only in this org,
 * in a protected custom setting that no permission set grants. Each use gets
 * its own key, derived from that one, so a log handle can never be replayed as
 * a claim code and a return code can never be replayed as either.
 *
 * Nothing already handed out stops working. A code in somebody's pocket was
 * hashed the old way and keeps matching, because every lookup asks for both
 * forms. Only new rows get the new one. An org with no key yet keeps hashing
 * the old way, so a fresh install works before anybody has run the key script,
 * and isConfigured() says so plainly rather than pretending.
 *
 * The key is never returned, never logged and never put in a message. It is
 * read straight into a Blob and used there, and nothing here turns it back
 * into text. It is not held in a String variable even briefly, because a debug
 * log at FINEST records every variable assignment, and an admin chasing some
 * other bug would otherwise find the key in the log.
 */
public with sharing class CurbCutKeys {

    public enum Purpose { LOG_HANDLE, CLAIM_CODE, RETURN_CODE }

    /** generateAesKey(256) gives 32 bytes. Anything shorter counts as no key. */
    private static final Integer MIN_KEY_BYTES = 32;

    /**
     * The salts that shipped in source until this class existed. Public by
     * definition now, and kept for one reason only: to recognise codes and
     * handles already handed out. Nothing new is written with them while a key
     * is set.
     */
    private static final Map<Purpose, String> LEGACY_SALT = new Map<Purpose, String>{
        Purpose.LOG_HANDLE  => 'curb-cut-log-salt-v1',
        Purpose.CLAIM_CODE  => 'curb-cut-claim-salt-v1',
        Purpose.RETURN_CODE => 'curb-cut-return-salt-v1'
    };

    /** The same lengths as before, so no field had to change size. */
    private static final Map<Purpose, Integer> HEX_LENGTH = new Map<Purpose, Integer>{
        Purpose.LOG_HANDLE  => 32,
        Purpose.CLAIM_CODE  => 64,
        Purpose.RETURN_CODE => 64
    };

    /** One label per use. Changing a label orphans every hash made under it. */
    private static final Map<Purpose, String> DOMAIN = new Map<Purpose, String>{
        Purpose.LOG_HANDLE  => 'curb-cut/log-handle/v2',
        Purpose.CLAIM_CODE  => 'curb-cut/claim-code/v2',
        Purpose.RETURN_CODE => 'curb-cut/return-code/v2'
    };

    /** For the setup check. True only when a usable key is set on the org default. */
    public static Boolean isConfigured() {
        return master() != null;
    }

    /** What the setup check prints. Says whether there is a key, never what it is. */
    public static String describe() {
        return isConfigured()
            ? 'This org has its own signing key. New codes and handles are hashed with it.'
            : 'This org has no signing key yet, so new codes and handles are hashed with '
              + 'the old public salt. Run scripts/apex/generate-key.apex once to set one.';
    }

    /** The form to store: keyed when there is a key, the old form when there is not. */
    public static String digest(Purpose p, String value) {
        if (value == null) { return null; }
        Blob k = master();
        return k == null ? legacy(p, value) : keyed(k, p, value);
    }

    /**
     * Every form a stored hash of this value might be in. Match with IN, never
     * with =, or every code handed out before the key was set stops working.
     */
    public static Set<String> candidates(Purpose p, String value) {
        Set<String> out = new Set<String>();
        if (value == null) { return out; }
        Blob k = master();
        if (k != null) { out.add(keyed(k, p, value)); }
        out.add(legacy(p, value));
        return out;
    }

    /** SHA-256 of salt and value, exactly as the three classes used to do it. */
    @TestVisible
    private static String legacy(Purpose p, String value) {
        return EncodingUtil.convertToHex(Crypto.generateDigest(
            'SHA-256', Blob.valueOf(LEGACY_SALT.get(p) + value)))
            .substring(0, HEX_LENGTH.get(p));
    }

    /**
     * HMAC-SHA256 under a key derived for this one use. Deriving per purpose,
     * rather than mixing the label into the message, keeps the uses apart even
     * if a later caller hashes a value that happens to contain a label.
     */
    private static String keyed(Blob k, Purpose p, String value) {
        Blob forThisUse = Crypto.generateMac('hmacSHA256', Blob.valueOf(DOMAIN.get(p)), k);
        return EncodingUtil.convertToHex(Crypto.generateMac(
            'hmacSHA256', Blob.valueOf(value), forThisUse))
            .substring(0, HEX_LENGTH.get(p));
    }

    /**
     * The org default only. A per-user or per-profile value would give two
     * people two different hashes for the same code, and the code would work
     * for one of them.
     *
     * One expression on purpose: see the class comment about debug logs.
     */
    private static Blob master() {
        try {
            Blob k = EncodingUtil.base64Decode(Curb_Cut_Secret__c.getOrgDefaults().Key__c);
            return k.size() >= MIN_KEY_BYTES ? k : null;
        } catch (Exception e) {
            // No setting, an empty one, or something that is not base64. They
            // all mean the same thing here: there is no key yet.
            return null;
        }
    }
}
