/**
 * Curb Cut — scenario seed.
 *
 * Ten situations that actually walk through the door, so the console shows a
 * working week rather than an empty table. Re-runnable: it clears previously
 * seeded scenario rows first, identified by the handles it sets, and never
 * touches the accommodation library.
 *
 * Every functional description here is what someone would say about their work.
 * None of them says why, because there is nowhere to put why, and a seed file
 * that quietly invented a diagnosis field would be the loudest possible way to
 * miss the point.
 *
 * Run:  sf apex run -f data/seed-scenarios.apex -o curbcut
 */

// ---- clear previously seeded scenarios (never the library) -----------------
List<Access_Profile__c> oldProfiles =
    [SELECT Id FROM Access_Profile__c WHERE Person_Handle__c LIKE 'seed-%'];
if (!oldProfiles.isEmpty()) { delete oldProfiles; }
// Requests and handoffs that were created by earlier ad-hoc testing and carry
// no words of anybody's are noise in every queue they appear in.
List<Accommodation_Request__c> orphans =
    [SELECT Id FROM Accommodation_Request__c WHERE Barrier_Report__c = null];
if (!orphans.isEmpty()) { delete orphans; }

// ---- profiles: only for the people who chose to be known ------------------
List<Access_Profile__c> profiles = new List<Access_Profile__c>{
    new Access_Profile__c(Person_Handle__c = 'seed-a1', Active__c = true,
        Preferred_Modality__c = 'Video',      Never_Call__c = true),
    new Access_Profile__c(Person_Handle__c = 'seed-b2', Active__c = true,
        Preferred_Modality__c = 'Text',       Never_Call__c = true,
        Plain_Language_Mode__c = true),
    new Access_Profile__c(Person_Handle__c = 'seed-c3', Active__c = true,
        Preferred_Modality__c = 'Voice note', Never_Call__c = false)
};
insert profiles;

// ---- what people said was hard --------------------------------------------
List<Barrier_Report__c> reports = new List<Barrier_Report__c>{
    new Barrier_Report__c(   // 1. deaf employee, signed video, waiting on a person
        Functional_Description__c = 'I miss most of what is said in team meetings. Reading lips does not work when several people talk at once.',
        Inbound_Modality__c = 'Video', Interpreter_Needed__c = true,
        Anonymous__c = false, Access_Profile__c = profiles[0].Id),
    new Barrier_Report__c(   // 2. chronic pain, the canonical sentence
        Functional_Description__c = 'I cannot type for long. By the afternoon my hands are done and I start making mistakes.',
        Inbound_Modality__c = 'Text', Anonymous__c = true),
    new Barrier_Report__c(   // 3. sensory, open plan
        Functional_Description__c = 'The open office is unbearable by two o clock. I can do the work, I just cannot do it there.',
        Inbound_Modality__c = 'Text', Anonymous__c = true),
    new Barrier_Report__c(   // 4. low vision
        Functional_Description__c = 'I cannot read the dashboards. Everything is small and low contrast and I lose the row I am on.',
        Inbound_Modality__c = 'Text', Anonymous__c = false, Access_Profile__c = profiles[1].Id),
    new Barrier_Report__c(   // 5. energy, treatment schedule
        Functional_Description__c = 'Some mornings I cannot get in for nine. I can work later and make the hours up.',
        Inbound_Modality__c = 'Voice note', Anonymous__c = false, Access_Profile__c = profiles[2].Id),
    new Barrier_Report__c(   // 6. only ever wanted to know
        Functional_Description__c = 'I just wanted to find out what people are allowed to ask for. I am not asking for anything yet.',
        Inbound_Modality__c = 'Text', Anonymous__c = true),
    new Barrier_Report__c(   // 7. cannot use the phone
        Functional_Description__c = 'I cannot use the phone. Every process here ends with give us a call and then I am stuck.',
        Inbound_Modality__c = 'Text', Anonymous__c = true),
    new Barrier_Report__c(   // 8. photo of a workstation
        Functional_Description__c = 'Sent a photo of my desk. The screen is too low and my neck is bad by lunchtime.',
        Inbound_Modality__c = 'Image', Anonymous__c = true),
    new Barrier_Report__c(   // 9. second signed video, still queued
        Functional_Description__c = 'Signed message about needing an interpreter booked before the quarterly review, not during it.',
        Inbound_Modality__c = 'Video', Interpreter_Needed__c = true, Anonymous__c = true),
    new Barrier_Report__c(   // 10. applicant, no work account at all
        Functional_Description__c = 'I have an interview next week and the assessment is timed. I do not work here yet so I have no login to ask anyone.',
        Inbound_Modality__c = 'Text', Anonymous__c = true)
};
insert reports;

// ---- requests, at every stage of the clock ---------------------------------
List<Accommodation_Request__c> requests = new List<Accommodation_Request__c>{
    new Accommodation_Request__c(   // approved, done well
        Barrier_Report__c = reports[1].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-12),
        Interactive_Process_Due__c = Date.today().addDays(-2),
        Manager_Response__c = 'Approved'),
    new Accommodation_Request__c(   // running out of time, nobody has answered
        Barrier_Report__c = reports[2].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-8),
        Interactive_Process_Due__c = Date.today().addDays(2),
        Manager_Response__c = 'Pending'),
    new Accommodation_Request__c(   // overdue
        Barrier_Report__c = reports[3].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-15),
        Interactive_Process_Due__c = Date.today().addDays(-3),
        Manager_Response__c = 'Pending'),
    new Accommodation_Request__c(   // fresh
        Barrier_Report__c = reports[4].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-1),
        Interactive_Process_Due__c = Date.today().addDays(9),
        Manager_Response__c = 'Pending'),
    new Accommodation_Request__c(   // the answer that quietly kills requests
        Barrier_Report__c = reports[7].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-5),
        Interactive_Process_Due__c = Date.today().addDays(5),
        Manager_Response__c = 'More info'),
    new Accommodation_Request__c(   // declined, with a reason, as the rule requires
        Barrier_Report__c = reports[9].Id, Person_Approved__c = true,
        Approved_At__c = System.now().addDays(-6),
        Interactive_Process_Due__c = Date.today().addDays(4),
        Manager_Response__c = 'Declined',
        Decline_Reason__c = 'The assessment vendor says extra time cannot be configured per candidate. We are looking for an alternative assessment and will come back by Friday.')
};
insert requests;

