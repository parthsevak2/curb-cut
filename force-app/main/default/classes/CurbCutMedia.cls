/**
 * CurbCutMedia — the two front doors that were listed but never opened.
 *
 * The site has said since the first week that a photo of your desk and a signed
 * video are front doors rather than fallbacks. Email accepted attachments; the
 * web did not. So for anyone without a phone plan, the two modalities that need
 * no typing at all were a promise and nothing else.
 *
 * A photo is often faster and less painful than describing a chair. A signed
 * video is, for some people, the only way they can say anything at all.
 *
 * Two rules are enforced here rather than documented:
 *
 * 1. Signed video is NEVER machine translated. It is marked as needing a human
 *    interpreter, a handoff is raised the moment it lands, and the person gets
 *    an acknowledgement immediately so they are not left watching a screen
 *    wondering whether it sent. The wait is the entire cost to them, so the
 *    wait starts with somebody saying "this arrived".
 *
 * 2. The system never describes what is in the file. No captioning, no vision
 *    model, no alt text generated on their behalf. A photo of a workstation is
 *    evidence a person chose to send; turning it into a machine's description of
 *    their body is the disclosure this whole project refuses.
 *
 * This door is anonymous, so it used to take anything under the size limit: a
 * PDF, a program renamed desk.jpg, a web page. Whatever it took landed in front
 * of a person on the access team, who would open it. So the first bytes of the
 * file now have to say photo or video, and say the same thing the person
 * chose. That is still not reading the file - nothing past the first few bytes
 * is looked at, and nothing about what it shows is ever worked out.
 */
