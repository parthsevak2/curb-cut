/**
 * The signed-video assertions are the ones that matter. Everything this class
 * does for a photo is convenience; what it does for a video is a promise.
 */
@IsTest
private class CurbCutMediaTest {

    private static String bytes(String s) {
        return EncodingUtil.base64Encode(Blob.valueOf(s));
    }

    // The first bytes of real files, as cameras and phones write them. The
    // rest of each file is padding: the door reads the header and nothing else.
    private static final String JPEG = 'ffd8ffe000104a46494600010100';
    private static final String PNG  = '89504e470d0a1a0a0000000d49484452';
    private static final String GIF  = '474946383961';
    private static final String WEBP = '52494646240000005745425056503820';
    private static final String HEIC = '00000018' + '66747970' + '68656963' + '00000000'
                                     + '6d696631' + '68656963';             // ftyp heic, mif1 heic
    private static final String MP4  = '00000018' + '66747970' + '69736f6d' + '00000200'
                                     + '69736f6d' + '6d703431';             // ftyp isom, isom mp41
    private static final String MOV  = '00000014' + '66747970' + '71742020' + '00000000'
                                     + '71742020';                          // ftyp qt
    private static final String WEBM = '1a45dfa39f4286810142f7810142f2810442f381084282847765626d';
    private static final String PDF  = '255044462d312e370a';                // %PDF-1.7
    private static final String EXE  = '4d5a90000300000004000000ffff0000';  // MZ, a Windows program

    private static String file(String headHex) {
        return EncodingUtil.base64Encode(EncodingUtil.convertFromHex(headHex + '00'.repeat(96)));
    }
    private static String photo() { return file(JPEG); }
    private static String video() { return file(MP4); }