// ---- people currently waiting for a human ---------------------------------
List<Human_Handoff__c> handoffs = new List<Human_Handoff__c>{
    new Human_Handoff__c(   // longest wait, signed video, nobody has it
        Barrier_Report__c = reports[0].Id, Requested_At__c = System.now().addHours(-26),
        Reachable_By__c = 'Video'),
    new Human_Handoff__c(   // waiting, reachable by text
        Barrier_Report__c = reports[6].Id, Requested_At__c = System.now().addHours(-5),
        Reachable_By__c = 'Text message'),
    new Human_Handoff__c(   // waiting, second interpreter case
        Barrier_Report__c = reports[8].Id, Requested_At__c = System.now().addHours(-2),
        Reachable_By__c = 'Video'),
    new Human_Handoff__c(   // picked up, being worked
        Barrier_Report__c = reports[5].Id, Requested_At__c = System.now().addHours(-30),
        Reachable_By__c = 'Text message',
        Handler_Name__c = 'the access team', Picked_Up_At__c = System.now().addHours(-28))
};
insert handoffs;

// ---- standing preferences, and who has been shown them --------------------
List<Access_Preference__c> prefs = new List<Access_Preference__c>{
    new Access_Preference__c(Access_Profile__c = profiles[0].Id,
        Statement__c = 'Please book an interpreter before the meeting, not during it.',
        Scope__c = 'Meetings', Shared_With__c = 'Meeting hosts', Auto_Apply__c = true),
    new Access_Preference__c(Access_Profile__c = profiles[1].Id,
        Statement__c = 'Send me things in writing. I will miss it if it is only said out loud.',
        Scope__c = 'Always', Shared_With__c = 'My team', Auto_Apply__c = true),
    new Access_Preference__c(Access_Profile__c = profiles[2].Id,
        Statement__c = 'Do not schedule me before ten. I will make the hours up later.',
        Scope__c = 'This manager', Shared_With__c = 'Manager only', Auto_Apply__c = true)
};
insert prefs;

insert new List<Disclosure_Event__c>{
    new Disclosure_Event__c(Access_Preference__c = prefs[0].Id, Shown_To__c = 'Priya Raman',
        Shown_At__c = System.now().addDays(-9),  Context__c = 'Booked as host of the sprint review'),
    new Disclosure_Event__c(Access_Preference__c = prefs[0].Id, Shown_To__c = 'Tom Whelan',
        Shown_At__c = System.now().addDays(-4),  Context__c = 'Booked as host of the quarterly review'),
    new Disclosure_Event__c(Access_Preference__c = prefs[0].Id, Shown_To__c = 'Dana Osei',
        Shown_At__c = System.now().addHours(-20),Context__c = 'Took over the sprint review'),
    new Disclosure_Event__c(Access_Preference__c = prefs[1].Id, Shown_To__c = 'The delivery team',
        Shown_At__c = System.now().addDays(-11), Context__c = 'Added to the team channel'),
    new Disclosure_Event__c(Access_Preference__c = prefs[1].Id, Shown_To__c = 'Marcus Bell',
        Shown_At__c = System.now().addDays(-2),  Context__c = 'Joined the team as a new manager'),
    new Disclosure_Event__c(Access_Preference__c = prefs[2].Id, Shown_To__c = 'Alina Kovic',
        Shown_At__c = System.now().addDays(-7),  Context__c = 'Line manager')
};

// ---- delivery ledger, including the failures that matter ------------------
insert new List<Message_Log__c>{
    // Channel is the transport, not the modality: a signed video arrives as MMS
    // over the text channel. Inbound_Modality__c on the report is what records
    // that it was signed, and that it must never be machine translated.
    new Message_Log__c(Channel__c='SMS', Direction__c='Inbound', Status__c='Accepted',
        Attempted_At__c=System.now().addHours(-26), Detail__c='signed video received as MMS',
        Barrier_Report__c=reports[0].Id),
    new Message_Log__c(Channel__c='SMS', Direction__c='Outbound', Status__c='Accepted',
        Attempted_At__c=System.now().addHours(-26), Detail__c='acknowledged in text immediately',
        Barrier_Report__c=reports[0].Id),
    new Message_Log__c(Channel__c='Email', Direction__c='Outbound', Status__c='Escalated',
        Attempted_At__c=System.now().addDays(-3), Detail__c='reply undeliverable, handed to a person',
        Barrier_Report__c=reports[3].Id),
    new Message_Log__c(Channel__c='SMS', Direction__c='Outbound', Status__c='Rejected',
        Attempted_At__c=System.now().addDays(-1), Detail__c='carrier rejected: unreachable handset',
        Barrier_Report__c=reports[6].Id)
};

System.debug(LoggingLevel.ERROR, 'seeded: ' + reports.size() + ' reports, '
    + requests.size() + ' requests, ' + handoffs.size() + ' handoffs, '
    + prefs.size() + ' preferences');