global with sharing class CurbCutMedia {

    /** Visualforce remoting carries base64, which inflates by a third. */
    private static final Integer MAX_BYTES = 4 * 1024 * 1024;

    /**
     * Files one report will hold. Enough for a desk from three sides and a clip
     * of the thing that is hard; not enough for an open door to fill the org.
     */
    @TestVisible
    private static final Integer MAX_FILES = 5;

    /**
     * How much of the file we look at: 88 base64 characters, which is the first
     * 66 bytes. Enough for every header below, and taken from the base64 rather
     * than the decoded file, because turning four megabytes into hex to read
     * twelve bytes of it would run out of memory on the guest user's heap.
     */
    private static final Integer HEAD_CHARS = 88;

    /** HEIF brands: what an iPhone photo (heic) or any HEIF still (mif1) says it is. */
    private static final Set<String> STILL_BRANDS = new Set<String>{
        'heic', 'heix', 'heim', 'heis', 'hevc', 'hevx', 'hevm', 'hevs', 'mif1', 'msf1'
    };

    /** MP4, QuickTime and 3GP brands: what phones and cameras write on video. */
    private static final Set<String> MOVING_BRANDS = new Set<String>{
        'isom', 'iso2', 'iso3', 'iso4', 'iso5', 'iso6', 'mp41', 'mp42', 'avc1',
        'm4v ', 'm4vh', 'm4vp', 'qt  ', '3gp4', '3gp5', '3gp6', '3g2a', 'mmp4',
        'msnv', 'dash', 'f4v '
    };

    global class Result {
        global Boolean accepted     { get; set; }
        global String  message      { get; set; }
        global String  barrierId    { get; set; }
        global String  handoffId    { get; set; }
        global Boolean interpreter  { get; set; }
    }

    /**
     * The guest user can create a file but cannot link it to a record it is not
     * allowed to read, and secure guest record access means it cannot read the
     * barrier report it created moments ago. Without this the file uploads and
     * then floats free of the person who sent it, which is worse than refusing
     * the upload: they believe it arrived attached to their story.
     */
    private without sharing class Filer {
        private Id store(ContentVersion cv) {
            insert cv;
            return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        }
        private void link(Id docId, Id recordId) {
            insert new ContentDocumentLink(
                ContentDocumentId = docId, LinkedEntityId = recordId,
                ShareType = 'V', Visibility = 'AllUsers');
        }
        private void open(Barrier_Report__c br) { insert br; }
        private void markReport(Barrier_Report__c br) { update br; }
        private void raise(Human_Handoff__c h) { insert h; }
        /** Same reason as link: the guest user cannot see the report to count on it. */
        private Integer filesOn(Id recordId) {
            Integer enough = MAX_FILES + 1;
            return [SELECT Id FROM ContentDocumentLink
                     WHERE LinkedEntityId = :recordId
                     LIMIT :enough].size();
        }
    }

    /**
     * 'Image', 'Video', or null when the first bytes are neither. Reads the
     * header and nothing else.
     */
    @TestVisible
    private static String sniff(String base64) {
        String head = base64.left(HEAD_CHARS + 32).deleteWhitespace().left(HEAD_CHARS);
        head = head.left(head.length() - Math.mod(head.length(), 4));
        String hex;
        try {
            hex = EncodingUtil.convertToHex(EncodingUtil.base64Decode(head)).toLowerCase();
        } catch (Exception e) {
            return null;
        }
        if (hex.startsWith('ffd8ff'))                                      { return 'Image'; } // JPEG
        if (hex.startsWith('89504e470d0a1a0a'))                            { return 'Image'; } // PNG
        if (hex.startsWith('474946383761') || hex.startsWith('474946383961')) { return 'Image'; } // GIF87a, GIF89a
        if (hex.startsWith('52494646') && hex.length() >= 24
                && hex.substring(16, 24) == '57454250')                    { return 'Image'; } // RIFF....WEBP
        if (hex.startsWith('1a45dfa3'))                                    { return 'Video'; } // WebM (EBML)
        if (hex.length() >= 24 && hex.substring(8, 16) == '66747970')      { return isoMedia(hex); } // ....ftyp
        return null;
    }

    /**
     * MP4, MOV and HEIC all start with an ftyp box, so the box's brands decide.
     * The major brand is read first and the compatible brands after it, in
     * order, so an iPhone photo (heic, listing mif1) reads as a photo and a
     * camera clip with a maker's own major brand still reads as the video it
     * says it is compatible with. A brand we do not know is not guessed at.
     */
    private static String isoMedia(String hex) {
        Integer stop = hex.length();
        Long box = hexToLong(hex.substring(0, 8)) * 2;
        if (box < stop) { stop = box.intValue(); }
        List<String> brands = new List<String>{ brandAt(hex, 16) };
        for (Integer at = 32; at + 8 <= stop; at += 8) {
            brands.add(brandAt(hex, at));
        }
        for (String b : brands) {
            if (STILL_BRANDS.contains(b))  { return 'Image'; }
            if (MOVING_BRANDS.contains(b)) { return 'Video'; }
        }
        return null;
    }

    private static String brandAt(String hex, Integer at) {
        try {
            return EncodingUtil.convertFromHex(hex.substring(at, at + 8)).toString().toLowerCase();
        } catch (Exception e) {
            return '';
        }
    }

    private static Long hexToLong(String hex) {
        Long n = 0;
        for (Integer i = 0; i < hex.length(); i++) {
            n = n * 16 + '0123456789abcdef'.indexOf(hex.substring(i, i + 1));
        }
        return n;
    }

    /**
     * @param kind  'Image' or 'Video'. Anything else is refused rather than guessed.
     */
    @RemoteAction
    global static Result send(String barrierId, String fileName, String base64, String kind) {
        Result r = new Result();
        r.accepted = false;
        r.interpreter = false;

        Boolean isVideo = 'Video'.equalsIgnoreCase(kind);
        Boolean isImage = 'Image'.equalsIgnoreCase(kind);
        if (!isVideo && !isImage) {
            r.message = 'I can take a photo or a video, and I did not recognise that one. '
                      + 'I would rather say so than put it somewhere odd. Send a photo or '
                      + 'a video instead, or just tell me in words, whichever is easier.';
            return r;
        }
        if (String.isBlank(base64)) {
            r.message = 'Nothing came through. Try again, or just tell me in words.';
            return r;
        }

        Blob body;
        try { body = EncodingUtil.base64Decode(base64); }
        catch (Exception e) {
            r.message = 'That file did not arrive in one piece. Try again, or tell me in words.';
            return r;
        }
        if (body.size() > MAX_BYTES) {
            r.message = 'That file is larger than I can take here, which is about four '
                      + 'megabytes. A shorter clip or a smaller photo will work, and so '
                      + 'will simply telling me in words.';
            return r;
        }

        // The file has to be what it says it is, before anything is written.
        // Refused here, no report, file or handoff is created; the only trace
        // is the ledger line saying a file was turned away, never the file.
        String looksLike = sniff(base64);
        if (looksLike == null) {
            r.message = 'I could not open that as a photo or a video, so I did not keep it. '
                      + 'A photo or a clip from your phone will work. So will telling me in words.';
            CurbCutLog.record('Web', 'Inbound', 'Rejected', null,
                'media refused: not a photo or video', barrierId);
            return r;
        }
        if (looksLike == 'Video' && isImage) {
            r.message = 'That file looks like a video, not a photo. '
                      + 'Try sending it as a video instead, or just tell me in words.';
            CurbCutLog.record('Web', 'Inbound', 'Rejected', null,
                'media refused: a video sent as a photo', barrierId);
            return r;
        }
        if (looksLike == 'Image' && isVideo) {
            r.message = 'That file looks like a photo, not a video. '
                      + 'Try sending it as a photo instead, or just tell me in words.';
            CurbCutLog.record('Web', 'Inbound', 'Rejected', null,
                'media refused: a photo sent as a video', barrierId);
            return r;
        }

        // Sending a photo or a video may be the FIRST thing somebody does, and for
        // the people these two doors exist for it usually will be. Requiring them
        // to type a sentence first in order to be allowed to not type would be a
        // fairly complete misunderstanding of the problem.
        Filer filer = new Filer();
        Barrier_Report__c br;
        Boolean isNew = String.isBlank(barrierId);
        try {
            if (isNew) {
                br = new Barrier_Report__c(
                    Anonymous__c = true,
                    Inbound_Modality__c = isVideo ? 'Video' : 'Image',
                    Interpreter_Needed__c = isVideo,
                    Functional_Description__c = isVideo
                        ? 'Sent a signed video. Not transcribed, not machine translated. Waiting on a human interpreter.'
                        : 'Sent a photo instead of describing it in words.');
                filer.open(br);
            } else {
                // Never downgrade. Somebody who sends a signed video and then adds
                // a photo of their desk must not quietly lose their interpreter:
                // the flag is the only thing standing between them and a machine
                // translation, and nothing they do afterwards should remove it.
                Barrier_Report__c existing = [
                    SELECT Id, Interpreter_Needed__c, Inbound_Modality__c
                    FROM Barrier_Report__c WHERE Id = :Id.valueOf(barrierId) LIMIT 1];
                Boolean stillNeedsOne = isVideo || existing.Interpreter_Needed__c == true;
                br = new Barrier_Report__c(
                    Id = existing.Id,
                    Inbound_Modality__c = stillNeedsOne ? 'Video'
                                        : (isVideo ? 'Video' : 'Image'),
                    Interpreter_Needed__c = stillNeedsOne);
            }
        } catch (Exception e) {
            r.message = 'I lost track of the conversation. Tell me again what is hard, '
                      + 'and send it after that.';
            return r;
        }

        // Counted before the report is touched, so a refusal changes nothing.
        if (!isNew && filer.filesOn(br.Id) >= MAX_FILES) {
            r.message = 'I already have ' + MAX_FILES + ' files for this, and that is as many '
                      + 'as I can keep together. Nothing you sent is lost. A person will look '
                      + 'at them. If there is more to say, tell me in words.';
            r.barrierId = br.Id;
            CurbCutLog.record('Web', 'Inbound', 'Rejected', null,
                'media refused: file limit for one report', br.Id);
            return r;
        }

        try {
            ContentVersion cv = new ContentVersion(
                Title = String.isBlank(fileName)
                        ? (isVideo ? 'Signed video' : 'Photo') : fileName.left(255),
                PathOnClient = String.isBlank(fileName)
                        ? (isVideo ? 'signed-video' : 'photo') : fileName.left(255),
                VersionData = body,
                // What it is, never what is in it. Nothing here describes a person.
                Description = isVideo
                    ? 'Signed video. Never machine translated. Waits for a human interpreter.'
                    : 'Photo sent by the person, in place of describing it in words.');
            Id docId = filer.store(cv);
            filer.link(docId, br.Id);
            if (!isNew) { filer.markReport(br); }
        } catch (Exception e) {
            r.message = 'I could not hold on to that file, and that is not your problem '
                      + 'to solve. Tell me in words instead and a person will pick it up.';
            CurbCutLog.record('Web', 'Inbound', 'Rejected', null,
                'media upload failed: ' + e.getMessage(), barrierId);
            return r;
        }

        r.accepted = true;
        r.barrierId = br.Id;
        CurbCutLog.record('Web', 'Inbound', 'Accepted', null,
            (isVideo ? 'signed video' : 'photo') + ' received, ' + body.size() + ' bytes', br.Id);

        if (isVideo) {
            // A person, immediately. Nothing about this waits for office hours.
            Human_Handoff__c h = new Human_Handoff__c(
                Barrier_Report__c = br.Id,
                Requested_At__c = System.now(),
                Reachable_By__c = 'Video');
            try {
                filer.raise(h);
                r.handoffId = h.Id;
            } catch (Exception ignored) {
                // The video is safely stored; losing the handoff must not lose the video.
            }
            r.interpreter = true;
            r.message = 'Your video arrived. It goes to a person, not a machine - we do '
                      + 'not machine translate signed video, ever. Someone is being asked '
                      + 'to look at it now, and you will get a message here as soon as an '
                      + 'interpreter is booked. You do not have to wait on this screen.';
            CurbCutLog.record('Web', 'Outbound', 'Accepted', null,
                'immediate acknowledgement for signed video', br.Id);
        } else {
            r.message = 'Your photo arrived. Nobody will run it through anything that '
                      + 'guesses what is in it; a person looks at it. If you want to add '
                      + 'a sentence about what is hard, you can, but you do not have to.';
        }
        return r;
    }
}