    @IsTest
    static void aSignedVideoRaisesAHumanImmediatelyAndIsNeverMachineTranslated() {
        Test.startTest();
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'signed.mp4', video(), 'Video');
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
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', photo(), 'Image');
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
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', photo(), 'Image');
        System.assertEquals(false, r.interpreter);
        System.assertEquals(0, [SELECT COUNT() FROM Human_Handoff__c],
            'A photo is not a request for a person');
    }

    @IsTest
    static void theFileIsActuallyAttachedToWhatTheySaid() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'desk.jpg', photo(), 'Image');
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :r.barrierId];
        System.assertEquals(1, links.size(),
            'A file that floats free of the person who sent it is worse than a refusal');
    }

    /** Nothing stored about a file may describe the person in it. */
    @IsTest
    static void nothingRecordedAboutTheFileIsMedical() {
        CurbCutMedia.Result r = CurbCutMedia.send(null, 'signed.mp4', video(), 'Video');
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
        CurbCutMedia.Result v = CurbCutMedia.send(null, 'signed.mp4', video(), 'Video');
        Test.startTest();
        CurbCutMedia.Result p = CurbCutMedia.send(v.barrierId, 'desk.jpg', photo(), 'Image');
        Test.stopTest();
        System.assertEquals(true, p.accepted);

        Barrier_Report__c br = [SELECT Interpreter_Needed__c, Inbound_Modality__c
                                FROM Barrier_Report__c WHERE Id = :v.barrierId];
        System.assertEquals(true, br.Interpreter_Needed__c,
            'A photo must never remove somebody\'s interpreter');
        System.assertEquals('Video', br.Inbound_Modality__c,
            'The channel that needs a human wins over the one that does not');
    }

    /** Whatever a phone or a camera makes, the door takes. */
    @IsTest
    static void everyKindOfPhotoAPhoneMakesIsTaken() {
        Map<String, String> photos = new Map<String, String>{
            'desk.jpg' => JPEG, 'screen.png' => PNG, 'reach.gif' => GIF,
            'chair.webp' => WEBP, 'IMG_0001.heic' => HEIC
        };
        Test.startTest();
        for (String name : photos.keySet()) {
            CurbCutMedia.Result r = CurbCutMedia.send(null, name, file(photos.get(name)), 'Image');
            System.assertEquals(true, r.accepted, name + ' was refused: ' + r.message);
            System.assertEquals(false, r.interpreter, name + ' is a photo, not a signed video');
        }
        Test.stopTest();
        System.assertEquals(photos.size(), [SELECT COUNT() FROM ContentVersion]);
    }

    @IsTest
    static void everyKindOfVideoAPhoneMakesIsTaken() {
        Map<String, String> videos = new Map<String, String>{
            'signed.mp4' => MP4, 'IMG_0002.mov' => MOV, 'recorded.webm' => WEBM
        };
        Test.startTest();
        for (String name : videos.keySet()) {
            CurbCutMedia.Result r = CurbCutMedia.send(null, name, file(videos.get(name)), 'Video');
            System.assertEquals(true, r.accepted, name + ' was refused: ' + r.message);
            System.assertEquals(true, r.interpreter,
                name + ' must still go to a person, not a machine');
        }
        Test.stopTest();
        System.assertEquals(videos.size(), [SELECT COUNT() FROM Human_Handoff__c]);
    }

    /**
     * A PDF or a program renamed desk.jpg is not a photo, and the person who
     * would open it is somebody on the access team. Nothing is created.
     */
    @IsTest
    static void aFileThatIsNotAPhotoIsTurnedAwayWhateverItIsCalled() {
        Test.startTest();
        CurbCutMedia.Result pdf  = CurbCutMedia.send(null, 'desk.jpg', file(PDF), 'Image');
        CurbCutMedia.Result exe  = CurbCutMedia.send(null, 'desk.jpg', file(EXE), 'Image');
        CurbCutMedia.Result text = CurbCutMedia.send(null, 'clip.mp4', bytes('just some words'), 'Video');
        Test.stopTest();

        for (CurbCutMedia.Result r : new List<CurbCutMedia.Result>{ pdf, exe, text }) {
            System.assertEquals(false, r.accepted, 'A file that is not media was kept');
            System.assert(r.message.contains('in words'),
                'The way out must always be offered: ' + r.message);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Barrier_Report__c],
            'A refused file must not open a report');
        System.assertEquals(0, [SELECT COUNT() FROM ContentVersion],
            'A refused file must not be stored');
        System.assertEquals(3, [SELECT COUNT() FROM Message_Log__c
                                WHERE Status__c = 'Rejected' AND Channel__c = 'Web'],
            'Each refusal is on the ledger, so an operator can see the door being tried');
    }

    /** What they chose and what they sent must agree, and they are told which way it went. */
    @IsTest
    static void aVideoSentAsAPhotoIsCaughtAndExplained() {
        Test.startTest();
        CurbCutMedia.Result videoAsPhoto = CurbCutMedia.send(null, 'clip.jpg', video(), 'Image');
        CurbCutMedia.Result photoAsVideo = CurbCutMedia.send(null, 'desk.mp4', photo(), 'Video');
        Test.stopTest();

        System.assertEquals(false, videoAsPhoto.accepted);
        System.assert(videoAsPhoto.message.contains('looks like a video'),
            'Say what it looked like: ' + videoAsPhoto.message);
        System.assertEquals(false, photoAsVideo.accepted);
        System.assert(photoAsVideo.message.contains('looks like a photo'),
            'Say what it looked like: ' + photoAsVideo.message);
        System.assertEquals(0, [SELECT COUNT() FROM Human_Handoff__c],
            'A photo labelled as video must not summon an interpreter');
        System.assertEquals(0, [SELECT COUNT() FROM ContentVersion]);
    }

    /** One report holds a handful of files, and then says so kindly. */
    @IsTest
    static void oneReportHoldsAHandfulOfFilesAndNoMore() {
        CurbCutMedia.Result first = CurbCutMedia.send(null, 'desk.jpg', photo(), 'Image');
        Test.startTest();
        for (Integer i = 1; i < CurbCutMedia.MAX_FILES; i++) {
            CurbCutMedia.Result more = CurbCutMedia.send(first.barrierId, 'desk-' + i + '.jpg', photo(), 'Image');
            System.assertEquals(true, more.accepted, 'File ' + (i + 1) + ' was refused: ' + more.message);
        }
        CurbCutMedia.Result tooMany = CurbCutMedia.send(first.barrierId, 'one-more.jpg', photo(), 'Image');
        Test.stopTest();

        System.assertEquals(false, tooMany.accepted, 'The limit must hold');
        System.assert(tooMany.message.contains('Nothing you sent is lost'),
            'They must be told the files they already sent are safe: ' + tooMany.message);
        System.assertEquals(CurbCutMedia.MAX_FILES,
            [SELECT ContentDocumentId FROM ContentDocumentLink
             WHERE LinkedEntityId = :first.barrierId].size(),
            'The refused file must not have been attached');
    }

    @IsTest
    static void theHeaderDecidesNotTheName() {
        System.assertEquals('Image', CurbCutMedia.sniff(file(JPEG)));
        System.assertEquals('Image', CurbCutMedia.sniff(file(HEIC)));
        System.assertEquals('Video', CurbCutMedia.sniff(file(MOV)));
        System.assertEquals('Video', CurbCutMedia.sniff(file(WEBM)));
        System.assertEquals(null, CurbCutMedia.sniff(file(PDF)));
        System.assertEquals(null, CurbCutMedia.sniff(file(EXE)));
        // A file shorter than the header still gets an answer rather than an error.
        System.assertEquals(null, CurbCutMedia.sniff(bytes('hi')));
        System.assertEquals('Image', CurbCutMedia.sniff(EncodingUtil.base64Encode(
            EncodingUtil.convertFromHex('ffd8ff'))));
    }
}
