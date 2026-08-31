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
 */
global with sharing class CurbCutMedia {

    /** Visualforce remoting carries base64, which inflates by a third. */
    private static final Integer MAX_BYTES = 4 * 1024 * 1024;

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
            r.message = 'I can take a photo or a video. I did not recognise that one, '
                      + 'and I would rather say so than put it somewhere odd.';
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
