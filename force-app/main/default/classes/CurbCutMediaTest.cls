/**
 * The signed-video assertions are the ones that matter. Everything this class
 * does for a photo is convenience; what it does for a video is a promise.
 */
@IsTest
private class CurbCutMediaTest {

    private static String bytes(String s) {
        return EncodingUtil.base64Encode(Blob.valueOf(s));
    }

    @IsTest
    static void aSignedVideoRaisesAHumanImmediatelyAndIsNeverMachineTranslated() {
        Test.startTest();
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'signed.mp4', bytes('video-bytes'), 'Video');
        Test.stopTest();

        System.assertEquals(true, r.accepted);
        System.assertEquals(true, r.interpreter);
        System.assertNotEquals(null, r.handoffId,
            'A signed video must raise a person the moment it lands');

        Barrier_Report__c br = [SELECT Inbound_Modality__c, Interpreter_Needed__c,
                                       Functional_Description__c
                                FROM Barrier_Report__c WHERE Id = :r.barrierId];
        System.assertEquals('Video', br.Inbound_Modality__c);
        System.assertEquals(true, br.Interpreter_Needed__c);

        Human_Handoff__c h = [SELECT Reachable_By__c, Requested_At__c, Interpreter_Booked_At__c
                              FROM Human_Handoff__c WHERE Id = :r.handoffId];
        System.assertEquals('Video', h.Reachable_By__c,
            'They must be reached the way they reached us');
        System.assertEquals(null, h.Interpreter_Booked_At__c,
            'Booking is a human act, not a side effect of upload');

        System.assert(r.message.contains('not a machine'),
            'The person must be told plainly it is not machine translated: ' + r.message);
    }

    /**
     * Sending a photo or a video may be the FIRST thing somebody does. Requiring
     * a typed sentence first, in order to be allowed to not type, would be a
     * fairly complete misunderstanding of the problem.
     */
    @IsTest
    static void mediaCanBeTheFirstThingSomebodySends() {
        Test.startTest();
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', bytes('photo'), 'Image');
        Test.stopTest();
        System.assertEquals(true, r.accepted);
        System.assertNotEquals(null, r.barrierId, 'It must open its own report');
        Barrier_Report__c br = [SELECT Anonymous__c, Inbound_Modality__c
                                FROM Barrier_Report__c WHERE Id = :r.barrierId];
        System.assertEquals('Image', br.Inbound_Modality__c);
        System.assertEquals(true, br.Anonymous__c,
            'Nobody has given a name by sending a photo');
    }

    @IsTest
    static void aPhotoDoesNotSummonAnInterpreter() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', bytes('photo'), 'Image');
        System.assertEquals(false, r.interpreter);
        System.assertEquals(0, [SELECT COUNT() FROM Human_Handoff__c],
            'A photo is not a request for a person');
    }

    @IsTest
    static void theFileIsActuallyAttachedToWhatTheySaid() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', bytes('photo'), 'Image');
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :r.barrierId];
        System.assertEquals(1, links.size(),
            'A file that floats free of the person who sent it is worse than a refusal');
    }

    /** Nothing stored about a file may describe the person in it. */
    @IsTest
    static void nothingRecordedAboutTheFileIsMedical() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'signed.mp4', bytes('v'), 'Video');
        ContentVersion cv = [SELECT Description, Title FROM ContentVersion LIMIT 1];
        String all = (cv.Description + ' ' + cv.Title).toLowerCase();
        for (String w : new List<String>{'diagnos','condition','disabilit','severity','prognos'}) {
            System.assert(!all.contains(w),
                'Stored file metadata mentions ' + w + ': ' + cv.Description);
        }
        Barrier_Report__c br = [SELECT Functional_Description__c FROM Barrier_Report__c
                                WHERE Id = :r.barrierId];
        System.assert(!br.Functional_Description__c.containsIgnoreCase('diagnos'),
            'The auto-written description must stay functional');
    }

    @IsTest
    static void refusesWhatItCannotPlaceRatherThanGuessing() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'notes.txt', bytes('x'), 'Document');
        System.assertEquals(false, r.accepted);
        System.assert(r.message.contains('rather say so'),
            'Refusal must be explained plainly: ' + r.message);
        System.assertEquals(0, [SELECT COUNT() FROM Barrier_Report__c]);
    }

    @IsTest
    static void refusesAnEmptyUploadKindly() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'x.jpg', '', 'Image');
        System.assertEquals(false, r.accepted);
        System.assert(r.message.contains('tell me in words'),
            'The way out must always be offered: ' + r.message);
    }

    /**
     * The one that bit. Somebody sends a signed video, then adds a photo of
     * their desk, and the second upload overwrote the modality and cleared
     * Interpreter Needed. That flag is the only thing standing between them and
     * a machine translation, and nothing they do afterwards may remove it.
     */
    @IsTest
    static void aLaterPhotoCannotStripTheInterpreterFromASignedVideo() {
        CurbCutMedia.Result v = CurbCutMedia.send(null, 'signed.mp4', bytes('v'), 'Video');
        Test.startTest();
        CurbCutMedia.Result p = CurbCutMedia.send(v.barrierId, 'desk.jpg', bytes('p'), 'Image');
        Test.stopTest();
        System.assertEquals(true, p.accepted);

        Barrier_Report__c br = [SELECT Interpreter_Needed__c, Inbound_Modality__c
                                FROM Barrier_Report__c WHERE Id = :v.barrierId];
        System.assertEquals(true, br.Interpreter_Needed__c,
            'A photo must never remove somebody\'s interpreter');
        System.assertEquals('Video', br.Inbound_Modality__c,
            'The channel that needs a human wins over the one that does not');
    }
}
